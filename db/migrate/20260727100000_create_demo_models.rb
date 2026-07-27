class CreateDemoModels < ActiveRecord::Migration[8.0]
  def change
    create_table :webhook_logs do |t|
      t.string :event_type
      t.text :payload
      t.string :status
      t.text :error_message

      t.timestamps
    end

    create_table :faq_entries do |t|
      t.string :question, null: false
      t.text :answer, null: false
      t.string :keywords

      t.timestamps
    end

    create_table :orders do |t|
      t.string :order_number, null: false
      t.string :status, null: false
      t.string :customer_name
      t.text :item_details

      t.timestamps
    end
    add_index :orders, :order_number, unique: true

    create_table :support_tickets do |t|
      t.string :psid, null: false
      t.string :customer_name
      t.string :status, default: "open"
      t.text :last_message
      t.text :human_agent_notes

      t.timestamps
    end
    add_index :support_tickets, :psid

    create_table :user_profiles do |t|
      t.string :psid, null: false
      t.string :first_name
      t.string :last_name
      t.text :profile_pic
      t.string :locale

      t.timestamps
    end
    add_index :user_profiles, :psid, unique: true

    create_table :connected_pages do |t|
      t.string :page_id, null: false
      t.string :name
      t.text :access_token
      t.string :instagram_business_account_id
      t.boolean :subscribed, default: false

      t.timestamps
    end
    add_index :connected_pages, :page_id, unique: true
  end
end
