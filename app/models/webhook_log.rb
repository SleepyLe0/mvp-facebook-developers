class WebhookLog < ApplicationRecord
  validates :event_type, presence: true
end
