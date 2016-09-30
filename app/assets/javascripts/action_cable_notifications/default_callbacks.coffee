# Default callbacks for internal storage of received packets
class CableNotifications.Store.DefaultCallbacks
  constructor: (@collections) ->

  # Callbacks
  ##################################################

  collection_remove: (packet, collection) ->
    console.warn 'Method not implemented: collection_remove '

  create: (packet, collection) ->
    fields = packet.data
    collection.insert(fields)

  update: (packet, collection) ->
    collection.update({id: packet.id}, packet.data)

  update_many: (packet, collection) ->
    _.each packet.data, (fields) ->
      collection.update({id: fields.id}, fields)

  upsert_many: (packet, collection) ->
    _.each packet.data, (fields) ->
      collection.upsert({id: fields.id}, fields)

  destroy: (packet, collection) ->
    collection.remove({id: packet.id})

  error: (packet, collection) ->
    console.error "[#{packet.cmd}]: #{packet.error}"
