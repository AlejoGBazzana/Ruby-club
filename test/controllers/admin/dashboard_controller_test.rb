require "test_helper"

class Admin::DashboardControllerTest < ActionDispatch::IntegrationTest
  test "redirects unauthenticated users to sign in" do
    get admin_root_url

    assert_redirected_to new_user_session_url
  end

  test "denies a regular user" do
    user = User.create!(email: "user@example.com", password: "password", role: :user)
    sign_in user

    get admin_root_url

    assert_response :forbidden
  end

  test "allows an admin" do
    user = User.create!(email: "admin@example.com", password: "password", role: :admin)
    sign_in user

    get admin_root_url

    assert_response :success
  end

  test "allows a superadmin" do
    user = User.create!(email: "superadmin@example.com", password: "password", role: :superadmin)
    sign_in user

    get admin_root_url

    assert_response :success
  end
end
