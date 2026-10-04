FactoryBot.define do
  factory :youtube_live_stream, class: "Youtube::LiveStream" do
    user
    sequence(:video_id) { |n| "vid#{n.to_s.rjust(8, '0')}" }
    channel_id { "UC#{SecureRandom.alphanumeric(22)}" }
    channel_title { Faker::Company.name }
    title { Faker::Lorem.sentence }
    status { Youtube::LiveStream::STATUSES[:live] }
    live_chat_id { SecureRandom.alphanumeric(24) }
    actual_start_at { 30.minutes.ago }
    concurrent_viewers { rand(1..5_000) }
    total_view_count { rand(1..50_000) }
    like_count { rand(1..1_000) }
    tracking { true }

    trait :completed do
      status { Youtube::LiveStream::STATUSES[:completed] }
      actual_end_at { 5.minutes.ago }
      live_chat_id { nil }
      tracking { false }
    end
  end
end
