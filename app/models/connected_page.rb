class ConnectedPage < ApplicationRecord
  belongs_to :user, optional: true

  validates :page_id, presence: true, uniqueness: true
end
