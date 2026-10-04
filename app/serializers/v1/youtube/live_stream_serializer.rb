# frozen_string_literal: true

class V1::Youtube::LiveStreamSerializer < Blueprinter::Base
  identifier :id

  view :default do
    fields :video_id, :title, :channel_title, :status, :concurrent_viewers,
           :actual_start_at, :tracking

    field(:chat_available) { |live_stream| live_stream.chat_pollable? }
  end

  view :extended do
    include_view :default

    fields :channel_id, :scheduled_start_at, :actual_end_at, :total_view_count,
           :like_count, :last_polled_at, :created_at, :updated_at

    field(:watch_url) { |live_stream| "https://www.youtube.com/watch?v=#{live_stream.video_id}" }
  end
end
