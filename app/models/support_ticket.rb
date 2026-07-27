class SupportTicket < ApplicationRecord
  validates :psid, presence: true

  scope :open_tickets, -> { where(status: "open") }
  scope :recent, -> { order(updated_at: :desc) }
end
