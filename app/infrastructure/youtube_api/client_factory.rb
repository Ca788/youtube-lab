# frozen_string_literal: true

module YoutubeApi
  module ClientFactory
    # @param [String, nil] api_key
    # @return [YoutubeApi::Client]
    def self.build(api_key: ENV["YOUTUBE_API_KEY"])
      if api_key.blank?
        raise ConfigurationError, "YOUTUBE_API_KEY is not configured"
      end

      Client.new(credentials: Client::Credentials.new(api_key: api_key))
    end
  end
end
