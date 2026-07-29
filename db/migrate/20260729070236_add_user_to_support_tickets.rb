class AddUserToSupportTickets < ActiveRecord::Migration[8.1]
  def change
    add_reference :support_tickets, :user, null: true, foreign_key: true
  end
end
