class Admin::ActividadesController < Admin::BaseController
  before_action :set_actividad, only: %i[show edit update destroy]
  before_action :load_deportes, only: %i[new edit]

  def index
    @actividades = Actividad.includes(:deporte).order(:fecha, :horario)
  end

  def show
  end

  def new
    @actividad = Actividad.new
  end

  def create
    @actividad = Actividad.new(actividad_params)

    if @actividad.save
      redirect_to admin_actividad_path(@actividad), notice: "Actividad creada correctamente."
    else
      load_deportes
      render :new, status: :unprocessable_entity
    end
  end

  def edit
  end

  def update
    if @actividad.update(actividad_params)
      redirect_to admin_actividad_path(@actividad), notice: "Actividad actualizada correctamente."
    else
      load_deportes
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    if @actividad.destroy
      redirect_to admin_actividades_path, notice: "Actividad eliminada correctamente."
    else
      redirect_to admin_actividad_path(@actividad), alert: @actividad.errors.full_messages.to_sentence
    end
  end

  private

  def set_actividad
    @actividad = Actividad.find(params[:id])
  end

  def load_deportes
    @deportes = Deporte.order(:nombre)
  end

  def actividad_params
    params.require(:actividad).permit(:nombre, :fecha, :horario, :cupo, :deporte_id)
  end
end
