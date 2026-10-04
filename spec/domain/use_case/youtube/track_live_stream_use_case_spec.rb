# frozen_string_literal: true

require "rails_helper"

RSpec.describe UseCase::Youtube::TrackLiveStreamUseCase do
  subject(:use_case) do
    described_class.new(sync_use_case: sync_use_case, poll_use_case: poll_use_case)
  end

  let(:user) { create(:user) }
  let(:sync_use_case) { instance_double(UseCase::Youtube::SyncLiveStreamUseCase) }
  let(:poll_use_case) { instance_double(UseCase::Youtube::PollChatMessagesUseCase) }

  before do
    allow(sync_use_case).to receive(:call) { |live_stream:| live_stream }
    allow(poll_use_case).to receive(:call)
  end

  it "creates a tracked stream from a watch url" do
    live_stream = use_case.call(user: user, url: "https://www.youtube.com/watch?v=dQw4w9WgXcQ")

    expect(live_stream).to be_persisted
    expect(live_stream.video_id).to eq("dQw4w9WgXcQ")
    expect(live_stream.user).to eq(user)
    expect(live_stream.tracking).to be(true)
  end

  it "reuses the existing stream for the same video" do
    existing = create(:youtube_live_stream, user: user, video_id: "dQw4w9WgXcQ", tracking: false)

    live_stream = use_case.call(user: user, url: "dQw4w9WgXcQ")

    expect(live_stream.id).to eq(existing.id)
    expect(existing.reload.tracking).to be(true)
    expect(user.live_streams.count).to eq(1)
  end

  it "keeps streams of different users apart" do
    create(:youtube_live_stream, video_id: "dQw4w9WgXcQ")

    live_stream = use_case.call(user: user, url: "dQw4w9WgXcQ")

    expect(live_stream.user).to eq(user)
    expect(Youtube::LiveStream.where(video_id: "dQw4w9WgXcQ").count).to eq(2)
  end

  it "rejects input without a video id" do
    expect { use_case.call(user: user, url: "nope") }.to raise_error(ArgumentError)
  end
end
