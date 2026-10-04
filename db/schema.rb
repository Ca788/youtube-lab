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

ActiveRecord::Schema[8.1].define(version: 2026_10_04_021552) do
  # These are extensions that must be enabled in order to support this database
  enable_extension "pg_catalog.plpgsql"

  create_table "users", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.string "name", null: false
    t.string "email", default: "", null: false
    t.string "encrypted_password", default: "", null: false
    t.string "reset_password_token"
    t.datetime "reset_password_sent_at"
    t.string "jti", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["email"], name: "index_users_on_email", unique: true
    t.index ["jti"], name: "index_users_on_jti", unique: true
    t.index ["reset_password_token"], name: "index_users_on_reset_password_token", unique: true
  end

  create_table "youtube_chat_messages", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.uuid "live_stream_id", null: false
    t.string "external_id", null: false
    t.string "message_type", default: "textMessageEvent", null: false
    t.text "text"
    t.datetime "published_at", null: false
    t.string "author_channel_id"
    t.string "author_name"
    t.string "author_image_url"
    t.boolean "author_is_owner", default: false, null: false
    t.boolean "author_is_moderator", default: false, null: false
    t.boolean "author_is_sponsor", default: false, null: false
    t.boolean "author_is_verified", default: false, null: false
    t.bigint "amount_micros"
    t.string "currency"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["live_stream_id", "author_channel_id"], name: "idx_on_live_stream_id_author_channel_id_9fdddb064b"
    t.index ["live_stream_id", "external_id"], name: "index_youtube_chat_messages_on_live_stream_id_and_external_id", unique: true
    t.index ["live_stream_id", "published_at"], name: "index_youtube_chat_messages_on_live_stream_id_and_published_at"
    t.index ["live_stream_id"], name: "index_youtube_chat_messages_on_live_stream_id"
  end

  create_table "youtube_live_streams", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.uuid "user_id", null: false
    t.string "video_id", null: false
    t.string "channel_id"
    t.string "channel_title"
    t.string "title"
    t.string "live_chat_id"
    t.string "status", default: "none", null: false
    t.datetime "scheduled_start_at"
    t.datetime "actual_start_at"
    t.datetime "actual_end_at"
    t.integer "concurrent_viewers"
    t.bigint "total_view_count"
    t.bigint "like_count"
    t.string "chat_next_page_token"
    t.datetime "last_polled_at"
    t.boolean "tracking", default: false, null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["tracking"], name: "index_youtube_live_streams_on_tracking"
    t.index ["user_id", "status"], name: "index_youtube_live_streams_on_user_id_and_status"
    t.index ["user_id", "video_id"], name: "index_youtube_live_streams_on_user_id_and_video_id", unique: true
    t.index ["user_id"], name: "index_youtube_live_streams_on_user_id"
  end

  create_table "youtube_viewer_samples", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.uuid "live_stream_id", null: false
    t.integer "concurrent_viewers", null: false
    t.datetime "captured_at", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["live_stream_id", "captured_at"], name: "index_youtube_viewer_samples_on_live_stream_id_and_captured_at"
    t.index ["live_stream_id"], name: "index_youtube_viewer_samples_on_live_stream_id"
  end

  add_foreign_key "youtube_chat_messages", "youtube_live_streams", column: "live_stream_id"
  add_foreign_key "youtube_live_streams", "users"
  add_foreign_key "youtube_viewer_samples", "youtube_live_streams", column: "live_stream_id"
end
