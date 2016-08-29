module ActionCableNotifications
  module Callbacks
    extend ActiveSupport::Concern

    included do
      after_update :notify_update
      after_create :notify_create
      after_destroy :notify_destroy
    end

    module ClassMethods
      def notify_initial( collection=nil )
        collection ||= self
        data = {
          collection: self.model_name.collection,
          msg: 'add',
          data: collection.all
        }
      end
    end

    def notify_create
      ActionCable.server.broadcast self.model_name.collection,
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

      ActionCable.server.broadcast self.model_name.collection,
        collection: self.model_name.collection,
        msg: 'update',
        id: self.id,
        fields: changes
    end

    def notify_destroy
      ActionCable.server.broadcast self.model_name.collection,
        collection: self.model_name.collection,
        msg: 'destroy',
        id: self.id
    end
  end
end
