# frozen_string_literal: true

require "rails_helper"

RSpec.describe Youtube::EnqueuePollingJob, type: :job do
  it "enqueues one polling job per tracked and unfinished stream" do
    tracked = create(:youtube_live_stream, tracking: true)
    create(:youtube_live_stream, tracking: false)
    create(:youtube_live_stream, :completed, tracking: true)

    expect { described_class.perform_now }
      .to have_enqueued_job(Youtube::PollLiveStreamJob).with(tracked.id).once
  end
end
