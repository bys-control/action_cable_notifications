require 'lodash-rails'
require 'action_cable_notifications/callbacks.rb'
require 'action_cable_notifications/streams.rb'

module ActionCableNotifications
  class Engine < ::Rails::Engine
    isolate_namespace ActionCableNotifications
  end
end
