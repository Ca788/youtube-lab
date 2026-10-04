# frozen_string_literal: true

module AuthHelpers
  # @param [User] user
  # @return [Hash]
  def auth_headers_for(user)
    token = Warden::JWTAuth::UserEncoder.new.call(user, :user, nil).first

    { "Authorization" => "Bearer #{token}" }
  end
end
