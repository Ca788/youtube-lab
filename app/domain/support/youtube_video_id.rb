# frozen_string_literal: true

require "uri"

module Support
  module YoutubeVideoId
    ID_PATTERN = /\A[A-Za-z0-9_-]{11}\z/
    PATH_PREFIXES = %w[live embed shorts v].freeze
    SHORT_HOSTS = %w[youtu.be].freeze

    # @param [String, nil] value
    # @return [String, nil]
    def self.extract(value)
      raw = value.to_s.strip
      return nil if raw.blank?
      return raw if raw.match?(ID_PATTERN)

      uri = parse_uri(raw)
      return nil if uri.nil?

      candidate = from_query(uri) || from_path(uri)
      candidate if candidate&.match?(ID_PATTERN)
    end

    # @param [String, nil] value
    # @return [String]
    def self.extract!(value)
      extract(value) || raise(ArgumentError, "#{value.inspect} is not a valid YouTube video URL or id")
    end

    def self.parse_uri(raw)
      normalized = raw.match?(%r{\Ahttps?://}i) ? raw : "https://#{raw}"
      URI.parse(normalized)
    rescue URI::InvalidURIError
      nil
    end

    def self.from_query(uri)
      return nil if uri.query.blank?

      URI.decode_www_form(uri.query).to_h["v"]
    end

    def self.from_path(uri)
      segments = uri.path.to_s.split("/").reject(&:blank?)
      return segments.first if SHORT_HOSTS.include?(uri.host.to_s.delete_prefix("www."))
      return segments.second if PATH_PREFIXES.include?(segments.first)

      nil
    end

    private_class_method :parse_uri, :from_query, :from_path
  end
end
