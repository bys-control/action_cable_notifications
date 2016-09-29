#= export CableNotifications
#= require_self
#= require './store'
#= require './collection'

@CableNotifications =
  stores: []

  # Register a new store
  registerStore: (store, callbacks) ->
    new_store = new CableNotifications.Store(store, callbacks)
    @stores.push new_store
    new_store
