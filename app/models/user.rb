class User < ApplicationRecord
  has_many :connected_pages, dependent: :destroy

  validates :facebook_uid, presence: true, uniqueness: true

  def display_name
    name.presence || email.presence || "Facebook User (#{facebook_uid})"
  end
end
