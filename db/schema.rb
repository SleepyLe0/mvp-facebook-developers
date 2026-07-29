# This file is auto-generated from the current state of the database. Instead
# of editing this file, please use the migrations feature of Active Record to
# incrementally modify your database, and then regenerate this schema definition.
#
# This file is the source Rails uses to define your schema when running `bin/rails
# db:schema:load`. When creating a new database, `bin/rails db:schema:load` tends to
# be faster and is potentially less error prone than running all of your
# migrations from scratch. Old migrations may fail to apply correctly if those
# migrations use external dependencies or application code.
#
# It's strongly recommended that you check this file into your version control system.

ActiveRecord::Schema[8.1].define(version: 2026_07_29_030017) do
  create_table "connected_pages", force: :cascade do |t|
    t.text "access_token"
    t.datetime "created_at", null: false
    t.string "instagram_business_account_id"
    t.string "name"
    t.string "page_id", null: false
    t.boolean "subscribed", default: false
    t.datetime "updated_at", null: false
    t.integer "user_id"
    t.index ["page_id"], name: "index_connected_pages_on_page_id", unique: true
    t.index ["user_id"], name: "index_connected_pages_on_user_id"
  end

  create_table "faq_entries", force: :cascade do |t|
    t.text "answer", null: false
    t.datetime "created_at", null: false
    t.string "keywords"
    t.string "question", null: false
    t.datetime "updated_at", null: false
    t.integer "user_id"
    t.index ["user_id"], name: "index_faq_entries_on_user_id"
  end

  create_table "orders", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.string "customer_name"
    t.text "item_details"
    t.string "order_number", null: false
    t.string "status", null: false
    t.datetime "updated_at", null: false
    t.index ["order_number"], name: "index_orders_on_order_number", unique: true
  end

  create_table "support_tickets", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.string "customer_name"
    t.boolean "handled_by_human"
    t.text "human_agent_notes"
    t.datetime "last_customer_message_at"
    t.text "last_message"
    t.string "psid", null: false
    t.string "status", default: "open"
    t.datetime "updated_at", null: false
    t.index ["psid"], name: "index_support_tickets_on_psid"
  end

  create_table "user_profiles", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.string "first_name"
    t.string "last_name"
    t.string "locale"
    t.text "profile_pic"
    t.string "psid", null: false
    t.datetime "updated_at", null: false
    t.index ["psid"], name: "index_user_profiles_on_psid", unique: true
  end

  create_table "users", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.string "email", null: false
    t.text "facebook_access_token"
    t.string "facebook_uid"
    t.string "name"
    t.string "password_digest"
    t.datetime "updated_at", null: false
    t.index ["email"], name: "index_users_on_email", unique: true
  end

  create_table "webhook_logs", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.text "error_message"
    t.string "event_type"
    t.text "payload"
    t.string "status"
    t.datetime "updated_at", null: false
    t.integer "user_id"
    t.index ["user_id"], name: "index_webhook_logs_on_user_id"
  end

  add_foreign_key "connected_pages", "users"
  add_foreign_key "faq_entries", "users"
  add_foreign_key "webhook_logs", "users"
end
