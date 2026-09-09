class Admin::InscripcionesController < Admin::BaseController
  before_action :set_inscripcion, only: %i[show edit update destroy]
  before_action :load_form_options, only: %i[new edit]

  def index
    @inscripciones = Inscripcion.includes(deportista: :socio, actividad: :deporte).order(fecha_inscripcion: :desc)
  end

  def show
  end

  def new
    @inscripcion = Inscripcion.new
  end

  def create
    @inscripcion = Inscripcion.new(inscripcion_params)

    if @inscripcion.save
      redirect_to admin_inscripcion_path(@inscripcion), notice: "Inscripción creada correctamente."
    else
      load_form_options
      render :new, status: :unprocessable_entity
    end
  end

  def edit
  end

  def update
    if @inscripcion.update(inscripcion_params)
      redirect_to admin_inscripcion_path(@inscripcion), notice: "Inscripción actualizada correctamente."
    else
      load_form_options
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    if @inscripcion.destroy
      redirect_to admin_inscripciones_path, notice: "Inscripción eliminada correctamente."
    else
      redirect_to admin_inscripcion_path(@inscripcion), alert: @inscripcion.errors.full_messages.to_sentence
    end
  end

  private

  def set_inscripcion
    @inscripcion = Inscripcion.find(params[:id])
  end

  def load_form_options
    @deportistas = Deportista.includes(:socio)
    @actividades = Actividad.includes(:deporte).order(:fecha, :horario)
  end

  def inscripcion_params
    params.require(:inscripcion).permit(:deportista_id, :actividad_id, :fecha_inscripcion, :estado)
  end
end
