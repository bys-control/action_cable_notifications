# == Schema Information
#
# Table name: todos
#
#  id         :integer          not null, primary key
#  title      :string
#  completed  :boolean
#  created_at :datetime         not null
#  updated_at :datetime         not null
#

class Todo < ApplicationRecord
  include ActionCableNotifications::Model

  broadcast_notifications_from self.model_name.collection,
    scope: {
        select: [:id, :title, :completed]
    }
end
