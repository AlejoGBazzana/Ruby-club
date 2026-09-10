class Api::V1::InscripcionesController < Api::V1::BaseController
  before_action :require_current_deportista!
  before_action :set_inscripcion, only: :destroy

  def index
    inscripciones = current_deportista.inscripciones.includes(actividad: :deporte).order(fecha_inscripcion: :desc)

    render json: { inscripciones: inscripciones.map { |inscripcion| inscripcion_payload(inscripcion) } }
  end

  def create
    actividad = Actividad.find(params.require(:actividad_id))
    inscripcion = current_deportista.inscripciones.build(actividad: actividad, estado: "pendiente")

    if inscripcion.save
      render json: { inscripcion: inscripcion_payload(inscripcion) }, status: :created
    else
      render_error(:unprocessable_entity, "validation_error", "No se pudo crear la inscripción.", details: inscripcion.errors.full_messages)
    end
  end

  def destroy
    @inscripcion.cancelar!
    head :no_content
  end

  private

  def set_inscripcion
    @inscripcion = current_deportista.inscripciones.find_by(id: params[:id])
    return if @inscripcion

    render_error(:not_found, "not_found", "Inscripción no encontrada.")
  end

  def inscripcion_payload(inscripcion)
    {
      id: inscripcion.id,
      fecha_inscripcion: inscripcion.fecha_inscripcion,
      estado: inscripcion.estado,
      actividad: {
        id: inscripcion.actividad.id,
        nombre: inscripcion.actividad.nombre,
        fecha: inscripcion.actividad.fecha,
        horario: inscripcion.actividad.horario.strftime("%H:%M"),
        deporte: {
          id: inscripcion.actividad.deporte.id,
          nombre: inscripcion.actividad.deporte.nombre
        }
      }
    }
  end
end
