class AddUserToFaqEntriesAndWebhookLogs < ActiveRecord::Migration[8.1]
  def change
    add_reference :faq_entries, :user, foreign_key: true, null: true
    add_reference :webhook_logs, :user, foreign_key: true, null: true
  end
end
