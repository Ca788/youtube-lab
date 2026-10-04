# frozen_string_literal: true

class UseCase::Youtube::StopTrackingLiveStreamUseCase
  # @param [User] user
  # @param [String] id
  # @return [Youtube::LiveStream]
  def call(user:, id:)
    live_stream = user.live_streams.find(id)
    live_stream.update!(tracking: false)
    live_stream
  end
end
