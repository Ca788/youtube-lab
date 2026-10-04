# frozen_string_literal: true

# == Schema Information
#
# Table name: youtube_chat_messages
#
#  id                  :uuid             not null, primary key
#  amount_micros       :bigint
#  author_image_url    :string
#  author_is_moderator :boolean          default(FALSE), not null
#  author_is_owner     :boolean          default(FALSE), not null
#  author_is_sponsor   :boolean          default(FALSE), not null
#  author_is_verified  :boolean          default(FALSE), not null
#  author_name         :string
#  currency            :string
#  message_type        :string           default("textMessageEvent"), not null
#  published_at        :datetime         not null
#  text                :text
#  created_at          :datetime         not null
#  updated_at          :datetime         not null
#  author_channel_id   :string
#  external_id         :string           not null
#  live_stream_id      :uuid             not null
#
# Indexes
#
#  idx_on_live_stream_id_author_channel_id_9fdddb064b              (live_stream_id,author_channel_id)
#  index_youtube_chat_messages_on_live_stream_id                   (live_stream_id)
#  index_youtube_chat_messages_on_live_stream_id_and_external_id   (live_stream_id,external_id) UNIQUE
#  index_youtube_chat_messages_on_live_stream_id_and_published_at  (live_stream_id,published_at)
#
# Foreign Keys
#
#  fk_rails_...  (live_stream_id => youtube_live_streams.id)
#
module Youtube
  class ChatMessage < ApplicationRecord
    MESSAGE_TYPES = {
      text:             "textMessageEvent",
      super_chat:       "superChatEvent",
      super_sticker:    "superStickerEvent",
      new_sponsor:      "newSponsorEvent",
      member_milestone: "memberMilestoneChatEvent",
      membership_gift:  "membershipGiftingEvent",
      gift_redemption:  "giftMembershipReceivedEvent",
      message_deleted:  "messageDeletedEvent",
      chat_ended:       "chatEndedEvent",
      sponsor_only:     "sponsorOnlyModeEndedEvent"
    }.freeze

    belongs_to :live_stream, class_name: "Youtube::LiveStream"

    validates :external_id, presence: true, uniqueness: { scope: :live_stream_id }
    validates :message_type, presence: true
    validates :published_at, presence: true

    scope :by_type,   ->(type) { where(message_type: type) if type.present? }
    scope :by_author, ->(channel_id) { where(author_channel_id: channel_id) if channel_id.present? }
    scope :paid,      -> { where.not(amount_micros: nil) }

    # @return [BigDecimal, nil]
    def amount
      return nil if amount_micros.blank?

      (amount_micros.to_d / 1_000_000).round(2)
    end
  end
end
