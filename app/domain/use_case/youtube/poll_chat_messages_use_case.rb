# frozen_string_literal: true

class UseCase::Youtube::PollChatMessagesUseCase
  # @param [YoutubeApi::Client] client
  def initialize(client: YoutubeApi::ClientFactory.build)
    @client = client
  end

  # @param [Youtube::LiveStream] live_stream
  # @return [YoutubeApi::ChatPage, nil]
  def call(live_stream:)
    return nil unless live_stream.chat_pollable?

    page = @client.fetch_chat_page(
      live_chat_id: live_stream.live_chat_id,
      page_token:   live_stream.chat_next_page_token
    )

    persist(live_stream, page)
    page
  end

  private

  def persist(live_stream, page)
    rows = rows_for(live_stream, page.messages)

    live_stream.transaction do
      if rows.any?
        Youtube::ChatMessage.upsert_all(rows, unique_by: %i[live_stream_id external_id])
      end

      live_stream.update!(
        chat_next_page_token: page.next_page_token,
        last_polled_at:       Time.current
      )
    end
  end

  def rows_for(live_stream, messages)
    now = Time.current

    messages.filter_map do |message|
      next if message.external_id.blank? || message.published_at.blank?

      message.to_attributes.merge(
        live_stream_id: live_stream.id,
        created_at:     now,
        updated_at:     now
      )
    end
  end
end
