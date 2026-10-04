# frozen_string_literal: true

module YoutubeApi
  class VideoSnapshot
    ATTRIBUTE_KEYS = %i[
      video_id
      title
      channel_id
      channel_title
      status
      live_chat_id
      scheduled_start_at
      actual_start_at
      actual_end_at
      concurrent_viewers
      total_view_count
      like_count
    ].freeze

    attr_reader(*ATTRIBUTE_KEYS)

    def initialize(**attributes)
      ATTRIBUTE_KEYS.each { |key| instance_variable_set("@#{key}", attributes[key]) }
    end

    # @param [Hash] item
    # @return [YoutubeApi::VideoSnapshot]
    def self.from_api(item)
      snippet = item["snippet"].to_h
      details = item["liveStreamingDetails"].to_h
      stats   = item["statistics"].to_h

      new(
        video_id:           item["id"],
        title:              snippet["title"],
        channel_id:         snippet["channelId"],
        channel_title:      snippet["channelTitle"],
        status:             derive_status(snippet, details),
        live_chat_id:       details["activeLiveChatId"],
        scheduled_start_at: parse_time(details["scheduledStartTime"]),
        actual_start_at:    parse_time(details["actualStartTime"]),
        actual_end_at:      parse_time(details["actualEndTime"]),
        concurrent_viewers: details["concurrentViewers"]&.to_i,
        total_view_count:   stats["viewCount"]&.to_i,
        like_count:         stats["likeCount"]&.to_i
      )
    end

    # @param [Hash] snippet
    # @param [Hash] details
    # @return [String]
    def self.derive_status(snippet, details)
      return Youtube::LiveStream::STATUSES[:completed] if details["actualEndTime"].present?

      broadcast = snippet["liveBroadcastContent"].to_s
      return broadcast if Youtube::LiveStream::STATUSES.value?(broadcast)

      Youtube::LiveStream::STATUSES[:none]
    end

    # @param [String, nil] value
    # @return [ActiveSupport::TimeWithZone, nil]
    def self.parse_time(value)
      value.present? ? Time.zone.parse(value) : nil
    end

    private_class_method :derive_status, :parse_time

    # @return [Boolean]
    def live?
      status == Youtube::LiveStream::STATUSES[:live]
    end

    # @return [Hash]
    def to_attributes
      {
        title:              title,
        channel_id:         channel_id,
        channel_title:      channel_title,
        status:             status,
        live_chat_id:       live_chat_id,
        scheduled_start_at: scheduled_start_at,
        actual_start_at:    actual_start_at,
        actual_end_at:      actual_end_at,
        concurrent_viewers: concurrent_viewers,
        total_view_count:   total_view_count,
        like_count:         like_count
      }.compact
    end
  end
end
