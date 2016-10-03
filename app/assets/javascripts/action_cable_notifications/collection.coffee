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
        if upstream(cmd.command, cmd.params)
          cmd.performed = true
      )

      # Cleanup performed commands
      _.remove(@commandsCache, {performed: true})

      # Fetch data from upstream server when connection is resumed
      @fetch()

  # Public methods
  #######################################

  constructor: (@store, @name, @tableName) ->
    # Data storage array
    @data = []
    # Channel used to sync with upstream collection
    @channel = null
    # Tells changes should be synced with upstream collection
    @sync = false
    # Stores upstream commands when there is no connection to the server
    @commandsCache = []

    # Bind private methods to class instance
    ########################################################
    upstream = upstream.bind(this)

  # Sync collection to ActionCable Channel
  syncToChannel: (@channel) ->
    @sync = true

    Tracker.autorun () =>
      @channel.isConnected()
      connectionChanged.call(this)

  # Fetch records from upstream
  fetch: (params) ->
    upstream("fetch", params)

  # Filter records from the current collection
  where: (selector={}) ->
    _.filter(@data, selector)

  # Find a record
  find: (selector={}) ->
    _.find(@data, selector)

  # Creates a new record
  create: (fields={}) ->
    record = _.find(@data, {id: fields.id})
    if( record )
      console.warn("[create] Not expected to find an existing record with id #{fields.id}")
      return

    @data.push (fields) unless @sync

    upstream("create",
      fields: fields
    )
    fields

  # Update an existing record
  update: (selector={}, fields={}, options={}) ->
    record = _.find(@data, selector)
    if !record
      if options.upsert
        @create(fields)
      else
        console.warn("[update] Couldn't find a matching record:", selector)
    else
      _.extend(record, fields)
      upstream("update", {id: record.id, fields: fields})
      record

  # Update an existing record or inserts a new one if there is no match
  upsert: (selector={}, fields) ->
    @update(selector, fields, {upsert: true})

  # Destroy an existing record
  destroy: (selector={}) ->
    index = _.findIndex(@data, selector)
    if index < 0
      console.warn("[destroy] Couldn't find a matching record:", selector)
    else
      record = @data[index]
      @data.splice(index, 1) unless @sync
      upstream("destroy", {id: record.id})
      record
