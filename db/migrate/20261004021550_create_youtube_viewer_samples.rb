class CreateYoutubeViewerSamples < ActiveRecord::Migration[8.1]
  def change
    create_table :youtube_viewer_samples, id: :uuid do |t|
      t.references :live_stream,
                   null:        false,
                   type:        :uuid,
                   foreign_key: { to_table: :youtube_live_streams }
      t.integer :concurrent_viewers, null: false
      t.datetime :captured_at, null: false

      t.timestamps
    end

    add_index :youtube_viewer_samples, [:live_stream_id, :captured_at]
  end
end
