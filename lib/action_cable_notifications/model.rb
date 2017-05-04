module ActionCableNotifications
  module Model
    extend ActiveSupport::Concern

    included do
      # Action cable notification options storage
      class_attribute :ActionCableNotificationsOptions
      self.ActionCableNotificationsOptions = {}

      # Register Callbacks
      before_update :prepare_update
      after_update :notify_update
      after_create :notify_create
      after_destroy :notify_destroy
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
          track_scope_changes: true,
          scope: :all,             # Default collection scope
          records: []
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
        scope = scope.to_a if scope.is_a? Hash
        Array(scope).inject(self) {|o, a| o.try(*a)} rescue nil
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
            msg: 'upsert_many',
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
          if options[:scope]==:all or self.class.scoped_collection(options[:scope]).where(id: self.id).present?
            ActionCable.server.broadcast broadcasting,
              collection: self.model_name.collection,
              msg: 'create',
              id: self.id,
              data: self
          end
        end
      end
    end

    def prepare_update
      self.ActionCableNotificationsOptions.each do |broadcasting, options|
        if options[:actions].include? :update
          if options[:scope]==:all
            options[:records].push self
          else
            record = self.class.scoped_collection(options[:scope]).where(id: self.id)
            if record.present?
              options[:records].push record.first
            end
          end
        end
      end
    end

    #
    # Broadcast notifications when a record is updated. Only changed fields will be sent
    # if they are within configured scope
    #
    def notify_update
      # Checks if there are changes in the model
      if !self.changes.empty?
        self.ActionCableNotificationsOptions.each do |broadcasting, options|
          if options[:actions].include? :update
            # Checks if previous record was within scope
            record = options[:records].detect{|r| r.id==self.id}
            was_in_scope = record.present?
            options[:records].delete(record) if was_in_scope

            # Checks if current record is within scope
            if options[:track_scope_changes]==true
              is_in_scope = false
              if options[:scope]==:all
                record = self
                is_in_scope = true
              else
                record = self.class.scoped_collection(options[:scope]).where(id: self.id)
                if record.present?
                  record = record.first
                  is_in_scope = true
                end
              end
            else
              is_in_scope = was_in_scope
            end

            # Broadcasts notifications about model changes
            if is_in_scope
              # Get model changes and applies them to the scoped collection record
              changes = {}
              self.changes.each do |k,v|
                if record.respond_to?(k)
                  changes[k] = v[1]
                end
              end

              if !changes.empty?
                ActionCable.server.broadcast broadcasting,
                  collection: self.model_name.collection,
                  msg: 'upsert',
                  id: self.id,
                  data: changes
              end
            elsif was_in_scope # checks if needs to delete the record if its no longer in scope
              ActionCable.server.broadcast broadcasting,
                collection: self.model_name.collection,
                msg: 'destroy',
                id: self.id
            end
          end
        end
      end
    end

    #
    # Broadcast notifications when a record is destroyed.
    #
    def notify_destroy
      self.ActionCableNotificationsOptions.each do |broadcasting, options|
        if options[:scope]==:all or options[:actions].include? :destroy
          # Checks if record is within scope before broadcasting
          if options[:scope]==:all or self.class.scoped_collection(options[:scope]).where(id: self.id).present?
            ActionCable.server.broadcast broadcasting,
              collection: self.model_name.collection,
              msg: 'destroy',
              id: self.id
          end
        end
      end
    end

  end
end
