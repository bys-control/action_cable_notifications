module ActionCableNotifications
  module Streams
    extend ActiveSupport::Concern

    included do
      attr_accessor :stream_notification_options
      # Actions to be done when the module is included
    end

    #
    # Methods to be called from the client with perform()
    ################################################################

    #
    # Fetch records from the DB and send them to the client
    #
    # @param [Hash] selector Specifies conditions that the registers should match
    # @param [Hash] options Options
    #
    def fetch(data)
      # XXX: Check if the client is allowed to call the method

      # Remove action name from data
      data.except!("action")

      # Record fetchnig options
      options = {
        limit: data["limit"],
        where: data["where"] || {},
        fields: data["fields"]
      }

      model = self.stream_notification_options[:model]
      broadcasting = self.stream_notification_options[:broadcasting]
      broadcasting_options = model.ActionCableNotificationsOptions[broadcasting]

      results = model.
                  select(options[:select]).
                  limit(options[:limit]).
                  where(options[:where]).
                  scoped_collection(broadcasting_options[:scope]).
                  to_a() rescue []

      response = { collection: model.model_name.collection,
        msg: 'update_many',
        data: results
      }

      # Send data to the client
      transmit response
    end

    #
    # Update one record from the DB
    #
    def update(data)
      # XXX: Check if the client is allowed to call the method

      # Remove action name from data
      data.except!("action")

      # Record fetchnig options
      options = {
        id: data["id"],
        fields: data["fields"]
      }

      model = self.stream_notification_options[:model]
      broadcasting = self.stream_notification_options[:broadcasting]
      broadcasting_options = model.ActionCableNotificationsOptions[broadcasting]

      record = model.find(options[:id]) rescue nil

      if record.present?
        result = record.update_attributes(options[:fields]) rescue false

        if !result
          response = { collection: model.model_name.collection,
            msg: 'error',
            cmd: 'update',
            error: record.errors.full_messages
          }

          # Send error notification to the client
          transmit response
        end
      end
    end

    #
    # Remove records from the DB
    #
    def remove

    end

    #
    # Private methods
    ################################################################

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
