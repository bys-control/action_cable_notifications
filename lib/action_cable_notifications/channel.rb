require 'action_cable_notifications/channel_actions.rb'
require 'action_cable_notifications/channel_cache.rb'

module ActionCableNotifications
  module Channel
    extend ActiveSupport::Concern

    included do

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

      channel_options = @ActionCableNotificationsOptions[data[:collection]]
      if channel_options
        model = channel_options[:model]
        broadcasting = channel_options[:broadcasting]
        model_options = model.ActionCableNotificationsOptions[broadcasting]

        params = {
          model: model,
          model_options: model_options,
          options: channel_options,
          params: data[:params],
          command: data[:command]
        }

        case data[:command]
        when "fetch"
          fetch(params)
        when "create"
          create(params)
        when "update"
          update(params)
        when "destroy"
          destroy(params)
        end
      else
        response = {
          collection: data[:collection],
          msg: 'error',
          command: data[:command],
          error: "Collection '#{data[:collection]}' does not exist."
        }

        # Send error notification to the client
        transmit response
      end
    end

    def initialize(*args)
      @collections = {}
      @ActionCableNotificationsOptions = {}
      super
    end

    def subscribed
      # XXX Check if this is new connection or a reconection of a
      # previously active client
    end

    def unsubscribed
      stop_all_streams
    end

    #
    # Private methods
    ################################################################

    private

    include ActionCableNotifications::Channel::Actions
    include ActionCableNotifications::Channel::Cache

    #
    # Streams notification for ActiveRecord model changes
    #
    # @param [ActiveRecord::Base] model Model to watch for changes
    # @param [Hash] options Streaming options
    #
    def stream_notifications_for(model, options = {})

      # Default options
      options = {
        broadcasting: model.model_name.collection,
        cache: false,
        model_options: {},
        scope: :all
      }.merge(options).merge(params.deep_symbolize_keys)

      # These options cannot be overridden
      options[:model] = model
      # options[:channel] = self
      model_name = model.model_name.collection

      # Sets channel options
      @ActionCableNotificationsOptions[model_name] = options

      # Checks if model already includes notification callbacks
      if !model.respond_to? :ActionCableNotificationsOptions
        model.send('include', ActionCableNotifications::Model)
      end

      # Sets broadcast options if they are not already present in the model
      if not model.ActionCableNotificationsOptions.key? options[:broadcasting]
        model.broadcast_notifications_from options[:broadcasting], options[:model_options]
      else # Reads options configuracion from model
        options[:model_options] = model.ActionCableNotificationsOptions[options[:broadcasting]]
      end

      # Start streaming
      stream_from options[:broadcasting], coder: ActiveSupport::JSON do |packet|
        transmit_packet(packet, options)
      end

      # XXX: Transmit initial data
    end

    #
    # Transmits packets to connected client
    #
    # @param [Hash] packet Packet with changes notifications
    #
    def transmit_packet(packet, options={})
      # Default options
      options = {
        cache: false
      }.merge(options)

      packet = packet.as_json.deep_symbolize_keys

      if validate_packet(packet, options)
        if options[:cache]==true
          if update_cache(packet)
            transmit packet
          end
        else
          transmit packet
        end
      end
    end

  end
end
