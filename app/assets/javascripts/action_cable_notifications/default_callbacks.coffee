# Default callbacks for internal storage of received packets
class CableNotifications.Store.DefaultCallbacks
  constructor: (@collections) ->

  # Helper function
  processPacketHelper: (packet, collection) ->
    index = -1
    record = null

    local_collection = @collections[collection || packet.collection].data
    if !local_collection
      console.warn("[#{packet.msg}]: Collection #{collection_name} doesn't exist")
    else
      index = _.findIndex(local_collection, (record) -> record.id == packet.id)
      if (index >= 0)
        record = local_collection[index]

    return {
      collection: local_collection
      index: index
      record: record
    }

  # Callbacks
  ##################################################

  collection_remove: (packet, collection) ->
    console.warn 'Method not implemented: collection_remove '

  create: (packet, collection) ->
    data = @processPacketHelper(packet, collection)
    if data.record
      console.warn 'Expected not to find a document already present for an add: ' + data.record
    else
      data.collection.push(packet.data)

  update: (packet, collection) ->
    data = @processPacketHelper(packet, collection)
    if !data.record
      console.warn 'Expected to find a document to change'
    else if !_.isEmpty(packet.data)
      _.extend(data.record, packet.data)

  update_many: (packet, collection) ->
    collection_name = collection || packet.collection
    local_collection = @collections[collection_name].data
    if !local_collection
      console.warn("[update_many]: Collection #{collection_name} doesn't exist")
    else
      _.each packet.data, (fields) ->
        record = _.findIndex(local_collection, (r) -> r.id == fields.id)
        if record>=0
          _.extend(local_collection[record], fields)
        else
          local_collection.push(fields)

  destroy: (packet, collection) ->
    data = @processPacketHelper(packet, collection)
    if !data.record
      console.warn 'Expected to find a document to remove'
    else
      data.collection.splice(data.index, 1)
