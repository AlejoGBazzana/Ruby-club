class Api::V1::AuthenticationController < Api::V1::BaseController
  skip_before_action :authenticate_api_user!, only: :login

  def login
    user = User.find_for_database_authentication(email: params[:email].to_s.strip)

    if user&.valid_password?(params[:password])
      token = user.generate_api_token!
      render json: { token: token, user: user_payload(user) }, status: :ok
    else
      render_error(:unauthorized, "invalid_credentials", "Email o contraseña inválidos.")
    end
  end

  def logout
    current_api_user.invalidate_api_token!
    head :no_content
  end

  private

  def user_payload(user)
    {
      id: user.id,
      email: user.email,
      role: user.role
    }
  end
end
