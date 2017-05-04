# Be sure to restart your server when you modify this file. Action Cable runs in a loop that does not support auto reloading.
class TodoChannel < ApplicationCable::Channel
  include ActionCableNotifications::Channel

  def subscribed
    stream_notifications_for Todo,
      model_options: {
        scope: {
          select: [:id, :title, :completed]
        }
      }
  end

  def unsubscribed
    # Any cleanup needed when channel is unsubscribed
  end
end
