class SupportTicket < ApplicationRecord
  belongs_to :user, optional: true

  validates :psid, presence: true

  scope :open_tickets, -> { where(status: "open") }
  scope :recent, -> { order(updated_at: :desc) }

  # Meta allows a human agent to reply up to 7 days after the customer's last message.
  # Fall back to created_at for tickets created before the column existed.
  def human_agent_window_open?
    reference = last_customer_message_at || created_at
    reference.present? && reference > 7.days.ago
  end
end
