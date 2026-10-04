# frozen_string_literal: true

class UseCase::Youtube::SyncLiveStreamUseCase
  # @param [YoutubeApi::Client] client
  def initialize(client: YoutubeApi::ClientFactory.build)
    @client = client
  end

  # @param [Youtube::LiveStream] live_stream
  # @return [Youtube::LiveStream]
  def call(live_stream:)
    snapshot = @client.fetch_video(video_id: live_stream.video_id)

    if snapshot.nil?
      raise ActiveRecord::RecordNotFound.new(
        "Video #{live_stream.video_id} is unavailable on YouTube",
        "Youtube::LiveStream"
      )
    end

    live_stream.transaction do
      live_stream.update!(snapshot.to_attributes.merge(last_polled_at: Time.current))
      append_viewer_sample(live_stream, snapshot)
    end

    live_stream
  end

  private

  def append_viewer_sample(live_stream, snapshot)
    return if snapshot.concurrent_viewers.blank?

    live_stream.viewer_samples.create!(
      concurrent_viewers: snapshot.concurrent_viewers,
      captured_at:        Time.current
    )
  end
end
