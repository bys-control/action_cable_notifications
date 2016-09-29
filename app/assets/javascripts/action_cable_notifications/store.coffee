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

  packetReceived = (channelInfo, collection) ->
    (packet) ->
      @storePacket(packet, collection)
      channelInfo.callbacks.received?.apply channelInfo.channel, arguments

  # Public methods
  #######################################

  # Register a new collection
  registerCollection: (collection) ->
    if @collections[collection]
      console.warn '[registerCollection]: Collection already exists'
    else
      @collections[collection] = new CableNotifications.Collection(this, collection)
    @collections[collection]

  # Sync store using ActionCable received events
  # collection parameter overrides the collection name specified in the incoming packets for this channel
  syncToChannel: (channel, collection) ->
    channelId = JSON.parse(channel.identifier)?.channel

    if !channelId
      console.warn "[syncToChannel]: Channel specified doesn't have an identifier"
    else
      @channels[channelId] =
        channel: channel
        callbacks: {
          received: channel.received
        }

      channel.received = packetReceived(@channels[channelId], collection).bind(this)
    channel

  # Dispatch received packet to registered stores
  # collection overrides the collection name specified in the incoming packet
  storePacket: (packet, collection) ->
    if packet && packet.msg
      @callbacks[packet.msg]?(packet, collection)
