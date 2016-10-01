#= require_self
#= require './default_callbacks'

class CableNotifications.Store
  constructor: (@name, @options={}, @callbacks) ->
    @collections = {}
    @channels = {}

    if !@callbacks
      @callbacks = new CableNotifications.Store.DefaultCallbacks(@collections)

    this

  # Private methods
  #######################################

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
      @callbacks[packet.msg]?(packet, collection)

  # Public methods
  #######################################

  # Register a new collection
  registerCollection: (name, channel, tableName) ->
    tableName = name unless tableName
    if @collections[name]
      console.warn "[registerCollection]: Collection '#{name}' already exists"
    else
      @collections[name] = new CableNotifications.Collection(this, name, tableName)
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
        channelInfo.collections.push collection
    else
      # Assigns channel to collection
      collection.channel = channel

      # Initialize channelInfo
      @channels[channelId] =
        id: channelId
        channel: channel
        collections: [collection]
        callbacks: {
          received: channel.received
        }

      channel.received = packetReceived(@channels[channelId]).bind(this)

    return true
