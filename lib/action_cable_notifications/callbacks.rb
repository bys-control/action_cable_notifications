module ActionCableNotifications
  module Callbacks
    extend ActiveSupport::Concern

    included do
      # Options
      class_attribute :ActionCableNotificationsOptions
      self.ActionCableNotificationsOptions = {}

      after_update :notify_update
      after_create :notify_create
      after_destroy :notify_destroy
    end

    module ClassMethods
      # Options setter
      def action_cable_notification_options= ( broadcasting, options = nil )
        if options.present?
          self.ActionCableNotificationsOptions[broadcasting.to_sym] = options
        else
          self.ActionCableNotificationsOptions.except! broadcasting.to_sym
        end
      end

      # Options getter
      def action_cable_notification_options ( broadcasting )
        if broadcasting.present?
          self.ActionCableNotificationsOptions[broadcasting.to_sym]
        else
          self.ActionCableNotificationsOptions
        end
      end

      def notify_initial ( broadcasting )
        options = self.action_cable_notification_options( broadcasting )
        {
          collection: self.model_name.collection,
          msg: 'add_collection',
          data: Array(options[:scope]).inject(self) {|o, a| o.try(*a)}
        }
      end
    end

    def notify_create
      self.ActionCableNotificationsOptions.each do |broadcasting, options|
        ActionCable.server.broadcast broadcasting,
          collection: self.model_name.collection,
          msg: 'create',
          id: self.id,
          data: self
      end
    end

    def notify_update
      changes = {}
      self.changes.each do |k,v|
        changes[k] = v[1]
      end

      self.ActionCableNotificationsOptions.each do |broadcasting, options|
        ActionCable.server.broadcast broadcasting,
          collection: self.model_name.collection,
          msg: 'update',
          id: self.id,
          data: changes
      end
    end

    def notify_destroy
      self.ActionCableNotificationsOptions.each do |broadcasting, options|
        ActionCable.server.broadcast broadcasting,
          collection: self.model_name.collection,
          msg: 'destroy',
          id: self.id
      end
    end
  end
end
