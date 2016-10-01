class CableNotifications.Collection
  constructor: (@store, @name, @tableName) ->
    # Data storage array
    @data = []
    # Channel used to sync with upstream collection
    @channel = null
    # Tells changes should be synced with upstream collection
    @sync = false

  # Public methods
  #######################################

  fetch: () ->
    @channel?.perform?('fetch') if @sync

  where: (selector={}) ->
    _.filter(@data, selector)

  find: (selector={}) ->
    _.find(@data, selector)

  create: (record) ->
    @data.push (record)
    record

  update: (selector, fields, options={}) ->
    record = _.find(@data, selector)
    if !record
      if options.upsert
        @data.push (fields)
      else
        console.warn("Couldn't find a matching record: #{selector}")
    else
      _.extend(record, fields)
      @channel?.perform?('update', {id: record.id, fields: fields}) if @sync

  upsert: (selector={}, fields) ->
    @update(selector, fields, {upsert: true})

  destroy: (selector={}) ->
    index = _.findIndex(@data, selector)
    if index < 0
      console.warn("Couldn't find a matching record: #{selector}")
    else
      record = @data[index]
      @data.splice(index, 1)
      @channel?.perform?('destroy', {id: record.id}) if @sync
