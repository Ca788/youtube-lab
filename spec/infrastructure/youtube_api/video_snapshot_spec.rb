# frozen_string_literal: true

require "rails_helper"

RSpec.describe YoutubeApi::VideoSnapshot do
  describe ".from_api" do
    subject(:snapshot) { described_class.from_api(item) }

    let(:item) do
      {
        "id" => "dQw4w9WgXcQ",
        "snippet" => {
          "title" => "Live de teste",
          "channelId" => "UC_canal",
          "channelTitle" => "Canal de Teste",
          "liveBroadcastContent" => "live",
          "categoryId" => "25",
          "thumbnails" => { "medium" => { "url" => "https://i.ytimg.com/vi/dQw4w9WgXcQ/mqdefault.jpg" } }
        },
        "liveStreamingDetails" => {
          "actualStartTime" => "2026-10-03T21:00:00Z",
          "concurrentViewers" => "1234",
          "activeLiveChatId" => "chat-abc"
        },
        "statistics" => { "viewCount" => "5000", "likeCount" => "321" }
      }
    end

    it "maps the live payload" do
      expect(snapshot.video_id).to eq("dQw4w9WgXcQ")
      expect(snapshot.title).to eq("Live de teste")
      expect(snapshot.channel_title).to eq("Canal de Teste")
      expect(snapshot.status).to eq("live")
      expect(snapshot.live_chat_id).to eq("chat-abc")
      expect(snapshot.concurrent_viewers).to eq(1234)
      expect(snapshot.total_view_count).to eq(5000)
      expect(snapshot.like_count).to eq(321)
      expect(snapshot.thumbnail_url).to eq("https://i.ytimg.com/vi/dQw4w9WgXcQ/mqdefault.jpg")
      expect(snapshot.category_id).to eq("25")
      expect(snapshot.watch_url).to eq("https://www.youtube.com/watch?v=dQw4w9WgXcQ")
      expect(snapshot).to be_live
    end

    context "when the broadcast already ended" do
      before do
        item["snippet"]["liveBroadcastContent"] = "none"
        item["liveStreamingDetails"]["actualEndTime"] = "2026-10-03T23:00:00Z"
      end

      it "reports the completed status" do
        expect(snapshot.status).to eq("completed")
        expect(snapshot).not_to be_live
      end
    end

    context "when the video was never a broadcast" do
      let(:item) do
        {
          "id" => "dQw4w9WgXcQ",
          "snippet" => { "title" => "Video comum", "liveBroadcastContent" => "none" },
          "statistics" => { "viewCount" => "10" }
        }
      end

      it "reports no live data" do
        expect(snapshot.status).to eq("none")
        expect(snapshot.concurrent_viewers).to be_nil
        expect(snapshot.live_chat_id).to be_nil
      end
    end
  end
end
