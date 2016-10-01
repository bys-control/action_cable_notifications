class CableNotifications.Collection
  constructor: (@store, @name, @tableName) ->
    @data = []
    @channel = null

  # Public methods
  #######################################

  find: (selector={}) ->
    _.filter(@data, selector)

  findFirst: (selector={}) ->
    _.find(@data, selector)

  findIndex: (selector={}) ->
    _.findIndex(@data, selector)

  insert: (record) ->
    @data.push (record)
    record

  remove: (selector={}) ->
    index = @findIndex(selector)
    if index < 0
      console.warn("Couldn't find a matching record: #{selector}")
    else
      record = @data.splice(index, 1)

  update: (selector, fields, options={}) ->
    record = _.find(@data, selector)
    if !record
      if options.upsert
        @data.push (fields)
      else
        console.warn("Couldn't find a matching record: #{selector}")
    else
      _.extend(record, fields)

  # http://docs.meteor.com/#/full/upsert
  upsert: (selector={}, fields) ->
    @update(selector, fields, {upsert: true})
