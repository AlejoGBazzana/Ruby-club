require "test_helper"

class UserTest < ActiveSupport::TestCase
  test "a regular user cannot access the admin area" do
    user = User.new(role: :user)

    assert_not user.can_access_admin?
  end

  test "an admin can access the admin area" do
    user = User.new(role: :admin)

    assert_predicate user, :can_access_admin?
  end

  test "a superadmin can access the admin area" do
    user = User.new(role: :superadmin)

    assert_predicate user, :can_access_admin?
  end
end
