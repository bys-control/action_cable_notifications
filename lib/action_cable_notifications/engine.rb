require 'lodash-rails'
require 'action_cable_notifications/model.rb'
require 'action_cable_notifications/channel.rb'

module ActionCableNotifications
  class Engine < ::Rails::Engine
    isolate_namespace ActionCableNotifications
  end
end
