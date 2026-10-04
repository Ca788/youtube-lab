FactoryBot.define do
  factory :youtube_viewer_sample, class: "Youtube::ViewerSample" do
    live_stream factory: :youtube_live_stream
    concurrent_viewers { rand(1..5_000) }
    captured_at { Time.current }
  end
end
