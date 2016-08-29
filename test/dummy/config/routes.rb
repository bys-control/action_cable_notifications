Rails.application.routes.draw do
  mount ActionCableNotifications::Engine => "/action_cable_notifications"
end
