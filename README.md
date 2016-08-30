# ActionCableNotifications
[![Gem Version](https://badge.fury.io/rb/action_cable_notifications.svg)](https://badge.fury.io/rb/action_cable_notifications)

**This gem is being developed as part of an internal proyect. It's constantly changing and is not ready for production usage. Use at your own risk!!**

## Usage

### Server side
On **server-side**, create a new channel (`rails g cahnnel Test`) or modify existing one including `ActionCableNotifications::Streams` module. 

```ruby
class TestChannel < ApplicationCable::Channel

  include ActionCableNotifications::Streams

  def subscribed
    stream_notifications_for Users, include_initial: true, scope: [:all, [:limit, 5], [:order, :id]]
  end

  def unsubscribed
    # Any cleanup needed when channel is unsubscribed
  end
end
```

Method `stream_notifications_for` receives the following parameters: 

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

### Client side
On **client-side**, use action_cable subscriptions as stated in the documentation. Received data will have the following format:

#### Initial values for collection
```javascript
{
  collection: 'users',
  msg: 'add_collection',
  data: [
    {
      id: 1,
      username: 'username 1',
      color: 'red'
    },
    {
      id: 2,
      username: 'username 2',
      color: 'green'
  ]
}
```

#### Create event
```javascript
{
  collection: 'users',
  msg: 'create',
  id: 3,
  data: {
    id: 3,
    username: 'username 3'
    color: 'blue'
  }
}
```

#### Update event
Update event will only transmit changed fields for the model.
```javascript
{
  collection: 'users',
  msg: 'update',
  id: 2,
  data: {
    color: 'light blue'
  }
}
```

#### Destroy event
```javascript
{
  collection: 'users',
  msg: 'destroy',
  id: 2
}
```

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

## Contributing
Contributions are welcome. We will be happy to receive issues, comments and pull-request to make this gem better.

## License
The gem is available as open source under the terms of the [MIT License](http://opensource.org/licenses/MIT).

