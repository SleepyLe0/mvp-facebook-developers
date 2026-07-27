class UserProfile < ApplicationRecord
  validates :psid, presence: true, uniqueness: true

  def full_name
    "#{first_name} #{last_name}".strip.presence || "Anonymous User (#{psid})"
  end
end
