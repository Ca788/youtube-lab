# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Api::V1::Youtube::LiveStreams::Participants", type: :request do
  let(:user) { create(:user) }
  let(:headers) { auth_headers_for(user) }
  let(:live_stream) { create(:youtube_live_stream, user: user) }

  describe "GET /api/v1/youtube/live_streams/:live_stream_id/participants" do
    it "groups chat authors ordered by message count" do
      create_list(:youtube_chat_message, 3,
                  live_stream:       live_stream,
                  author_channel_id: "UC_ana",
                  author_name:       "Ana")
      create(:youtube_chat_message,
             live_stream:         live_stream,
             author_channel_id:   "UC_bia",
             author_name:         "Bia",
             author_is_moderator: true)

      get "/api/v1/youtube/live_streams/#{live_stream.id}/participants", headers: headers

      expect(response).to have_http_status(:ok)

      participants = response.parsed_body["data"]
      expect(participants.map { |row| row["author_channel_id"] }).to eq(%w[UC_ana UC_bia])
      expect(participants.first).to include("author_name" => "Ana", "messages_count" => 3)
      expect(participants.second).to include("is_moderator" => true, "messages_count" => 1)
      expect(response.parsed_body["pagination"]["totalCount"]).to eq(2)
    end

    it "paginates over the grouped authors" do
      3.times do |index|
        create(:youtube_chat_message, live_stream: live_stream, author_channel_id: "UC_#{index}")
      end

      get "/api/v1/youtube/live_streams/#{live_stream.id}/participants",
          params:  { page: 2, perPage: 2 },
          headers: headers

      expect(response.parsed_body["data"].size).to eq(1)
      expect(response.parsed_body["pagination"]).to include(
        "currentPage" => 2,
        "totalPages"  => 2,
        "totalCount"  => 3
      )
    end

    it "sums paid amounts in the extended view" do
      create(:youtube_chat_message, :super_chat,
             live_stream:       live_stream,
             author_channel_id: "UC_ana")

      get "/api/v1/youtube/live_streams/#{live_stream.id}/participants",
          params:  { view: "extended" },
          headers: headers

      expect(response.parsed_body["data"].first["paid_amount"]).to eq("5.0")
    end

    it "orders by the most recent message" do
      create(:youtube_chat_message,
             live_stream:       live_stream,
             author_channel_id: "UC_ana",
             published_at:      2.hours.ago)
      create(:youtube_chat_message,
             live_stream:       live_stream,
             author_channel_id: "UC_bia",
             published_at:      1.minute.ago)

      get "/api/v1/youtube/live_streams/#{live_stream.id}/participants",
          params:  { order: "recent" },
          headers: headers

      expect(response.parsed_body["data"].map { |row| row["author_channel_id"] }).to eq(%w[UC_bia UC_ana])
    end

    it "ignores an unknown order instead of failing" do
      create(:youtube_chat_message, live_stream: live_stream)

      get "/api/v1/youtube/live_streams/#{live_stream.id}/participants",
          params:  { order: "drop table" },
          headers: headers

      expect(response).to have_http_status(:ok)
    end

    it "does not expose a stream of another user" do
      other = create(:youtube_live_stream)

      get "/api/v1/youtube/live_streams/#{other.id}/participants", headers: headers

      expect(response).to have_http_status(:not_found)
    end
  end
end
