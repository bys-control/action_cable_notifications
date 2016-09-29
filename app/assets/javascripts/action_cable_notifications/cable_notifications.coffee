#= export CableNotifications
#= require_self
#= require './store'
#= require './collection'
# require './exports'

console.log('cable_notifications')

class @CableNotifications
  constructor: ->
    @stores = []

    # Register internal store
    @registerStore('default')

  # Public methods
  #######################################

  # Register a new store
  registerStore: (store, callbacks) ->
    new_store = new CableNotifications.Store(store, callbacks)
    @stores.push new_store
    new_store
