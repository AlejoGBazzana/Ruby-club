class UserPolicy < ApplicationPolicy
  def access_admin?
    user&.can_access_admin?
  end
end
