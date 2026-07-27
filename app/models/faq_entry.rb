class FaqEntry < ApplicationRecord
  validates :question, :answer, presence: true

  def self.search_answer(text)
    return nil if text.blank?

    downcase_text = text.downcase
    all.find do |entry|
      keywords = entry.keywords.to_s.downcase.split(",").map(&:strip)
      keywords.any? { |kw| downcase_text.include?(kw) } || downcase_text.include?(entry.question.downcase)
    end
  end
end
