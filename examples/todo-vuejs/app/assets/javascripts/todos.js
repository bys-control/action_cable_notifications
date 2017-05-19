// Full spec-compliant TodoMVC with localStorage persistence
// and hash-based routing in ~120 effective lines of JavaScript.
//= require './channels/todo'
//= require './vue'

var store = App.cableNotifications.registerStore("defaultStore")
var todosCollection = store.registerCollection("Todo", App.todo)

// DB persistence
var todoStorage = {
  fetch: function () {
    return todosCollection.data
  },
  add: function (todo) {
    todosCollection.create(todo)
  },
  update: function (todo) {
    todosCollection.update({id: todo.id}, todo)
  },
  remove: function (todo) {
    todosCollection.destroy({id: todo.id})
  }
}

// visibility filters
var filters = {
  all: function (todos) {
    return todos
  },
  active: function (todos) {
    return todos.filter(function (todo) {
      return !todo.completed
    })
  },
  completed: function (todos) {
    return todos.filter(function (todo) {
      return todo.completed
    })
  }
}

// app Vue instance
var app = new Vue({
  // app initial state
  data: {
    todos: todoStorage.fetch(),
    newTodo: '',
    editedTodo: null,
    visibility: 'all'
  },

  // computed properties
  // http://vuejs.org/guide/computed.html
  computed: {
    filteredTodos: function () {
      return filters[this.visibility](this.todos)
    },
    remaining: function () {
      return filters.active(this.todos).length
    },
    allDone: {
      get: function () {
        return this.remaining === 0
      },
      set: function (value) {
        this.setCompleted(value)
      }
    }
  },

  filters: {
    pluralize: function (n) {
      return n === 1 ? 'item' : 'items'
    }
  },

  // methods that implement data logic.
  // note there's no DOM manipulation here at all.
  methods: {
    toggleCompleted: function (todo) {
      todo.completed = !todo.completed
      todoStorage.update(todo)
    },

    addTodo: function () {
      var value = this.newTodo && this.newTodo.trim()
      if (!value) {
        return
      }

      todoStorage.add({
        title: value,
        completed: false
      })

      this.newTodo = ''
    },

    removeTodo: function (todo) {
      todoStorage.remove(todo)
    },

    editTodo: function (todo) {
      this.beforeEditCache = todo.title
      this.editedTodo = todo
    },

    doneEdit: function (todo) {
      if (!this.editedTodo) {
        return
      }
      this.editedTodo = null
      todo.title = todo.title.trim()
      if (!todo.title) {
        this.removeTodo(todo)
      } else {
        todoStorage.update(todo)
      }
    },

    cancelEdit: function (todo) {
      this.editedTodo = null
      todo.title = this.beforeEditCache
    },

    removeCompleted: function () {
      var todo = filters.completed(this.todos)[0]
      if( todo ) {
        todosCollection.destroy({id: todo.id})
        // This is a workaround for sqlite3 databases because it doesn't
        // allow concurrent transactions
        setTimeout(this.removeCompleted.bind(this), 50)
      }
    },

    setCompleted: function (value) {
      var todo = value ? filters.active(this.todos)[0] : filters.completed(this.todos)[0]
      if( todo ) {
        todo.completed = value
        todosCollection.update({id: todo.id}, {completed: value})
        // This is a workaround for sqlite3 databases because it doesn't
        // allow concurrent transactions
        setTimeout(this.setCompleted.bind(this, value), 50)
      }
    }
  },

  // a custom directive to wait for the DOM to be updated
  // before focusing on the input field.
  // http://vuejs.org/guide/custom-directive.html
  directives: {
    'todo-focus': function (el, value) {
      if (value) {
        el.focus()
      }
    }
  }
})

// handle routing
function onHashChange () {
  var visibility = window.location.hash.replace(/#\/?/, '')
  if (filters[visibility]) {
    app.visibility = visibility
  } else {
    window.location.hash = ''
    app.visibility = 'all'
  }
}

window.addEventListener('hashchange', onHashChange)
onHashChange()

// mount
app.$mount('.todoapp')
