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
    #   "publication": "model.model_name.name"
    #   "command": "fetch"
    #   "params": {}
    # }
    def action(data)
      data.deep_symbolize_keys!

      publication = data[:publication]
      channel_options = @ChannelPublications[publication]
      if channel_options
        model = channel_options[:model]
        model_options = model.ChannelPublications[publication]
        params = data[:params]
        command = data[:command]

        action_params = {
          publication: publication,
          model: model,
          model_options: model_options,
          options: channel_options,
          params: params,
          command: command
        }

        case command
        when "fetch"
          fetch(action_params)
        when "create"
          create(action_params)
        when "update"
          update(action_params)
        when "destroy"
          destroy(action_params)
        end
      else
        response = {
          publication: publication,
          msg: 'error',
          command: command,
          error: "Stream for publication '#{publication}' does not exist in channel '#{self.channel_name}'."
        }

        # Send error notification to the client
        transmit response
      end
    end

    def initialize(*args)
      @collections = {}
      @ChannelPublications = {}
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

      # Default publication options
      options = {
        publication: model.model_name.name,
        cache: false,
        model_options: {},
        scope: :all
      }.merge(options).merge(params.deep_symbolize_keys)

      # These options cannot be overridden
      options[:model] = model

      publication = options[:publication]

      # Checks if the publication already exists in the channel
      if not @ChannelPublications.include?(publication)
        # Sets channel options
        @ChannelPublications[publication] = options

        # Checks if model already includes notification callbacks
        if !model.respond_to? :ChannelPublications
          model.send('include', ActionCableNotifications::Model)
        end

        # Sets broadcast options if they are not already present in the model
        if not model.ChannelPublications.key? publication
          model.broadcast_notifications_from publication, options[:model_options]
        else # Reads options configuracion from model
          options[:model_options] = model.ChannelPublications[publication]
        end

        # Start streaming
        stream_from publication, coder: ActiveSupport::JSON do |packet|
          packet.merge!({publication: publication})
          transmit_packet(packet, options)
        end
        # XXX: Transmit initial data

      end
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
