class Api::V1::MeController < Api::V1::BaseController
  def show
    render json: {
      user: user_payload,
      socio: socio_payload,
      deportista: deportista_payload
    }
  end

  private

  def user_payload
    {
      id: current_api_user.id,
      email: current_api_user.email,
      role: current_api_user.role
    }
  end

  def socio_payload
    socio = current_api_user.socio
    return unless socio

    {
      id: socio.id,
      nombre: socio.nombre,
      apellido: socio.apellido,
      email: socio.email,
      fecha_inscripcion: socio.fecha_inscripcion
    }
  end

  def deportista_payload
    deportista = current_deportista
    return unless deportista

    {
      id: deportista.id,
      edad: deportista.edad
    }
  end
end
