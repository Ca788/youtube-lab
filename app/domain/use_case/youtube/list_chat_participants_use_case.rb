# frozen_string_literal: true

class UseCase::Youtube::ListChatParticipantsUseCase
  ORDERS = {
    messages: "messages_count DESC",
    recent:   "last_message_at DESC",
    paid:     "paid_amount_micros DESC"
  }.freeze

  SELECT_FIELDS = [
    "author_channel_id",
    "MAX(author_name) AS author_name",
    "MAX(author_image_url) AS author_image_url",
    "COUNT(*) AS messages_count",
    "MIN(published_at) AS first_message_at",
    "MAX(published_at) AS last_message_at",
    "BOOL_OR(author_is_owner) AS is_owner",
    "BOOL_OR(author_is_moderator) AS is_moderator",
    "BOOL_OR(author_is_sponsor) AS is_sponsor",
    "COALESCE(SUM(amount_micros), 0) AS paid_amount_micros"
  ].freeze

  # @param [User] user
  # @param [String] live_stream_id
  # @param [String, Symbol, nil] order
  # @return [ActiveRecord::Relation<Youtube::ChatMessage>]
  def call(user:, live_stream_id:, order: nil)
    live_stream = user.live_streams.find(live_stream_id)

    live_stream.chat_messages
               .where.not(author_channel_id: nil)
               .group(:author_channel_id)
               .select(*SELECT_FIELDS)
               .order(Arel.sql(ORDERS.fetch(order.presence&.to_sym, ORDERS[:messages])))
  end
end
