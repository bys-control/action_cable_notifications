class CableNotifications

  #
  # Private variables
  #####################################

  registered_stores = {}

  #
  # Public variables
  #####################################

  collections: null

  #
  # Private methods
  #####################################

  processPacketHelper = (packet, collection) ->
    local_collection = @collections[collection || packet.collection]
    index = null
    record = null

    index = _.findIndex(local_collection, (record) -> record.id == packet.id)
    if (index >= 0)
      record = local_collection[index]

    return {
      collection: local_collection
      index: index
      record: record
    }

  # Default callbacks for internal storage of received packets
  # Need to set include_initial: true in broadcasting options
  default_callbacks =
    initialize: (collection) ->
      @collections[collection] = []

    collection_add: (packet, collection) ->
      @collections[collection || packet.collection] = packet.data

    collection_remove: (packet, collection) ->
      console.warn 'Method not implemented: collection_remove '

    added: (packet, collection) ->
      data = processPacketHelper(packet, collection)
      if data.record
        console.warn 'Expected not to find a document already present for an add: ' + data.record
      else
        data.collection.push(packet.data)

    changed: (packet, collection) ->
      data = processPacketHelper(packet, collection)
      if !data.record
        console.warn 'Expected to find a document to change'
      else if !_.isEmpty(packet.data)
        _.extend(data.record, packet.data)

    removed: (packet, collection) ->
      data = processPacketHelper(packet, collection)
      if !data.record
        console.warn 'Expected to find a document to remove'
      else
        data.collection.splice(data.index, 1)

  #
  # Public methods
  #####################################
  constructor: ->
    @collections = {}

    # Binds local methods and callbacks to this class
    for name, callback of default_callbacks
      default_callbacks[name] = callback.bind(this)

    processPacketHelper = processPacketHelper.bind(this)

  # Registers a new store
  registerStore: (collection, callbacks) ->
    if callbacks
      registered_stores[collection] = callbacks
    else
      registered_stores[collection] = default_callbacks

    # Initialize registered store
    registered_stores[collection].initialize?(collection)

  # Dispatch received packet to registered stores
  storePacket: (packet, collection) ->
    if packet && packet.msg
      for store, callbacks of registered_stores
        callbacks[packet.msg]?(packet, collection)


# Export to global namespace
#######################################
@App = {} unless @App
@App.cable_notifications = new CableNotifications()
