class WebhookLog < ApplicationRecord
  belongs_to :user, optional: true

  validates :event_type, presence: true
end
