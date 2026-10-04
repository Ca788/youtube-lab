# frozen_string_literal: true

class V1::Youtube::ChatParticipantSerializer < Blueprinter::Base
  identifier :author_channel_id

  view :default do
    fields :author_name, :author_image_url, :messages_count,
           :first_message_at, :last_message_at

    field(:is_owner)     { |row| row.is_owner }
    field(:is_moderator) { |row| row.is_moderator }
    field(:is_sponsor)   { |row| row.is_sponsor }
  end

  view :extended do
    include_view :default

    field(:paid_amount) { |row| (row.paid_amount_micros.to_d / 1_000_000).round(2) }
  end
end
