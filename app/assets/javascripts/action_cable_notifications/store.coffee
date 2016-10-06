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
      if packet?.collection
        # Search if there is a collection in this Store that receives packets from the server
        collection = _.find(channelInfo.collections,
          {tableName: packet.collection})
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
  registerCollection: (name, channel, tableName, actions) ->
    tableName = name unless tableName
    if @collections[name]
      console.warn "[registerCollection]: Collection '#{name}' already exists"
    else
      @collections[name] = new CableNotifications.Collection(this, name, tableName, actions)
      @collections[name].initialize()
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

    if @collections[collection.name] < 0
      console.warn "[syncToChannel]: Collection does not exists in the store"
      return false

    if @channels[channelId]
      channelInfo = @channels[channelId]
      if _.find(channelInfo.collections, {name: collection.name})
        console.warn "[syncToChannel]: Collection '#{collection.name}' is already being synced with channel '#{channelId}'"
        return false
      else
        collection.syncToChannel(channel)
        channelInfo.collections.push collection
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

    return true
