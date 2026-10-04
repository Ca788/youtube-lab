# frozen_string_literal: true

module YoutubeApi
  class ChatMessageData
    ATTRIBUTE_KEYS = %i[
      external_id
      message_type
      text
      published_at
      author_channel_id
      author_name
      author_image_url
      author_is_owner
      author_is_moderator
      author_is_sponsor
      author_is_verified
      amount_micros
      currency
    ].freeze

    attr_reader(*ATTRIBUTE_KEYS)

    def initialize(**attributes)
      ATTRIBUTE_KEYS.each { |key| instance_variable_set("@#{key}", attributes[key]) }
    end

    # @param [Hash] item
    # @return [YoutubeApi::ChatMessageData]
    def self.from_api(item)
      snippet = item["snippet"].to_h
      author  = item["authorDetails"].to_h
      paid    = snippet["superChatDetails"].presence || snippet["superStickerDetails"].presence || {}

      new(
        external_id:         item["id"],
        message_type:        snippet["type"].presence || Youtube::ChatMessage::MESSAGE_TYPES[:text],
        text:                snippet["displayMessage"],
        published_at:        snippet["publishedAt"].presence && Time.zone.parse(snippet["publishedAt"]),
        author_channel_id:   author["channelId"],
        author_name:         author["displayName"],
        author_image_url:    author["profileImageUrl"],
        author_is_owner:     author["isChatOwner"].present?,
        author_is_moderator: author["isChatModerator"].present?,
        author_is_sponsor:   author["isChatSponsor"].present?,
        author_is_verified:  author["isVerified"].present?,
        amount_micros:       paid["amountMicros"]&.to_i,
        currency:            paid["currency"]
      )
    end

    # @return [Hash]
    def to_attributes
      {
        external_id:         external_id,
        message_type:        message_type,
        text:                text,
        published_at:        published_at,
        author_channel_id:   author_channel_id,
        author_name:         author_name,
        author_image_url:    author_image_url,
        author_is_owner:     author_is_owner,
        author_is_moderator: author_is_moderator,
        author_is_sponsor:   author_is_sponsor,
        author_is_verified:  author_is_verified,
        amount_micros:       amount_micros,
        currency:            currency
      }
    end
  end
end
