# frozen_string_literal: true

require "rails_helper"

RSpec.describe Support::YoutubeVideoId do
  describe ".extract" do
    it "accepts a bare video id" do
      expect(described_class.extract("dQw4w9WgXcQ")).to eq("dQw4w9WgXcQ")
    end

    it "accepts a watch url with extra params" do
      expect(described_class.extract("https://www.youtube.com/watch?v=dQw4w9WgXcQ&t=42s")).to eq("dQw4w9WgXcQ")
    end

    it "accepts a youtu.be short link" do
      expect(described_class.extract("https://youtu.be/dQw4w9WgXcQ")).to eq("dQw4w9WgXcQ")
    end

    it "accepts a live url" do
      expect(described_class.extract("https://www.youtube.com/live/dQw4w9WgXcQ")).to eq("dQw4w9WgXcQ")
    end

    it "accepts a url without scheme" do
      expect(described_class.extract("youtube.com/watch?v=dQw4w9WgXcQ")).to eq("dQw4w9WgXcQ")
    end

    it "returns nil when no id of the expected shape is present" do
      expect(described_class.extract("https://www.youtube.com/watch?v=short")).to be_nil
    end

    it "returns nil for blank input" do
      expect(described_class.extract(nil)).to be_nil
    end
  end

  describe ".extract!" do
    it "raises for input without a video id" do
      expect { described_class.extract!("nope") }.to raise_error(ArgumentError)
    end
  end
end
