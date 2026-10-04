class CreateYoutubeChatMessages < ActiveRecord::Migration[8.1]
  def change
    create_table :youtube_chat_messages, id: :uuid do |t|
      t.references :live_stream,
                   null:        false,
                   type:        :uuid,
                   foreign_key: { to_table: :youtube_live_streams }
      t.string :external_id, null: false
      t.string :message_type, null: false, default: "textMessageEvent"
      t.text :text
      t.datetime :published_at, null: false
      t.string :author_channel_id
      t.string :author_name
      t.string :author_image_url
      t.boolean :author_is_owner, null: false, default: false
      t.boolean :author_is_moderator, null: false, default: false
      t.boolean :author_is_sponsor, null: false, default: false
      t.boolean :author_is_verified, null: false, default: false
      t.bigint :amount_micros
      t.string :currency

      t.timestamps
    end

    add_index :youtube_chat_messages, [:live_stream_id, :external_id], unique: true
    add_index :youtube_chat_messages, [:live_stream_id, :published_at]
    add_index :youtube_chat_messages, [:live_stream_id, :author_channel_id]
  end
end
