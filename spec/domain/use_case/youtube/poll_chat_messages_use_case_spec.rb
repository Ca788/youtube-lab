# frozen_string_literal: true

require "rails_helper"

RSpec.describe UseCase::Youtube::PollChatMessagesUseCase do
  subject(:use_case) { described_class.new(client: client) }

  let(:live_stream) { create(:youtube_live_stream) }
  let(:client) { instance_double(YoutubeApi::Client) }

  let(:payload) do
    {
      "nextPageToken" => "next-token",
      "pollingIntervalMillis" => 3_000,
      "items" => [
        {
          "id" => "msg-1",
          "snippet" => {
            "type" => "textMessageEvent",
            "publishedAt" => "2026-10-03T22:00:00Z",
            "displayMessage" => "bom dia"
          },
          "authorDetails" => {
            "channelId" => "UC_ana",
            "displayName" => "Ana",
            "isChatModerator" => true
          }
        },
        {
          "id" => "msg-2",
          "snippet" => {
            "type" => "superChatEvent",
            "publishedAt" => "2026-10-03T22:01:00Z",
            "displayMessage" => "valeu!",
            "superChatDetails" => { "amountMicros" => "5000000", "currency" => "BRL" }
          },
          "authorDetails" => { "channelId" => "UC_bia", "displayName" => "Bia" }
        }
      ]
    }
  end

  before do
    allow(client).to receive(:fetch_chat_page).and_return(YoutubeApi::ChatPage.from_api(payload))
  end

  it "stores the page and advances the cursor" do
    use_case.call(live_stream: live_stream)

    expect(live_stream.chat_messages.count).to eq(2)
    expect(live_stream.reload.chat_next_page_token).to eq("next-token")
    expect(live_stream.last_polled_at).to be_present
  end

  it "maps author details and paid amounts" do
    use_case.call(live_stream: live_stream)

    text = live_stream.chat_messages.find_by(external_id: "msg-1")
    paid = live_stream.chat_messages.find_by(external_id: "msg-2")

    expect(text.text).to eq("bom dia")
    expect(text.author_name).to eq("Ana")
    expect(text.author_is_moderator).to be(true)
    expect(text.author_is_owner).to be(false)
    expect(paid.message_type).to eq("superChatEvent")
    expect(paid.amount).to eq(5.0)
    expect(paid.currency).to eq("BRL")
  end

  it "does not duplicate messages when the same page is read twice" do
    use_case.call(live_stream: live_stream)
    use_case.call(live_stream: live_stream)

    expect(live_stream.chat_messages.count).to eq(2)
  end

  it "resumes from the stored page token" do
    live_stream.update!(chat_next_page_token: "stored-token")

    use_case.call(live_stream: live_stream)

    expect(client).to have_received(:fetch_chat_page).with(
      live_chat_id: live_stream.live_chat_id,
      page_token:   "stored-token"
    )
  end

  it "skips a stream without an active chat" do
    completed = create(:youtube_live_stream, :completed)

    expect(use_case.call(live_stream: completed)).to be_nil
    expect(client).not_to have_received(:fetch_chat_page)
  end
end
