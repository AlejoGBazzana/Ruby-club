require_relative "api_test_helper"

class Api::V1::AuthenticationControllerTest < ActionDispatch::IntegrationTest
  include ApiTestHelper

  setup do
    @user = User.create!(email: "api-user@example.com", password: "password", role: :user)
  end

  test "login returns a bearer token without exposing sensitive attributes" do
    post api_v1_login_url, params: { email: @user.email, password: "password" }, as: :json

    assert_response :success
    body = json_response
    assert body["token"].present?
    assert_equal @user.id, body.dig("user", "id")
    assert_equal @user.email, body.dig("user", "email")
    assert_not_includes response.body, "encrypted_password"
    assert_equal @user, User.authenticate_api_token(body["token"])
    assert_not_equal body["token"], @user.reload.api_token_digest
  end

  test "login rejects invalid credentials" do
    post api_v1_login_url, params: { email: @user.email, password: "incorrecta" }, as: :json

    assert_response :unauthorized
    assert_equal "invalid_credentials", json_response.dig("error", "code")
  end

  test "protected endpoints reject requests without a bearer token" do
    get api_v1_me_url, as: :json

    assert_response :unauthorized
    assert_equal "unauthorized", json_response.dig("error", "code")
  end

  test "logout revokes the bearer token" do
    token = @user.generate_api_token!

    post api_v1_logout_url, headers: authorization_headers(token), as: :json

    assert_response :no_content
    assert_nil @user.reload.api_token_digest

    get api_v1_me_url, headers: authorization_headers(token), as: :json

    assert_response :unauthorized
  end
end
