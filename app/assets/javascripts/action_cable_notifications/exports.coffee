console.log('exports')

# Export to global namespace
#######################################
@App = {} unless @App
@App.cable_notifications = new CableNotifications()
