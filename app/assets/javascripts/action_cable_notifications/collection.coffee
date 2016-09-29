class CableNotifications.Collection
  constructor: (@store, @name) ->
    @data = []
    @channelInfo = null

  # Private methods
  #######################################

  find: (selector={}) ->
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

  update: (selector={}, fields, options) ->
    record = @find(selector)
    if !record
      if options.upsert
        @insert(fields)
      else
        console.warn("Couldn't find a matching record: #{selector}")
    else
      _.extend(record, fields)

  # http://docs.meteor.com/#/full/upsert
  upsert: (selector={}, fields) ->
    @update(selector, fields, {upsert: true})

  filter: (selector={}) ->
    _.filter(@data, selector)
