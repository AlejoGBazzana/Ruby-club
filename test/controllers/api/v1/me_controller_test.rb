require_relative "api_test_helper"

class Api::V1::MeControllerTest < ActionDispatch::IntegrationTest
  include ApiTestHelper

  test "me returns only the authenticated user and their related records" do
    user, deportista = create_user_with_deportista(email: "me@example.com")
    token = user.generate_api_token!

    get api_v1_me_url, headers: authorization_headers(token), as: :json

    assert_response :success
    body = json_response
    assert_equal user.id, body.dig("user", "id")
    assert_equal user.email, body.dig("user", "email")
    assert_equal user.socio.id, body.dig("socio", "id")
    assert_equal deportista.id, body.dig("deportista", "id")
    assert_not_includes response.body, "encrypted_password"
  end

  test "me handles a user without a socio or deportista" do
    user = User.create!(email: "without-socio@example.com", password: "password", role: :user)
    token = user.generate_api_token!

    get api_v1_me_url, headers: authorization_headers(token), as: :json

    assert_response :success
    assert_nil json_response["socio"]
    assert_nil json_response["deportista"]
  end
end
