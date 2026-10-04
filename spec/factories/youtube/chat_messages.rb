FactoryBot.define do
  factory :youtube_chat_message, class: "Youtube::ChatMessage" do
    live_stream factory: :youtube_live_stream
    sequence(:external_id) { |n| "chat-message-#{n}" }
    message_type { Youtube::ChatMessage::MESSAGE_TYPES[:text] }
    text { Faker::Lorem.sentence }
    published_at { Time.current }
    author_channel_id { "UC#{SecureRandom.alphanumeric(22)}" }
    author_name { Faker::Name.first_name }
    author_image_url { Faker::Internet.url }

    trait :super_chat do
      message_type { Youtube::ChatMessage::MESSAGE_TYPES[:super_chat] }
      amount_micros { 5_000_000 }
      currency { "BRL" }
    end
  end
end
