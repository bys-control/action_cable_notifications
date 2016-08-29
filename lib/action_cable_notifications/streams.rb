module ActionCableNotifications
  module Streams
    extend ActiveSupport::Concern

    included do

    end

    private

    def stream_notifications_for(model, options = {}, callback = nil)
      # Default options
      options = {
        include_initial: false, # Send all records to the subscriber on connection
        broadcast_name: model.model_name.collection
        }.merge(options)

      # Checks if model already includes notification callbacks
      if !model.respond_to? :ActionCableNotificationsOptions
        model.send('include', ActionCableNotifications::Callbacks)
      end

      # Set specified options on model
      model.send('set_action_cable_notification_options', options)

      stream_from(options[:broadcast_name], callback)

      # Transmit initial state if required
      if options[:include_initial]
        transmit model.notify_initial
      end

    end

  end
end
