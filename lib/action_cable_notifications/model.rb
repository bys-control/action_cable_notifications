module ActionCableNotifications
  module Model
    extend ActiveSupport::Concern

    included do
      # Action cable notification options storage
      class_attribute :ChannelPublications
      self.ChannelPublications = {}

      # Register Callbacks
      before_update :prepare_update
      after_update :notify_update
      after_create :notify_create
      after_destroy :notify_destroy

      def record_within_scope records
        if records.respond_to?(:where)
          found_record = records.where(id: self.id).first
        elsif records.respond_to?(:detect) and (found_record = records.detect{|e| e["id"]==self.id})
          found_record
        else
          nil
        end
      end

    end

    class_methods do
      #
      # Sets or removes notificacions options for Active Record model
      #
      # @param [sym] publication Topic name to broadcast in
      # @param [hash] options Hash containing notification options
      #
      def broadcast_notifications_from ( publication, options = {} )
        # Default options
        options = {
          actions: [:create, :update, :destroy],
          track_scope_changes: false,
          scope: :all,             # Default collection scope
          records: []
          }.merge(options)

        self.ChannelPublications[publication.to_s] = options
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
      # @param [Sym] publication Name of publication stream
      #
      # @return [Hash] Hash containing the results in the following format:
      # {
      #   msg: 'add_collection',
      #   data: self.scoped_collection(options[:scope])
      # }
      def notify_initial ( publication )
        options = self.ChannelPublications[publication.to_s]
        if options.present?
          {
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
      self.ChannelPublications.each do |publication, options|
        if options[:actions].include? :create
          # Checks if records is within scope before broadcasting
          records = self.class.scoped_collection(options[:scope])

          if options[:scope]==:all or record_within_scope(records)
            ActionCable.server.broadcast publication,
              {
                msg: 'create',
                id: self.id,
                data: self
              }
          end
        end
      end
    end

    def prepare_update
      self.ChannelPublications.each do |publication, options|
        if options[:actions].include? :update
          if options[:scope]==:all
            options[:records].push self
          else
            record = record_within_scope(self.class.scoped_collection(options[:scope]))
            if record.present?
              options[:records].push record
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
      # Get model changes
      if self.respond_to?(:saved_changes) # For Rails >= 5.1
        changes = self.saved_changes.transform_values(&:second)
      else # For Rails < 5.1
        changes = self.changes.transform_values(&:second)
      end

      # Checks if there are changes in the model
      if !changes.empty?
        self.ChannelPublications.each do |publication, options|
          if options[:actions].include? :update
            # Checks if previous record was within scope
            record = record_within_scope(options[:records])
            was_in_scope = record.present?

            options[:records].delete(record) if was_in_scope

            # Checks if current record is within scope
            if options[:track_scope_changes]==true
              is_in_scope = false
              if options[:scope]==:all
                record = self
                is_in_scope = true
              else
                record = record_within_scope(self.class.scoped_collection(options[:scope]))
                if record.present?
                  is_in_scope = true
                end
              end
            else
              is_in_scope = was_in_scope
            end

            # Broadcasts notifications about model changes
            if is_in_scope
              if was_in_scope
                # Get model changes and applies them to the scoped collection record
                changes.select!{|k,v| record.respond_to?(k)}

                if !changes.empty?
                  ActionCable.server.broadcast publication,
                    {
                      msg: 'update',
                      id: self.id,
                      data: changes
                    }
                end
              else
                ActionCable.server.broadcast publication,
                  {
                    msg: 'create',
                    id: record.id,
                    data: record
                  }
              end
            elsif was_in_scope # checks if needs to delete the record if its no longer in scope
              ActionCable.server.broadcast publication,
                {
                  msg: 'destroy',
                  id: self.id
                }
            end
          end
        end
      end
    end

    #
    # Broadcast notifications when a record is destroyed.
    #
    def notify_destroy
      self.ChannelPublications.each do |publication, options|
        if options[:scope]==:all or options[:actions].include? :destroy
          # Checks if record is within scope before broadcasting
          if options[:scope]==:all or record_within_scope(self.class.scoped_collection(options[:scope])).present?
            ActionCable.server.broadcast publication,
              {
                msg: 'destroy',
                id: self.id
              }
          end
        end
      end
    end

  end
end
