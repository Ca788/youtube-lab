# frozen_string_literal: true

class UseCase::User::CreateUserUseCase
  Result = Struct.new(:user, :token, keyword_init: true)

  # @param [String] name
  # @param [String] email
  # @param [String] password
  # @param [String] password_confirmation
  # @return [Result]
  def call(name:, email:, password:, password_confirmation:)
    user = User.create!(
      name:                  name,
      email:                 email,
      password:              password,
      password_confirmation: password_confirmation
    )

    token = Warden::JWTAuth::UserEncoder.new.call(user, :user, nil).first

    Result.new(user: user, token: token)
  end
end
