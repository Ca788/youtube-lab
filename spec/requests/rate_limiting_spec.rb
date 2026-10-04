# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Rate limiting", type: :request do
  let(:user) { create(:user) }

  before do
    Rack::Attack.enabled = true
    Rack::Attack.cache.store.clear
  end

  after do
    Rack::Attack.enabled = false
    Rack::Attack.cache.store.clear
  end

  it "throttles repeated failed logins for the same email" do
    6.times do
      post "/api/v1/login",
           params:  { user: { email: user.email, password: "wrong" } }.to_json,
           headers: { "CONTENT_TYPE" => "application/json" }
    end

    expect(response).to have_http_status(:too_many_requests)
    expect(response.parsed_body["errorCode"]).to eq(ErrorMapper.too_many_requests.code)
    expect(response.headers["Retry-After"]).to be_present
  end

  it "throttles the writes that consume YouTube quota" do
    headers = auth_headers_for(user)

    21.times do
      post "/api/v1/youtube/live_streams",
           params:  { live_stream: { url: "nope" } },
           headers: headers
    end

    expect(response).to have_http_status(:too_many_requests)
  end

  it "keeps reads out of the quota throttle" do
    headers = auth_headers_for(user)

    21.times do
      post "/api/v1/youtube/live_streams",
           params:  { live_stream: { url: "nope" } },
           headers: headers
    end

    get "/api/v1/youtube/live_streams", headers: headers

    expect(response).to have_http_status(:ok)
  end

  it "leaves the health check unthrottled" do
    get "/health"

    expect(response).to have_http_status(:ok)
  end
end
