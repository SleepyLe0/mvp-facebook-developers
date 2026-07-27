class AddHandledByHumanToSupportTickets < ActiveRecord::Migration[8.1]
  def change
    add_column :support_tickets, :handled_by_human, :boolean
  end
end
