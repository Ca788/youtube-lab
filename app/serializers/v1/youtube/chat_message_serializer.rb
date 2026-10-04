# frozen_string_literal: true

class V1::Youtube::ChatMessageSerializer < Blueprinter::Base
  identifier :id

  view :default do
    fields :message_type, :text, :published_at

    field :author do |message|
      {
        channelId:   message.author_channel_id,
        name:        message.author_name,
        imageUrl:    message.author_image_url,
        isOwner:     message.author_is_owner,
        isModerator: message.author_is_moderator,
        isSponsor:   message.author_is_sponsor,
        isVerified:  message.author_is_verified
      }
    end
  end

  view :extended do
    include_view :default

    fields :external_id, :currency, :created_at

    field(:amount) { |message| message.amount }
  end
end
