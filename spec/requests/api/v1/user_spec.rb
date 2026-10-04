# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Api::V1::User", type: :request do
  describe "POST /api/v1/user" do
    it "creates a user and returns a bearer token" do
      post "/api/v1/user", params: {
        user: {
          name:                  "Ana",
          email:                 "ana@example.com",
          password:              "password123",
          password_confirmation: "password123"
        }
      }

      expect(response).to have_http_status(:created)
      expect(response.headers["Authorization"]).to start_with("Bearer ")
      expect(response.parsed_body["data"]["user"]).to include("name" => "Ana", "email" => "ana@example.com")
    end

    it "rejects a mismatched password confirmation" do
      post "/api/v1/user", params: {
        user: {
          name:                  "Ana",
          email:                 "ana@example.com",
          password:              "password123",
          password_confirmation: "nope"
        }
      }

      expect(response).to have_http_status(:unprocessable_content)
      expect(response.parsed_body["success"]).to be(false)
    end

    it "rejects a duplicated email" do
      create(:user, email: "ana@example.com")

      post "/api/v1/user", params: {
        user: {
          name:                  "Ana",
          email:                 "ana@example.com",
          password:              "password123",
          password_confirmation: "password123"
        }
      }

      expect(response).to have_http_status(:unprocessable_content)
    end
  end

  describe "GET /api/v1/user" do
    it "returns the authenticated user" do
      user = create(:user)

      get "/api/v1/user", headers: auth_headers_for(user)

      expect(response).to have_http_status(:ok)
      expect(response.parsed_body["data"]["user"]["id"]).to eq(user.id)
    end

    it "rejects an unauthenticated request" do
      get "/api/v1/user"

      expect(response).to have_http_status(:unauthorized)
    end
  end
end
