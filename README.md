# ActionCableNotifications
[![Gem Version](https://badge.fury.io/rb/action_cable_notifications.svg)](https://badge.fury.io/rb/action_cable_notifications)

## Description
**This gem is being developed as part of an internal proyect. It's constantly changing and is not ready for production usage. Use at your own risk!!**

This gem provides realtime sync of Model data between a Rails 5 app and its web clients. It was inspired in [meteor's](https://www.meteor.com/) [ddp](https://github.com/meteor/meteor/tree/devel/packages/ddp) and [minimongo](https://github.com/meteor/meteor/tree/devel/packages/minimongo) for data syncing and client side storage. It uses new Rails 5 Action Cable to communicate with the server and sync collections in realtime.

Check the sample [todo app](/examples/todo-vuejs) that uses this gem with [VueJS](http://vuejs.org/) for rendering. Will try to upload more examples shortly.

## Usage

### Server side
On **server-side**, create a new channel (`rails g cahnnel Test`) or modify existing one including `ActionCableNotifications::Streams` module. 

```ruby
class TestChannel < ApplicationCable::Channel

  include ActionCableNotifications::Channel

  def subscribed
    # Config streaming for Customer model with default options
    stream_notifications_for Customer
    # Can have more than one ActiveRecord model streaming per channel
    stream_notifications_for Invoice,
      model_options: {
        scope: { 
          limit: 5, 
          order: :id, 
          select: [:id, :customer_id, :seller_id, :amount]
      }
    }
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
  broadcasting: model.model_name.collection, # Name of the pubsub stream
  params: params,                            # Params sent when client subscribes
  cache: false,                              # Turn off server-side cache of client-side data
  model_options: {
    actions: [:create, :update, :destroy],     # Model callbacks to attach to
    scope: :all                                # Default collection scope. Can be an ,Array or Hash
    track_scope_changes: true                 # During model updates, checks if the changes affect scope inclusion of the resulting record
  }
}
```

### Client side
On **client-side**, you will need to create a subscription to the channel and then you can instantiate a **Store** and one or more **Collections** to keep the data synced with the server. You can register more than one store per application and more than one collection per store.

```javascript
App.testChannel = App.cable.subscriptions.create("TestChannel", {
  connected: function() {
    return console.log("Connected")
  },
  disconnected: function() {
    return console.log("Disconnected")
  }
}

// Create a store
store = App.cableNotifications.registerStore('storeName')

// Create the collections and sync them with the server using testChannel
customersCollection = store.registerCollection('customers', App.testChannel)
invoicesCollection = store.registerCollection('invoices', App.testChannel)
```

That's it! Now you have customers and invoices collections available in your clients. Data will be available as an array in customersCollection.data and invoicesCollection.data objects.

#### Stores
Stores are groups of collections. They hold a list of available collections and its options for syncing with the server using channels subscriptions. They expose the following methods:

##### registerCollection(collectionName, channelSubscription, tableName)
Called to register a new collection into the store. **collectionName** must be unique in the store. **channelSubscription** specifies which channel to use to sync with the server. Multiple collections can share the same channel for syncing. If no channel is specified, the collection will work standalone. You can always turn on syncing for a collection later using *syncToChannel* method.

By default, *collectionName* is used on the server side to identify the table on the DB. If you are using a different tablename, you can specify it in the *tableName* parameter.

Example:
```javascript
customersCollection = store.registerCollection('customers', App.testChannel)
```

##### syncToChannel()
Used to sync a standalone collection with the server using a channel.
```javascript
store.syncToChannel(App.testChannel, customersCollection)
```

#### Collections
Collections is where data is stored on clients. Collections can be standalone or synced with the server using channel subcriptions.

The registered collection object expose some methods to give easy access to data stored on clients. It uses [lodash](https://lodash.com) for data manipulation, so you can check its documentation for details on parameters.

##### fetch(parameters)
Retrieves data from the server. You can specify a hash of parameters to send to server.
```javascript
invoicesCollection.fetch({limit: 10, where: 'amount>100'})
```
##### filter(selector)
Filter data already present in the client and return all records that met the field values specified in *selector* parameter. You can specify a hash of options or a callback function.
```javascript
invoices = invoicesCollection.where({customer_id: 14})
```
##### find(selector)
Same as filter but returns only the first record found.
```javascript
invoice = invoicesCollection.find({customer_id: 14})
```
##### create(fields)
Create a new record having the specified field values and sync it with the server.
```javascript
invoice = invoicesCollection.create({customer_id: 14, seller_id: 5, amount: 100})
```
##### update(selector, fields)
Updates an existing record identified by *selector* with the specified field values and sync it with the server.
```javascript
invoice = invoicesCollection.update({id: 55},{seller_id: 6, amount: 150})
```
##### upsert(selector, fields)
If an existing record cannot be found for updating, a new record is created with the specified fields.
```javascript
invoice = invoicesCollection.upsert({id: 55},{seller_id: 6, amount: 150})
```
##### destroy(selector)
Destroys an existing record identified by *selector* and sync it with the server.
```javascript
invoicesCollection.destroy({id: 55})
```

### Server sent messages:

Received data will have the following format:

#### Initial values for collection
```javascript
{
  collection: 'users',
  msg: 'upsert_many',
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

