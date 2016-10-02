class CableNotifications.Collection
  # Private methods
  #######################################
  upstream = (command, params={}) ->
    @channel?.perform?('action',
      collection: @tableName
      command: command
      params: params
    ) if @sync

  constructor: (@store, @name, @tableName) ->
    # Data storage array
    @data = []
    # Channel used to sync with upstream collection
    @channel = null
    # Tells changes should be synced with upstream collection
    @sync = false

    upstream = upstream.bind(this)

  # Public methods
  #######################################

  fetch: (params) ->
    upstream("fetch", params)

  where: (selector={}) ->
    _.filter(@data, selector)

  find: (selector={}) ->
    _.find(@data, selector)

  create: (record) ->
    @data.push (record)
    record

  update: (selector={}, fields={}, options={}) ->
    record = _.find(@data, selector)
    if !record
      if options.upsert
        @data.push (fields)
      else
        console.warn("Couldn't find a matching record: #{selector}")
    else
      _.extend(record, fields)
      upstream("update", {id: record.id, fields: fields})

  upsert: (selector={}, fields) ->
    @update(selector, fields, {upsert: true})

  destroy: (selector={}) ->
    index = _.findIndex(@data, selector)
    if index < 0
      console.warn("Couldn't find a matching record: #{selector}")
    else
      record = @data[index]
      @data.splice(index, 1)
      upstream("destroy", {id: record.id})
