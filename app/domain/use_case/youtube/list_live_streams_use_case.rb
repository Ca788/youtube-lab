# frozen_string_literal: true

class UseCase::Youtube::ListLiveStreamsUseCase
  # @param [User] user
  # @param [String, nil] status
  # @param [Boolean, nil] tracking
  # @return [ActiveRecord::Relation<Youtube::LiveStream>]
  def call(user:, status: nil, tracking: nil)
    relation = user.live_streams.by_status(status)
    relation = relation.where(tracking: tracking) unless tracking.nil?

    relation.order(actual_start_at: :desc, created_at: :desc)
  end
end
