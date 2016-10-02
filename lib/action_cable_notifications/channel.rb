require 'action_cable_notifications/channel_actions.rb'

module ActionCableNotifications
  module Channel
    extend ActiveSupport::Concern

    included do
      cattr_accessor :ActionCableNotifications

      self.ActionCableNotifications = {}
    end

    #
    # Public methods
    ################################################################

    #
    # Process actions sent from the client
    #
    # @param [Hash] data Contains command to be executed and its parameters
    # {
    #   "collection": "model.model_name.collection"
    #   "command": "fetch"
    #   "params": {}
    # }
    def action(data)
      data.deep_symbolize_keys!

      channel_options = self.ActionCableNotifications[data[:collection]]
      model = channel_options[:model]
      broadcasting = channel_options[:broadcasting]
      model_options = model.ActionCableNotificationsOptions[broadcasting]

      params = {
        model: model,
        model_options: model_options,
        params: data[:params]
      }

      case data[:command]
      when "fetch"
        fetch(params)
      when "update"
        update(params)
      when "destroy"
        destroy(params)
      end
    end

    #
    # Private methods
    ################################################################

    private

    include ActionCableNotifications::Channel::Actions

    #
    # Streams notification for ActiveRecord model changes
    #
    # @param [ActiveRecord::Base] model Model to watch for changes
    # @param [Hash] options Streaming options
    #
    def stream_notifications_for(model, options = {})
      # Default options
      options = {
      }.merge(options)

      # These options cannot be overridden
      options[:model] = model
      options[:channel] = self
      options[:broadcasting] = model.model_name.collection

      # Sets channel options
      self.ActionCableNotifications[options[:broadcasting]] = options

      # Checks if model already includes notification callbacks
      if !model.respond_to? :ActionCableNotificationsOptions
        model.send('include', ActionCableNotifications::Model)
      end

      # Sets broadcast options if they are not already present in the model
      if not model.ActionCableNotificationsOptions.key? options[:broadcasting]
        model.broadcast_notifications_from options[:broadcasting], options
      end

      # Start streaming
      stream_from options[:broadcasting], coder: ActiveSupport::JSON do |packet|
        # XXX: Implement Meteor MergeBox functionality
        transmit packet
      end

    end

    def unsubscribed
      stop_all_streams
    end

  end
end
