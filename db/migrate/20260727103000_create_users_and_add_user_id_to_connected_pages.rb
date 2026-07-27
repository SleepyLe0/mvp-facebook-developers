class CreateUsersAndAddUserIdToConnectedPages < ActiveRecord::Migration[8.0]
  def change
    create_table :users do |t|
      t.string :name
      t.string :email, null: false
      t.string :password_digest
      t.string :facebook_uid
      t.text :facebook_access_token

      t.timestamps
    end
    add_index :users, :email, unique: true

    add_reference :connected_pages, :user, foreign_key: true
  end
end
