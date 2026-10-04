# frozen_string_literal: true

require "json"
require "net/http"
require "uri"

module YoutubeApi
  class Client
    API_HOST = "https://www.googleapis.com"

    VIDEO_FIELDS = "items(" \
                   "id," \
                   "snippet(title,channelId,channelTitle,liveBroadcastContent)," \
                   "liveStreamingDetails(scheduledStartTime,actualStartTime,actualEndTime," \
                   "concurrentViewers,activeLiveChatId)," \
                   "statistics(viewCount,likeCount)" \
                   ")"

    CHAT_FIELDS = "nextPageToken,pollingIntervalMillis,offlineAt," \
                  "items(id," \
                  "snippet(type,publishedAt,displayMessage," \
                  "superChatDetails(amountMicros,currency)," \
                  "superStickerDetails(amountMicros,currency))," \
                  "authorDetails(channelId,displayName,profileImageUrl,isVerified," \
                  "isChatOwner,isChatSponsor,isChatModerator))"

    CHAT_MAX_RESULTS = 200
    OPEN_TIMEOUT = 5
    READ_TIMEOUT = 10

    Credentials = Struct.new(:api_key, keyword_init: true)

    # @param [YoutubeApi::Client::Credentials] credentials
    def initialize(credentials:)
      @api_key = credentials.api_key
    end

    # @param [String] video_id
    # @return [YoutubeApi::VideoSnapshot, nil]
    def fetch_video(video_id:)
      payload = get(
        "youtube/v3/videos",
        part:   "snippet,liveStreamingDetails,statistics",
        id:     video_id,
        fields: VIDEO_FIELDS
      )

      item = payload["items"].to_a.first
      item.present? ? VideoSnapshot.from_api(item) : nil
    end

    # @param [String] live_chat_id
    # @param [String, nil] page_token
    # @param [Integer] max_results
    # @return [YoutubeApi::ChatPage]
    def fetch_chat_page(live_chat_id:, page_token: nil, max_results: CHAT_MAX_RESULTS)
      payload = get(
        "youtube/v3/liveChat/messages",
        liveChatId: live_chat_id,
        part:       "snippet,authorDetails",
        maxResults: max_results,
        pageToken:  page_token,
        fields:     CHAT_FIELDS
      )

      ChatPage.from_api(payload)
    end

    private

    def get(path, **query)
      uri = URI("#{API_HOST}/#{path}")
      uri.query = URI.encode_www_form(query.compact.merge(key: @api_key))

      request = Net::HTTP::Get.new(uri)
      request["Accept"] = "application/json"

      parse_response(perform(uri, request))
    end

    def perform(uri, request)
      Net::HTTP.start(
        uri.host,
        uri.port,
        use_ssl:      true,
        open_timeout: OPEN_TIMEOUT,
        read_timeout: READ_TIMEOUT
      ) { |http| http.request(request) }
    end

    def parse_response(response)
      body = response.body.to_s
      json = body.present? ? JSON.parse(body) : {}

      unless response.is_a?(Net::HTTPSuccess)
        error   = json["error"].to_h
        reason  = error["errors"].to_a.first&.dig("reason")
        message = error["message"].presence || body.presence || response.code

        raise RequestError.new(
          "YouTube API #{response.code}: #{message}",
          status: response.code,
          reason: reason
        )
      end

      json
    end
  end
end
