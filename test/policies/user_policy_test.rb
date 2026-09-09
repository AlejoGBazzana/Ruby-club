require "test_helper"

class UserPolicyTest < ActiveSupport::TestCase
  test "a regular user is not authorized for the admin area" do
    user = User.new(role: :user)

    assert_not UserPolicy.new(user, user).access_admin?
  end

  test "an admin is authorized for the admin area" do
    user = User.new(role: :admin)

    assert_predicate UserPolicy.new(user, user), :access_admin?
  end

  test "a superadmin is authorized for the admin area" do
    user = User.new(role: :superadmin)

    assert_predicate UserPolicy.new(user, user), :access_admin?
  end
end
