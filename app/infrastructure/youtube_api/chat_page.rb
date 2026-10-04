# frozen_string_literal: true

module YoutubeApi
  class ChatPage
    attr_reader :messages, :next_page_token, :polling_interval_ms, :offline_at

    def initialize(messages:, next_page_token: nil, polling_interval_ms: nil, offline_at: nil)
      @messages = messages
      @next_page_token = next_page_token
      @polling_interval_ms = polling_interval_ms
      @offline_at = offline_at
    end

    # @param [Hash] payload
    # @return [YoutubeApi::ChatPage]
    def self.from_api(payload)
      new(
        messages:            payload["items"].to_a.map { |item| ChatMessageData.from_api(item) },
        next_page_token:     payload["nextPageToken"],
        polling_interval_ms: payload["pollingIntervalMillis"]&.to_i,
        offline_at:          payload["offlineAt"].presence && Time.zone.parse(payload["offlineAt"])
      )
    end

    # @return [Float]
    def polling_interval_seconds
      (polling_interval_ms || 5_000) / 1000.0
    end

    # @return [Boolean]
    def chat_offline?
      offline_at.present?
    end
  end
end
