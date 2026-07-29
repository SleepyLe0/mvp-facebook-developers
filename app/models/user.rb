class User < ApplicationRecord
  has_many :connected_pages, dependent: :destroy
  has_many :faq_entries, dependent: :destroy
  has_many :webhook_logs, dependent: :nullify

  validates :facebook_uid, presence: true, uniqueness: true

  def display_name
    name.presence || email.presence || "Facebook User (#{facebook_uid})"
  end
end
