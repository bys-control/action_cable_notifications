App.todo = App.cable.subscriptions.create {
  channel: "TodoChannel",
  scope:
    select:
      ["id", "title", "completed"]
  },
  connected: ->
    # Called when the subscription is ready for use on the server

  disconnected: ->
    # Called when the subscription has been terminated by the server
