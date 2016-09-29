class CableNotifications

  #
  # Private variables
  #####################################

  registered_stores = {}

  #
  # Public variables
  #####################################

  # Default internal storage
  collections: {}

  #
  # Private methods
  #####################################

  # Default callbacks for internal storage of received packets
  # Need to set include_initial: true in broadcasting options
  class DefaultCallbacks
    constructor: (@collections) ->

    # Helper function
    processPacketHelper = (packet, collection) ->
      index = -1
      record = null

      local_collection = @collections[collection || packet.collection]
      if !local_collection
        console.warn("[update_many]: Collection #{collection_name} doesn't exist")
      else
        index = _.find(local_collection, (record) -> record.id == packet.id)
        if (index >= 0)
          record = local_collection[index]

      return {
        collection: local_collection
        index: index
        record: record
      }

    # Callbacks
    ##################################################

    initialize: (collection) ->
      @collections[collection] = []

    collection_remove: (packet, collection) ->
      console.warn 'Method not implemented: collection_remove '

    create: (packet, collection) ->
      data = processPacketHelper(packet, collection)
      if data.record
        console.warn 'Expected not to find a document already present for an add: ' + data.record
      else
        data.collection.push(packet.data)

    update: (packet, collection) ->
      data = processPacketHelper(packet, collection)
      if !data.record
        console.warn 'Expected to find a document to change'
      else if !_.isEmpty(packet.data)
        _.extend(data.record, packet.data)

    update_many: (packet, collection) ->
      collection_name = collection || packet.collection
      local_collection = @collections[collection_name]
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
    @default_callbacks = new @DefaultCallbacks(@collections)

    # Register internal store
    @registerStore()

  # Register a new store
  registerStore: (store='default', callbacks) ->
    if !registered_stores[store]
      if callbacks
        registered_stores[store] = callbacks
      else
        registered_stores[store] = default_callbacks
    registered_stores[store]

  # Register a new collection into a store
  registerCollection: (collection, channel, store='default') ->
    if registered_stores[store]
      # Initialize registered collection
      new_collection = registered_stores[store].initialize?(collection)
      # If ActionCable channel is specified, get initial values for subcription
      if channel
        channel.perform?("get_initial_values")
      new_collection
    else
      console.warn("Store #{store} does not exist")
      null

  # Dispatch received packet to registered stores
  storePacket: (packet, collection) ->
    if packet && packet.msg
      for store, callbacks of registered_stores
        callbacks[packet.msg]?(packet, collection)

  findRecord: (collection, id) ->
    record = _.find(@collections[collection], (record) -> record.id == id)
    if !record
      record = {id: id, value: [0]}
      @collections[collection].push record
    record

# Export to global namespace
#######################################
@App = {} unless @App
@App.cable_notifications = new CableNotifications()
