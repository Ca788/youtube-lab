# frozen_string_literal: true

class Youtube::EnqueuePollingJob < ApplicationJob
  queue_as :youtube

  def perform
    Youtube::LiveStream
      .tracking
      .where.not(status: Youtube::LiveStream::STATUSES[:completed])
      .pluck(:id)
      .each { |id| Youtube::PollLiveStreamJob.perform_later(id) }
  end
end
