# frozen_string_literal: true

class Youtube::PollLiveStreamJob < ApplicationJob
  queue_as :youtube

  # @param [String] live_stream_id
  def perform(live_stream_id)
    live_stream = Youtube::LiveStream.find_by(id: live_stream_id)
    return if live_stream.nil? || !live_stream.tracking?

    UseCase::Youtube::SyncLiveStreamUseCase.new.call(live_stream: live_stream)

    return unless live_stream.chat_pollable?

    UseCase::Youtube::PollChatMessagesUseCase.new.call(live_stream: live_stream)
  rescue YoutubeApi::RequestError => e
    raise unless e.quota_exceeded? || e.chat_unavailable?

    Rails.logger.warn("[youtube] polling stopped for #{live_stream_id}: #{e.message}")
    live_stream&.update(tracking: false) if e.chat_unavailable?
  end
end
