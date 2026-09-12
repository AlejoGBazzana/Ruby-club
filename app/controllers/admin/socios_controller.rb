class Admin::SociosController < Admin::BaseController
  before_action :set_socio, only: %i[show edit update destroy]

  def index
    @socios = Socio.order(:apellido, :nombre)
  end

  def show
  end

  def new
    @socio = Socio.new
  end

  def create
    @socio = Socio.new(socio_params)

    if @socio.save
      redirect_to admin_socio_path(@socio), notice: "Socio creado correctamente."
    else
      render :new, status: :unprocessable_entity
    end
  end

  def edit
  end

  def update
    if @socio.update(socio_params)
      redirect_to admin_socio_path(@socio), notice: "Socio actualizado correctamente."
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    if @socio.destroy
      redirect_to admin_socios_path, notice: "Socio eliminado correctamente."
    else
      redirect_to admin_socio_path(@socio), alert: @socio.errors.full_messages.to_sentence
    end
  end

  private

  def set_socio
    @socio = Socio.find(params[:id])
  end

  def socio_params
    params.require(:socio).permit(:nombre, :apellido, :email, :fecha_inscripcion, :foto_perfil)
  end
end
