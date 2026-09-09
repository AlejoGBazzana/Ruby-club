class Admin::DeportesController < Admin::BaseController
  before_action :set_deporte, only: %i[show edit update destroy]

  def index
    @deportes = Deporte.order(:nombre)
  end

  def show
  end

  def new
    @deporte = Deporte.new
  end

  def create
    @deporte = Deporte.new(deporte_params)

    if @deporte.save
      redirect_to admin_deporte_path(@deporte), notice: "Deporte creado correctamente."
    else
      render :new, status: :unprocessable_entity
    end
  end

  def edit
  end

  def update
    if @deporte.update(deporte_params)
      redirect_to admin_deporte_path(@deporte), notice: "Deporte actualizado correctamente."
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    if @deporte.destroy
      redirect_to admin_deportes_path, notice: "Deporte eliminado correctamente."
    else
      redirect_to admin_deporte_path(@deporte), alert: @deporte.errors.full_messages.to_sentence
    end
  end

  private

  def set_deporte
    @deporte = Deporte.find(params[:id])
  end

  def deporte_params
    params.require(:deporte).permit(:nombre)
  end
end
