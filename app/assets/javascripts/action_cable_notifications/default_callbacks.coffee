# Default callbacks for internal storage of received packets
class CableNotifications.Store.DefaultCallbacks
  constructor: (@collections) ->

  # Callbacks
  ##################################################

  collection_remove: (packet, collection) ->
    console.warn 'Method not implemented: collection_remove '

  create: (packet, collection) ->
    collection.create(packet.data)

  update: (packet, collection) ->
    collection.update({id: packet.id}, packet.data)

  update_many: (packet, collection) ->
    _.each packet.data, (fields, index, records) ->
      collection.update({id: fields.id}, fields, {batching: index<records.length-1})

  upsert: (packet, collection) ->
    collection.upsert({id: packet.id}, packet.data)

  upsert_many: (packet, collection) ->
    _.each packet.data, (fields, index, records) ->
      collection.upsert({id: fields.id}, fields, {batching: index<records.length-1})

  destroy: (packet, collection) ->
    collection.destroy({id: packet.id})

  error: (packet, collection) ->
    console.error "[#{packet.command}]: #{packet.error}"
