# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Api::V1::Youtube::LiveStreams::ViewerSamples", type: :request do
  let(:user) { create(:user) }
  let(:headers) { auth_headers_for(user) }
  let(:live_stream) { create(:youtube_live_stream, user: user) }

  describe "GET /api/v1/youtube/live_streams/:live_stream_id/viewer_samples" do
    it "returns the viewer history newest first" do
      older = create(:youtube_viewer_sample, live_stream: live_stream, captured_at: 20.minutes.ago)
      newer = create(:youtube_viewer_sample, live_stream: live_stream, captured_at: 1.minute.ago)

      get "/api/v1/youtube/live_streams/#{live_stream.id}/viewer_samples", headers: headers

      expect(response).to have_http_status(:ok)
      expect(response.parsed_body["data"].map { |row| row["id"] }).to eq([newer.id, older.id])
    end

    it "filters by capture window" do
      create(:youtube_viewer_sample, live_stream: live_stream, captured_at: 3.hours.ago)
      recent = create(:youtube_viewer_sample, live_stream: live_stream, captured_at: 5.minutes.ago)

      get "/api/v1/youtube/live_streams/#{live_stream.id}/viewer_samples",
          params:  { from: 1.hour.ago.iso8601 },
          headers: headers

      expect(response.parsed_body["data"].map { |row| row["id"] }).to eq([recent.id])
    end

    it "rejects an invalid timestamp" do
      get "/api/v1/youtube/live_streams/#{live_stream.id}/viewer_samples",
          params:  { from: "ontem" },
          headers: headers

      expect(response).to have_http_status(:unprocessable_content)
    end

    it "paginates the result" do
      create_list(:youtube_viewer_sample, 3, live_stream: live_stream)

      get "/api/v1/youtube/live_streams/#{live_stream.id}/viewer_samples",
          params:  { page: 2, perPage: 2 },
          headers: headers

      expect(response.parsed_body["data"].size).to eq(1)
      expect(response.parsed_body["pagination"]).to include("currentPage" => 2, "totalCount" => 3)
    end

    it "does not expose samples of another user stream" do
      other = create(:youtube_live_stream)

      get "/api/v1/youtube/live_streams/#{other.id}/viewer_samples", headers: headers

      expect(response).to have_http_status(:not_found)
    end
  end
end
