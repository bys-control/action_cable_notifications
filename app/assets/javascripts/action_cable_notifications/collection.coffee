class CableNotifications.Collection
  # Private methods
  #######################################
  upstream = (command, params={}) ->
    @channel?.perform?('action',
      collection: @tableName
      command: command
      params: params
    ) if @sync

  # Public methods
  #######################################

  constructor: (@store, @name, @tableName) ->
    # Data storage array
    @data = []
    # Channel used to sync with upstream collection
    @channel = null
    # Tells changes should be synced with upstream collection
    @sync = false

    @create_pending_confirmation = {}

    upstream = upstream.bind(this)

  fetch: (params) ->
    upstream("fetch", params)

  where: (selector={}) ->
    _.filter(@data, selector)

  find: (selector={}) ->
    _.find(@data, selector)

  create: (fields={}, tmp_id) ->
    # Check if the call is the upstream confirmation
    if tmp_id
      record = @create_pending_confirmation[tmp_id]
      _.extend(record, fields)
      delete @create_pending_confirmation[tmp_id]
    else
      record = _.find(@data, {id: fields.id})
      if( record )
        console.warn("[create] Not expected to find an existing record with id #{fields.id}")
        return

      @data.push (fields) unless @sync

      tmp_id = "new_#{_.random(2**32)}"
      @create_pending_confirmation[tmp_id] = fields

      upstream("create",
        tmp_id: tmp_id
        fields: fields
      )
      fields

  update: (selector={}, fields={}, options={}) ->
    record = _.find(@data, selector)
    if !record
      if options.upsert
        @create(fields)
      else
        console.warn("[update] Couldn't find a matching record: #{selector}")
    else
      _.extend(record, fields)
      upstream("update", {id: record.id, fields: fields})
      record

  upsert: (selector={}, fields) ->
    @update(selector, fields, {upsert: true})

  destroy: (selector={}) ->
    index = _.findIndex(@data, selector)
    if index < 0
      console.warn("[destroy] Couldn't find a matching record: #{selector}")
    else
      record = @data[index]
      @data.splice(index, 1)
      upstream("destroy", {id: record.id})
