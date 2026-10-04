# frozen_string_literal: true

class UseCase::Youtube::ListViewerSamplesUseCase
  # @param [User] user
  # @param [String] live_stream_id
  # @param [String, Time, nil] from
  # @param [String, Time, nil] to
  # @return [ActiveRecord::Relation<Youtube::ViewerSample>]
  def call(user:, live_stream_id:, from: nil, to: nil)
    live_stream = user.live_streams.find(live_stream_id)

    live_stream.viewer_samples
               .captured_between(parse_time(from), parse_time(to))
               .order(captured_at: :desc)
  end

  private

  def parse_time(value)
    return nil if value.blank?
    return value if value.is_a?(Time) || value.is_a?(ActiveSupport::TimeWithZone)

    Time.zone.parse(value.to_s) || raise(ArgumentError, "#{value.inspect} is not a valid timestamp")
  end
end
