class Api::V1::ActividadesController < Api::V1::BaseController
  def index
    actividades = Actividad.includes(:deporte).order(:fecha, :horario)

    render json: { actividades: actividades.map { |actividad| actividad_payload(actividad) } }
  end

  private

  def actividad_payload(actividad)
    {
      id: actividad.id,
      nombre: actividad.nombre,
      fecha: actividad.fecha,
      horario: actividad.horario.strftime("%H:%M"),
      cupo: actividad.cupo,
      cupo_disponible: actividad.cupo_disponible,
      deporte: {
        id: actividad.deporte.id,
        nombre: actividad.deporte.nombre
      }
    }
  end
end
