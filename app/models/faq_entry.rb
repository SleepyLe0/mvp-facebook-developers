class FaqEntry < ApplicationRecord
  belongs_to :user, optional: true

  validates :question, :answer, presence: true

  # Respects the current scope, so `user.faq_entries.search_answer(text)`
  # only matches that user's rules.
  def self.search_answer(text)
    return nil if text.blank?

    downcase_text = text.downcase
    all.find do |entry|
      keywords = entry.keywords.to_s.downcase.split(",").map(&:strip)
      keywords.any? { |kw| downcase_text.include?(kw) } || downcase_text.include?(entry.question.downcase)
    end
  end
end
