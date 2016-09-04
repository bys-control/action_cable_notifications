module ActionCableNotifications
  module Callbacks
    extend ActiveSupport::Concern

    included do
      # Action cable notification options storage
      class_attribute :ActionCableNotificationsOptions
      self.ActionCableNotificationsOptions = {}

      # Register Callbacks
      after_update :notify_update
      after_create :notify_create
      before_destroy :notify_destroy
    end

    module ClassMethods

      #
      # Sets or removes notificacions options for Active Record model
      #
      # @param [sym] broadcasting Topic name to broadcast in
      # @param [hash] options Hash containing notification options
      #
      def broadcast_notifications_from ( broadcasting, options = {} )
        # Default options
        options = {
          actions: [:create, :update, :destroy],
          scope: :all             # Default collection scope
          }.merge(options)

        self.ActionCableNotificationsOptions[broadcasting.to_s] = options
      end

      #
      # Returns collection scoped as specified in parameters.
      #
      # @param [Array] scope Contains the scopes to be applied. For
      # example: [[:limit, 5], [:order, :id]]
      #
      # @return [ActiveRecordRelation] Results fetched from the database
      #
      def scoped_collection ( scope = :all )
        Array(scope).inject(self) {|o, a| o.try(*a)}
      end

      #
      # Retrieves initial values to be sent to clients upon subscription
      #
      # @param [Sym] broadcasting Name of broadcasting stream
      #
      # @return [Hash] Hash containing the results in the following format:
      # {
      #   collection: self.model_name.collection,
      #   msg: 'add_collection',
      #   data: self.scoped_collection(options[:scope])
      # }
      def notify_initial ( broadcasting )
        options = self.ActionCableNotificationsOptions[broadcasting.to_s]
        if options.present?
          {
            collection: self.model_name.collection,
            msg: 'add_collection',
            data: self.scoped_collection(options[:scope])
          }
        end
      end
    end

    #
    # Broadcast notifications when a new record is created
    #
    def notify_create
      self.ActionCableNotificationsOptions.each do |broadcasting, options|
        if options[:actions].include? :create
          # Checks if record is within scope before broadcasting
          if self.class.scoped_collection(options[:scope]).where(id: self.id)
            ActionCable.server.broadcast broadcasting,
              collection: self.model_name.collection,
              msg: 'added',
              id: self.id,
              data: self
          end
        end
      end
    end

    #
    # Broadcast notifications when a record is updated. Only changed
    # field will be sent.
    #
    def notify_update
      changes = {}
      self.changes.each do |k,v|
        changes[k] = v[1]
      end

      self.ActionCableNotificationsOptions.each do |broadcasting, options|
        if options[:actions].include? :update
          # Checks if record is within scope before broadcasting
          if self.class.scoped_collection(options[:scope]).where(id: self.id)
            # XXX: Performance required. For small data sets this should be
            # fast enough, but for large data sets this could be slow. As
            # clients should have a limited subset of the dataset loaded at a
            # time, caching the results already sent to clients in server memory
            # should not have a big impact in memory usage but can improve
            # performance for large data sets where only a sub
            ActionCable.server.broadcast broadcasting,
              collection: self.model_name.collection,
              msg: 'changed',
              id: self.id,
              data: changes
          end
        end
      end
    end

    #
    # Broadcast notifications when a record is destroyed.
    #
    def notify_destroy
      self.ActionCableNotificationsOptions.each do |broadcasting, options|
        if options[:actions].include? :destroy
          # Checks if record is within scope before broadcasting
          if self.class.scoped_collection(options[:scope]).where(id: self.id)
            ActionCable.server.broadcast broadcasting,
              collection: self.model_name.collection,
              msg: 'removed',
              id: self.id
          end
        end
      end
    end

  end
end
