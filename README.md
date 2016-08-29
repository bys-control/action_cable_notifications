# ActionCableNotifications
[![Gem Version](https://badge.fury.io/rb/action_cable_notifications.svg)](https://badge.fury.io/rb/action_cable_notifications)

This gem is under develoment and is not ready for production usage.

## Usage
How to use my plugin.

## Installation
Add this line to your application's Gemfile:

```ruby
gem 'action_cable_notifications'
```

And then execute:
```bash
$ bundle
```

Or install it yourself as:
```bash
$ gem install action_cable_notifications
```

## Usage
Create a new channel (`rails g cahnnel Test`) or modify existing one including `ActionCableNotifications::Streams` module. 

```ruby
class TestChannel < ApplicationCable::Channel

  include ActionCableNotifications::Streams

  def subscribed
    stream_notifications_for model, include_initial: true
  end

  def unsubscribed
    # Any cleanup needed when channel is unsubscribed
  end
end
```

## Contributing
Contribution directions go here.

## License
The gem is available as open source under the terms of the [MIT License](http://opensource.org/licenses/MIT).

