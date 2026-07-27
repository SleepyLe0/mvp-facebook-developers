class AddLastCustomerMessageAtToSupportTickets < ActiveRecord::Migration[8.1]
  def change
    add_column :support_tickets, :last_customer_message_at, :datetime
  end
end
