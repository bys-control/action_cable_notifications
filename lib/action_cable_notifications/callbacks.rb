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
      def set_action_cable_notification_options( options = {} )
        self.ActionCableNotificationsOptions = options
      end

      def notify_initial
        data = {
          collection: self.model_name.collection,
          msg: 'add',
          data: self.all
        }
      end
    end

    def notify_create
      ActionCable.server.broadcast self.ActionCableNotificationsOptions[:broadcast_name],
        collection: self.model_name.collection,
        msg: 'create',
        id: self.id,
        fields: self
    end

    def notify_update
      changes = {}
      self.changes.each do |k,v|
        changes[k] = v[1]
      end

      ActionCable.server.broadcast self.ActionCableNotificationsOptions[:broadcast_name],
        collection: self.model_name.collection,
        msg: 'update',
        id: self.id,
        fields: changes
    end

    def notify_destroy
      ActionCable.server.broadcast self.ActionCableNotificationsOptions[:broadcast_name],
        collection: self.model_name.collection,
        msg: 'destroy',
        id: self.id
    end
  end
end
