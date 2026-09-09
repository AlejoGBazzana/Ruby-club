class Admin::BaseController < ApplicationController
  before_action :authenticate_user!
  before_action :authorize_admin!

  after_action :verify_authorized

  private

  def authorize_admin!
    authorize current_user, :access_admin?, policy_class: UserPolicy
  end
end
