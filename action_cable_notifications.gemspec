$:.push File.expand_path("../lib", __FILE__)

# Maintain your gem's version:
require "action_cable_notifications/version"

# Describe your gem and declare its dependencies:
Gem::Specification.new do |s|
  s.name        = "action_cable_notifications"
  s.version     = ActionCableNotifications::VERSION
  s.authors     = ["ByS Sistemas de Control"]
  s.email       = ["info@bys-control.com.ar"]
  s.homepage    = "https://github.com/bys-control/action_cable_notifications"
  s.summary     = "Automatic realtime notification broadcast for ActiveRecord models changes using Action Cable and websockets"
  s.description = "Rails engine that provides Automatic realtime notification broadcast for ActiveRecord models changes using Action Cable and websockets"
  s.license     = "MIT"

  s.files = Dir["{app,config,db,lib}/**/*", "MIT-LICENSE", "Rakefile", "README.md"]

  s.add_dependency "rails", "~> 5.0.0", ">= 5.0.0.1"
  s.add_dependency "lodash-rails", "~> 4.15.0"

  s.add_development_dependency "sqlite3"
  s.add_development_dependency 'pry'
  s.add_development_dependency 'pry-byebug'
end
