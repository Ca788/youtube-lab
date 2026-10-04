# frozen_string_literal: true

class UseCase::Youtube::TrackLiveStreamUseCase
  # @param [UseCase::Youtube::SyncLiveStreamUseCase] sync_use_case
  # @param [UseCase::Youtube::PollChatMessagesUseCase] poll_use_case
  def initialize(
    sync_use_case: UseCase::Youtube::SyncLiveStreamUseCase.new,
    poll_use_case: UseCase::Youtube::PollChatMessagesUseCase.new
  )
    @sync_use_case = sync_use_case
    @poll_use_case = poll_use_case
  end

  # @param [User] user
  # @param [String] url
  # @return [Youtube::LiveStream]
  def call(user:, url:)
    video_id = Support::YoutubeVideoId.extract!(url)

    live_stream = user.live_streams.find_or_initialize_by(video_id: video_id)
    live_stream.tracking = true
    live_stream.save!

    live_stream = @sync_use_case.call(live_stream: live_stream)
    @poll_use_case.call(live_stream: live_stream)
    live_stream
  end
end
