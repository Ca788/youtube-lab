# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Api::V1::Youtube::LiveStreams", type: :request do
  let(:user) { create(:user) }
  let(:headers) { auth_headers_for(user) }
  let(:client) { instance_double(YoutubeApi::Client) }

  let(:video_payload) do
    {
      "id" => "dQw4w9WgXcQ",
      "snippet" => {
        "title" => "Live de teste",
        "channelId" => "UC_canal",
        "channelTitle" => "Canal de Teste",
        "liveBroadcastContent" => "live"
      },
      "liveStreamingDetails" => {
        "actualStartTime" => "2026-10-03T21:00:00Z",
        "concurrentViewers" => "1234",
        "activeLiveChatId" => "chat-abc"
      },
      "statistics" => { "viewCount" => "5000", "likeCount" => "321" }
    }
  end

  before do
    allow(YoutubeApi::ClientFactory).to receive(:build).and_return(client)
    allow(client).to receive(:fetch_video).and_return(YoutubeApi::VideoSnapshot.from_api(video_payload))
  end

  describe "GET /api/v1/youtube/live_streams" do
    it "rejects an unauthenticated request" do
      get "/api/v1/youtube/live_streams"

      expect(response).to have_http_status(:unauthorized)
    end

    it "returns only the streams of the current user" do
      mine = create(:youtube_live_stream, user: user)
      create(:youtube_live_stream)

      get "/api/v1/youtube/live_streams", headers: headers

      expect(response).to have_http_status(:ok)
      expect(response.parsed_body["success"]).to be(true)
      expect(response.parsed_body["data"].map { |stream| stream["id"] }).to eq([mine.id])
      expect(response.parsed_body["pagination"]["totalCount"]).to eq(1)
    end

    it "paginates the result" do
      create_list(:youtube_live_stream, 3, user: user)

      get "/api/v1/youtube/live_streams", params: { page: 2, perPage: 2 }, headers: headers

      expect(response.parsed_body["data"].size).to eq(1)
      expect(response.parsed_body["pagination"]).to include(
        "currentPage" => 2,
        "totalPages"  => 2,
        "totalCount"  => 3
      )
    end

    it "filters by status" do
      create(:youtube_live_stream, user: user)
      completed = create(:youtube_live_stream, :completed, user: user)

      get "/api/v1/youtube/live_streams", params: { status: "completed" }, headers: headers

      expect(response.parsed_body["data"].map { |stream| stream["id"] }).to eq([completed.id])
    end

    it "returns the compact view by default and the full view on demand" do
      create(:youtube_live_stream, user: user)

      get "/api/v1/youtube/live_streams", headers: headers
      expect(response.parsed_body["data"].first).not_to have_key("watch_url")

      get "/api/v1/youtube/live_streams", params: { view: "extended" }, headers: headers
      expect(response.parsed_body["data"].first).to have_key("watch_url")
    end
  end

  describe "conditional GET" do
    it "answers 304 while the collection is unchanged" do
      create(:youtube_live_stream, user: user)

      get "/api/v1/youtube/live_streams", headers: headers

      expect(response).to have_http_status(:ok)
      expect(response.etag).to be_present
      expect(response.headers["Cache-Control"]).to include("max-age=15", "private")

      get "/api/v1/youtube/live_streams", headers: headers.merge("If-None-Match" => response.etag)

      expect(response).to have_http_status(:not_modified)
      expect(response.body).to be_empty
    end

    it "answers a fresh payload once a stream is added" do
      create(:youtube_live_stream, user: user)
      get "/api/v1/youtube/live_streams", headers: headers
      etag = response.etag

      create(:youtube_live_stream, user: user)
      get "/api/v1/youtube/live_streams", headers: headers.merge("If-None-Match" => etag)

      expect(response).to have_http_status(:ok)
    end

    it "does not reuse the cache entry across serializer views" do
      create(:youtube_live_stream, user: user)
      get "/api/v1/youtube/live_streams", headers: headers
      etag = response.etag

      get "/api/v1/youtube/live_streams",
          params:  { view: "extended" },
          headers: headers.merge("If-None-Match" => etag)

      expect(response).to have_http_status(:ok)
    end

    it "answers 304 while a single stream is unchanged" do
      live_stream = create(:youtube_live_stream, user: user)

      get "/api/v1/youtube/live_streams/#{live_stream.id}", headers: headers
      expect(response).to have_http_status(:ok)

      get "/api/v1/youtube/live_streams/#{live_stream.id}",
          headers: headers.merge("If-None-Match" => response.etag)

      expect(response).to have_http_status(:not_modified)
    end

    it "answers a fresh payload after the stream is synced" do
      live_stream = create(:youtube_live_stream, user: user)
      get "/api/v1/youtube/live_streams/#{live_stream.id}", headers: headers
      etag = response.etag

      live_stream.update!(concurrent_viewers: 99)
      get "/api/v1/youtube/live_streams/#{live_stream.id}", headers: headers.merge("If-None-Match" => etag)

      expect(response).to have_http_status(:ok)
    end
  end

  describe "POST /api/v1/youtube/live_streams" do
    it "tracks a stream and records the first viewer sample" do
      post "/api/v1/youtube/live_streams",
           params:  { live_stream: { url: "https://www.youtube.com/watch?v=dQw4w9WgXcQ" } },
           headers: headers

      expect(response).to have_http_status(:created)
      expect(response.parsed_body["data"]).to include(
        "video_id"           => "dQw4w9WgXcQ",
        "title"              => "Live de teste",
        "status"             => "live",
        "concurrent_viewers" => 1234,
        "chat_available"     => true
      )

      live_stream = user.live_streams.sole
      expect(live_stream.viewer_samples.count).to eq(1)
      expect(live_stream.viewer_samples.sole.concurrent_viewers).to eq(1234)
    end

    it "rejects a url without a video id" do
      post "/api/v1/youtube/live_streams",
           params:  { live_stream: { url: "nope" } },
           headers: headers

      expect(response).to have_http_status(:unprocessable_content)
      expect(response.parsed_body["success"]).to be(false)
    end

    it "rejects a missing live_stream param" do
      post "/api/v1/youtube/live_streams", params: {}, headers: headers

      expect(response).to have_http_status(:bad_request)
    end

    it "reports an unavailable video" do
      allow(client).to receive(:fetch_video).and_return(nil)

      post "/api/v1/youtube/live_streams",
           params:  { live_stream: { url: "dQw4w9WgXcQ" } },
           headers: headers

      expect(response).to have_http_status(:not_found)
    end

    it "surfaces a quota error as too many requests" do
      allow(client).to receive(:fetch_video).and_raise(
        YoutubeApi::RequestError.new("quota", status: 403, reason: "quotaExceeded")
      )

      post "/api/v1/youtube/live_streams",
           params:  { live_stream: { url: "dQw4w9WgXcQ" } },
           headers: headers

      expect(response).to have_http_status(:too_many_requests)
    end
  end

  describe "POST /api/v1/youtube/live_streams/:id/sync" do
    it "refreshes the stored stream" do
      live_stream = create(:youtube_live_stream, user: user, concurrent_viewers: 1)

      post "/api/v1/youtube/live_streams/#{live_stream.id}/sync", headers: headers

      expect(response).to have_http_status(:ok)
      expect(live_stream.reload.concurrent_viewers).to eq(1234)
      expect(live_stream.viewer_samples.count).to eq(1)
    end

    it "does not touch a stream of another user" do
      other = create(:youtube_live_stream)

      post "/api/v1/youtube/live_streams/#{other.id}/sync", headers: headers

      expect(response).to have_http_status(:not_found)
    end
  end

  describe "DELETE /api/v1/youtube/live_streams/:id" do
    it "stops tracking but keeps the captured history" do
      live_stream = create(:youtube_live_stream, user: user)
      create(:youtube_chat_message, live_stream: live_stream)

      delete "/api/v1/youtube/live_streams/#{live_stream.id}", headers: headers

      expect(response).to have_http_status(:ok)
      expect(live_stream.reload.tracking).to be(false)
      expect(live_stream.chat_messages.count).to eq(1)
    end
  end
end
