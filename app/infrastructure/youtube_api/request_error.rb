# frozen_string_literal: true

module YoutubeApi
  class RequestError < StandardError
    attr_reader :status, :reason

    # @param [String] message
    # @param [Integer, String, nil] status
    # @param [String, nil] reason
    def initialize(message, status: nil, reason: nil)
      @status = status
      @reason = reason
      super(message)
    end

    # @return [Boolean]
    def quota_exceeded?
      reason.to_s == "quotaExceeded"
    end

    # @return [Boolean]
    def chat_unavailable?
      %w[liveChatDisabled liveChatNotFound liveChatEnded forbidden].include?(reason.to_s)
    end
  end
end
