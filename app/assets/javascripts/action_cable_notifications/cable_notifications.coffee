#= export CableNotifications
#= require_self
#= require './store'
#= require './collection'

@App || (@App = {})

@App.cableNotifications =
  stores: []

  # Register a new store
  registerStore: (store, options, callbacks) ->
    new_store = new CableNotifications.Store(store, options, callbacks)
    @stores.push new_store
    new_store

# Backwards compatibility
@CableNotifications = @App.cableNotifications
