class Order < ApplicationRecord
  validates :order_number, presence: true, uniqueness: true
  validates :status, presence: true

  def self.find_by_query(text)
    return nil if text.blank?

    # Match order numbers like #1001, 1001, ORDER-1001
    match = text.match(/#?(\d{4})/)|| text.match(/order[-_]?(\w+)/i)
    if match
      num = match[1]
      where("order_number LIKE ?", "%#{num}%").first
    else
      nil
    end
  end
end
