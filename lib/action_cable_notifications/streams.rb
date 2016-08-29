module ActionCableNotifications::Streams
  extend ActiveSupport::Concern

  included do
    class_attribute :ActionCableNotificationsOptions
    self.ActionCableNotificationsOptions = {}
  end

  private

  def stream_for(model, options = {})

    # Original behaviour
    if options.is_a? Proc
      super(model, options)
    else

      # Checks if model already includes notification callbacks
      if !model.respond_to? :notify_initial
        model.send('include', ActionCableNotifications::Callbacks)
      end

      super(model, options[:callback])

      # Transmit initial state if required
      if options[:include_initial].present?
        transmit model.notify_initial
      end
    end
  end

end
