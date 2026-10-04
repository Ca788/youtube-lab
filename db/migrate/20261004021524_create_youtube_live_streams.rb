class CreateYoutubeLiveStreams < ActiveRecord::Migration[8.1]
  def change
    create_table :youtube_live_streams, id: :uuid do |t|
      t.references :user, null: false, foreign_key: true, type: :uuid
      t.string :video_id, null: false
      t.string :channel_id
      t.string :channel_title
      t.string :title
      t.string :live_chat_id
      t.string :status, null: false, default: "none"
      t.datetime :scheduled_start_at
      t.datetime :actual_start_at
      t.datetime :actual_end_at
      t.integer :concurrent_viewers
      t.bigint :total_view_count
      t.bigint :like_count
      t.string :chat_next_page_token
      t.datetime :last_polled_at
      t.boolean :tracking, null: false, default: false

      t.timestamps
    end

    add_index :youtube_live_streams, [:user_id, :video_id], unique: true
    add_index :youtube_live_streams, [:user_id, :status]
    add_index :youtube_live_streams, :tracking
  end
end
