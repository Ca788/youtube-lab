# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Api::V1::Sessions", type: :request do
  let!(:user) { create(:user, email: "ana@example.com", password: "password123") }

  describe "POST /api/v1/login" do
    it "returns a bearer token for valid credentials" do
      post "/api/v1/login", params: { user: { email: "ana@example.com", password: "password123" } }

      expect(response).to have_http_status(:ok)
      expect(response.headers["Authorization"]).to start_with("Bearer ")
      expect(response.parsed_body["data"]["user"]["email"]).to eq("ana@example.com")
    end

    it "rejects invalid credentials" do
      post "/api/v1/login", params: { user: { email: "ana@example.com", password: "wrong" } }

      expect(response).to have_http_status(:unauthorized)
    end
  end

  describe "DELETE /api/v1/logout" do
    it "revokes the token" do
      post "/api/v1/login", params: { user: { email: "ana@example.com", password: "password123" } }
      token = response.headers["Authorization"]

      delete "/api/v1/logout", headers: { "Authorization" => token }
      expect(response).to have_http_status(:ok)

      get "/api/v1/youtube/live_streams", headers: { "Authorization" => token }
      expect(response).to have_http_status(:unauthorized)
    end
  end
end
