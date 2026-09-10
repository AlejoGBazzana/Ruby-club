class Api::V1::BaseController < ActionController::API
  before_action :authenticate_api_user!

  rescue_from ActionController::ParameterMissing, with: :parameter_missing
  rescue_from ActiveRecord::RecordNotFound, with: :record_not_found

  private

  attr_reader :current_api_user

  def authenticate_api_user!
    @current_api_user = User.authenticate_api_token(bearer_token)
    return if current_api_user

    render_error(:unauthorized, "unauthorized", "Token de autenticación inválido o ausente.")
  end

  def bearer_token
    match = request.headers["Authorization"].to_s.match(/\ABearer\s+(.+)\z/i)
    match&.[](1)&.strip
  end

  def current_deportista
    current_api_user.socio&.deportista
  end

  def require_current_deportista!
    return if current_deportista

    render_error(:unprocessable_entity, "deportista_required", "El usuario no tiene un deportista asociado.")
  end

  def render_error(status, code, message, details: nil)
    error = { code: code, message: message }
    error[:details] = details if details.present?

    render json: { error: error }, status: status
  end

  def parameter_missing(exception)
    render_error(:bad_request, "bad_request", "Falta el parámetro requerido: #{exception.param}.")
  end

  def record_not_found
    render_error(:not_found, "not_found", "Recurso no encontrado.")
  end
end
