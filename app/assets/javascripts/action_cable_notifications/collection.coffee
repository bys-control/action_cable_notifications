class CableNotifications.Collection
  # Private methods
  #######################################
  upstream = (command, params={}) ->
    if @sync
      cmd =
        collection: @tableName
        command: command
        params: params

      # If channel is connected, send command to the server
      if @channel.isConnected()
        @channel?.perform?('action', cmd)
      # Otherwise, enqueue commands to send when connection resumes
      else
        @commandsCache.push {command: command, params: params, performed: false}
        false
    else
      false

  connectionChanged = () ->
    if @channel.isConnected()
      _.each(@commandsCache, (cmd) ->
        if upstream.call(this, cmd.command, cmd.params)
          cmd.performed = true
      )

      # Cleanup performed commands
      _.remove(@commandsCache, {performed: true})

      # Clears the data array before fetching data
      @data.splice(0,@data.length)

      # Fetch data from upstream server when connection is resumed
      @fetch()

    @callbacks?.connectionChanged?.call(this)

  # Public methods
  #######################################
  constructor: (@store, @name, @tableName=name, @callbacks) ->
    # Data storage array
    @data = []
    # Channel used to sync with upstream collection
    @channel = null
    # Tells changes should be synced with upstream collection
    @sync = false
    # Stores upstream commands when there is no connection to the server
    @commandsCache = []
    # Stores records that needs to be tracked when inserted into the collection
    @trackedRecords = []

    @callbacks?.initialize?.call(this)

  # Sets the callbacks for collection after initialization
  setCallbacks: (@callbacks) ->

  # Sync collection to ActionCable Channel
  syncToChannel: (@channel) ->
    @sync = true

    Tracker.autorun () =>
      @channel.isConnected()
      connectionChanged.call(this)

  # Fetch records from upstream
  fetch: (params) ->
    upstream.call(this, "fetch", params)

  # Filter records from the current collection
  where: (selector={}) ->
    if @callbacks?.where?
      @callbacks.where.call(this, selector)
    else
      _.filter(@data, selector)

  filter: (selector={}) ->
    @where(selector)

  # Find a record
  find: (selector={}, options={}) ->
    record = _.find(@data, selector)

    if !record and options.track
      if selector.id
        trackedRecord = _.find(@trackedRecords, {id: selector.id})
        if trackedRecord
          trackedRecord
        else
          trackedRecord = selector
          @trackedRecords.push trackedRecord
          trackedRecord
      else
        console.warn("[find] Id must be specified to track records")
    else
      record

  # Creates a new record
  create: (fields={}, options={}) ->
    record = _.find(@data, {id: fields.id})
    if record
      console.warn("[create] Not expected to find an existing record with id #{fields.id}")
      return

    # Search in tracked records
    recordIndex = _.findIndex(@trackedRecords, {id: fields.id})
    if recordIndex>=0
      fields = _.extend( @trackedRecords[recordIndex], fields )
      @trackedRecords.splice(recordIndex, 1)

    if !@sync
      @data.push (fields)
      @callbacks?.create?.call(this, fields)
      @callbacks?.changed?.call(this, @data) unless options.batching

    upstream.call(this, "create", {fields: fields})
    fields

  # Update an existing record
  update: (selector={}, fields={}, options={}) ->
    record = _.find(@data, selector)
    if !record
      if options.upsert
        @create(fields, options)
      else
        console.warn("[update] Couldn't find a matching record:", selector)
    else
      if !@sync
        @callbacks?.update?.call(this, selector, fields, options)
        _.extend(record, fields)
        @callbacks?.changed?.call(this, @data) unless options.batching

      upstream.call(this, "update", {id: record.id, fields: fields})
      record

  # Update an existing record or inserts a new one if there is no match
  upsert: (selector={}, fields, options={}) ->
    @update(selector, fields, _.extend(options, {upsert: true}))

  # Destroy an existing record
  destroy: (selector={}) ->
    index = _.findIndex(@data, selector)
    if index < 0
      console.warn("[destroy] Couldn't find a matching record:", selector)
    else
      record = @data[index]
      if !@sync
        @data.splice(index, 1)
        @callbacks?.destroy?.call(this, selector)
        @callbacks?.changed?.call(this, @data) unless options.batching

      upstream.call(this, "destroy", {id: record.id})
      record
