#= require_self
#= require './default_callbacks'

class CableNotifications.Store
  constructor: (@name, @options={}, @callbacks) ->
    @collections = {}
    @channels = {}

    if !@callbacks
      @callbacks = new CableNotifications.Store.DefaultCallbacks(@collections)

  # Private methods
  #######################################

  # Check received packet and dispatch to the apropriate callback.
  # Then call original callback
  packetReceived = (channelInfo) ->
    (packet) ->
      if packet?.publication
        # Search if there is a collection in this Store that receives packets from the server
        collection = _.find(channelInfo.collections,
          {publication: packet.publication})
        if collection
          dispatchPacket.call(this, packet, collection)
      channelInfo.callbacks.received?.apply(channelInfo.channel, arguments)

  # Dispatch received packet to registered stores
  # collection overrides the collection name specified in the incoming packet
  dispatchPacket = (packet, collection) ->
    if packet && packet.msg
      # Disables sync with upstream to prevent infinite message loop
      sync = collection.sync
      collection.sync = false
      @callbacks[packet.msg]?(packet, collection)
      collection.sync = sync

  # Called when connected to a channel
  channelConnected = (channelInfo) ->
    () ->
      channelInfo.connectedDep.changed()
      channelInfo.callbacks.connected?.apply(channelInfo.channel, arguments)

  # Called when disconnected from a channel
  channelDisconnected = (channelInfo) ->
    () ->
      channelInfo.connectedDep.changed()
      channelInfo.callbacks.disconnected?.apply(channelInfo.channel, arguments)

  # Returns channel connection status
  channelIsConnected = (channelInfo) ->
    () ->
      channelInfo.connectedDep.depend()
      !channelInfo.channel.consumer.connection.disconnected

  # Public methods
  #######################################

  # Register a new collection
  registerCollection: (name, channel, publication=name, actions) ->
    if @collections[name]
      console.warn "[registerCollection]: Collection '#{name}' already exists"
    else
      @collections[name] = new CableNotifications.Collection(this, name, publication, actions)
      if channel
        @syncToChannel(channel, @collections[name])

    @collections[name]

  # Sync store using ActionCable received events
  # collection parameter overrides the collection name specified in the incoming packets for this channel
  syncToChannel: (channel, collection) ->
    if !channel
      console.warn "[syncToChannel]: Channel must be specified"
      return false

    if !collection
      console.warn "[syncToChannel]: Collection must be specified"
      return false

    channelId = JSON.parse(channel.identifier)?.channel

    if !channelId
      console.warn "[syncToChannel]: Channel specified doesn't have an identifier"
      return false

    if !@collections[collection.name]
      console.warn "[syncToChannel]: Collection does not exists in the store"
      return false

    if collection.channel == channel
      console.warn "[syncToChannel]: Collection is already been synced with channel '#{channelId}'"
      return false

    channel.collections = [] unless channel.collections

    existingCollection = _.find(channel.collections, {tableName: collection.tableName})
    if existingCollection
      console.warn "[syncToChannel]: Table '#{collection.tableName}' is already being synced with channel '#{channelId}' in collection '#{existingCollection.name}'"

      # Copies data from existing collection to the new collection
      collection.data = _.cloneDeep(existingCollection.data)

    if @channels[channelId]
      @channels[channelId].collections.push collection
    else
      # Initialize channelInfo
      @channels[channelId] =
        id: channelId
        channel: channel
        collections: [collection]
        callbacks: {
          received: channel.received
          connected: channel.connected
          disconnected: channel.disconnected
        }
        connectedDep: new Tracker.Dependency

      channel.received = packetReceived(@channels[channelId]).bind(this)
      channel.connected = channelConnected(@channels[channelId]).bind(this)
      channel.disconnected = channelDisconnected(@channels[channelId]).bind(this)
      channel.isConnected = channelIsConnected(@channels[channelId]).bind(this)

    # Assigns channel to collection and turns on Sync
    collection.syncToChannel(channel)
    channel.collections.push collection

    return true
