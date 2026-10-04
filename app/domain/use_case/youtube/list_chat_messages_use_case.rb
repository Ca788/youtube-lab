# frozen_string_literal: true

class UseCase::Youtube::ListChatMessagesUseCase
  # @param [User] user
  # @param [String] live_stream_id
  # @param [String, nil] message_type
  # @param [String, nil] author_channel_id
  # @param [Boolean] paid_only
  # @return [ActiveRecord::Relation<Youtube::ChatMessage>]
  def call(user:, live_stream_id:, message_type: nil, author_channel_id: nil, paid_only: false)
    live_stream = user.live_streams.find(live_stream_id)

    relation = live_stream.chat_messages
                          .by_type(message_type)
                          .by_author(author_channel_id)

    relation = relation.paid if paid_only

    relation.order(published_at: :desc)
  end
end
