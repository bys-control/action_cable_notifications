module ActionCableNotifications
  module Streams
    extend ActiveSupport::Concern

    included do
      attr_accessor :stream_notification_options
      # Actions to be done when the module is included
    end

    def get_initial_values
      transmit self.stream_notification_options[:model].notify_initial self.stream_notification_options[:broadcasting]
    end

    private

    def stream_notifications_for(model, options = {}, &block)
      # Default options
      options = {
        model: model,
        actions: [:create, :update, :destroy],
        broadcasting: model.model_name.collection,
        callback: nil,
        coder: nil,
        include_initial: false, # Send all records to the subscriber on connection
        params: params,
        scope: :all             # Default collection scope
        }.merge(options)

      # Sets channel options
      self.stream_notification_options = options

      # Checks if model already includes notification callbacks
      if !model.respond_to? :ActionCableNotificationsOptions
        model.send('include', ActionCableNotifications::Callbacks)
        # Set specified options on model
      end

      # Sets broadcast options if they are not already present in the model
      if not model.ActionCableNotificationsOptions.key? options[:broadcasting]
        model.broadcast_notifications_from options[:broadcasting], options
      end

      # Start streaming
      stream_from(options[:broadcasting], options[:callback] || block, options.slice(:coder))

      # Transmit initial state if required
      if options[:include_initial]
        # XXX: Check if data should be transmitted
        get_initial_values
      end

    end

    def unsubscribed
      stop_all_streams
    end

  end
end
