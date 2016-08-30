module ActionCableNotifications
  module Streams
    extend ActiveSupport::Concern

    included do
      # Actions to be done when the module is included
    end

    private

    def stream_notifications_for(model, options = {}, &block)
      @model = model

      # Default options
      @options = {
        actions: [:create, :update, :destroy],
        broadcasting: model.model_name.collection,
        callback: nil,
        coder: nil,
        include_initial: false, # Send all records to the subscriber on connection
        params: params,
        scope: :all             # Default collection scope
        }.merge(options)

      # Checks if model already includes notification callbacks
      if !@model.respond_to? :ActionCableNotificationsOptions
        @model.send('include', ActionCableNotifications::Callbacks)
      end

      # Set specified options on model
      @model.send('action_cable_notification_options=', @options[:broadcasting], @options)

      # Start streaming
      stream_from(@options[:broadcasting], options[:callback] || block, @options.slice(:coder))

      # Transmit initial state if required
      if @options[:include_initial]
        # XXX: Check if data should be transmitted
        transmit @model.notify_initial @options[:broadcasting]
      end

    end

    def unsubscribed
      stop_all_streams

      # Unset options for this channel on model
      @model.send('action_cable_notification_options=', @options[:broadcasting], nil)
    end

  end
end
