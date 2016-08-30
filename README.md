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
    stream_notifications_for model, include_initial: true, scope: [:all, [:limit, 5], [:order, :id]]
  end

  def unsubscribed
    # Any cleanup needed when channel is unsubscribed
  end
end
```

Method stream_notifications_for receives the following parameters: 

```ruby
stream_notifications_for(model, options = {}, &block)
```

* model: **(ActiveRecord model)** - Specifies the model to be used for data fetching and event binding.
* options: **(Hash)** - Options to be used for configuracion. Default options are:
```ruby
{
  actions: [:create, :update, :destroy],     # Controller actions to attach to
  broadcasting: model.model_name.collection, # Name of the pubsub stream
  callback: nil,                             # Same as http://edgeapi.rubyonrails.org/classes/ActionCable/Channel/Streams.html
  coder: nil,                                # Pass `coder: ActiveSupport::JSON` to decode messages as JSON before passing to the callback.
                                             # Defaults to `coder: nil` which does no decoding, passes raw messages.
  include_initial: false,                    # Send all records to the subscriber upon connection
  params: params,                            # Params sent during subscription
  scope: :all                                # Default collection scope
}
```
* block: **(Proc)** - Same as options[:callback]

## Contributing
Contribution directions go here.

## License
The gem is available as open source under the terms of the [MIT License](http://opensource.org/licenses/MIT).

