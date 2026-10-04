# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Api::V1::Youtube::LiveStreams::ChatMessages", type: :request do
  let(:user) { create(:user) }
  let(:headers) { auth_headers_for(user) }
  let(:live_stream) { create(:youtube_live_stream, user: user) }

  describe "GET /api/v1/youtube/live_streams/:live_stream_id/chat_messages" do
    it "returns the newest messages first" do
      older = create(:youtube_chat_message, live_stream: live_stream, published_at: 10.minutes.ago)
      newer = create(:youtube_chat_message, live_stream: live_stream, published_at: 1.minute.ago)

      get "/api/v1/youtube/live_streams/#{live_stream.id}/chat_messages", headers: headers

      expect(response).to have_http_status(:ok)
      expect(response.parsed_body["data"].map { |row| row["id"] }).to eq([newer.id, older.id])
    end

    it "exposes the author of each message" do
      create(:youtube_chat_message,
             live_stream:       live_stream,
             author_channel_id: "UC_ana",
             author_name:       "Ana",
             author_is_sponsor: true)

      get "/api/v1/youtube/live_streams/#{live_stream.id}/chat_messages", headers: headers

      expect(response.parsed_body["data"].first["author"]).to include(
        "channelId" => "UC_ana",
        "name"      => "Ana",
        "isSponsor" => true
      )
    end

    it "filters by author" do
      create(:youtube_chat_message, live_stream: live_stream, author_channel_id: "UC_ana")
      create(:youtube_chat_message, live_stream: live_stream, author_channel_id: "UC_bia")

      get "/api/v1/youtube/live_streams/#{live_stream.id}/chat_messages",
          params:  { author_channel_id: "UC_ana" },
          headers: headers

      expect(response.parsed_body["data"].size).to eq(1)
      expect(response.parsed_body["data"].first["author"]["channelId"]).to eq("UC_ana")
    end

    it "filters paid messages only" do
      create(:youtube_chat_message, live_stream: live_stream)
      paid = create(:youtube_chat_message, :super_chat, live_stream: live_stream)

      get "/api/v1/youtube/live_streams/#{live_stream.id}/chat_messages",
          params:  { paid_only: "true" },
          headers: headers

      expect(response.parsed_body["data"].map { |row| row["id"] }).to eq([paid.id])
    end

    it "paginates the result" do
      create_list(:youtube_chat_message, 3, live_stream: live_stream)

      get "/api/v1/youtube/live_streams/#{live_stream.id}/chat_messages",
          params:  { page: 2, perPage: 2 },
          headers: headers

      expect(response.parsed_body["data"].size).to eq(1)
      expect(response.parsed_body["pagination"]).to include("currentPage" => 2, "totalCount" => 3)
    end

    it "does not expose messages of another user stream" do
      other = create(:youtube_live_stream)
      create(:youtube_chat_message, live_stream: other)

      get "/api/v1/youtube/live_streams/#{other.id}/chat_messages", headers: headers

      expect(response).to have_http_status(:not_found)
    end
  end
end
