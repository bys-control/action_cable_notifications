require 'action_cable_notifications/channel_actions.rb'

module ActionCableNotifications
  module Channel
    extend ActiveSupport::Concern

    included do
      # class variables
      class_attribute :ActionCableNotifications

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
      when "create"
        create(params)
      when "update"
        update(params)
      when "destroy"
        destroy(params)
      end
    end

    def initialize(*args)
      super
      @collections = {}
    end

    def subscribed
      puts "subscribed"
    end

    def unsubscribed
      puts "unsubscribed"
      stop_all_streams
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
        transmit_packet(packet)
      end

    end

    def transmit_packet(packet)
      packet = packet.as_json.deep_symbolize_keys!
      if update_cache(packet)
        transmit packet
      end
    end

    #
    # Updates server side cache of client side collections
    #
    def update_cache(packet)
      case packet[:msg]
      when 'upsert_many'
        if @collections[packet[:collection]].nil?
          collection = @collections[packet[:collection]] = []
          packet[:data].each do |record|
            collection.push record
          end
          true
        else
          collection = @collections[packet[:collection]]
          retval = false

          packet[:data].each do |record|
            current_record = collection.find{|c| c[:id]==record[:id]}
            if current_record
              new_record = current_record.merge(record)
              if new_record != current_record
                current_record.merge!(record)
                retval = true
              end
            else
              collection.push record
              retval = true
            end
          end
          retval
        end

      when 'create'
        @collections[packet[:collection]].push packet[:data]
        true

      when 'update'
        record = @collections[packet[:collection]].find{|c| c.id==packet[:id]}
        if record
          record.merge!(packet[:data])
        end
        true

      when 'destroy'
        index = @collections[packet[:collection]].find_index{|c| c.id==packet[:id]}
        if index
          @collections[packet[:collection]].delete_at(index)
        end
        true
      end

    end

  end
end
