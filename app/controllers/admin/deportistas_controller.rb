class Admin::DeportistasController < Admin::BaseController
  before_action :set_deportista, only: %i[show edit update destroy]
  before_action :load_socios_disponibles, only: %i[new edit]

  def index
    @deportistas = Deportista.includes(:socio, :deportes)
  end

  def show
  end

  def new
    @deportista = Deportista.new
  end

  def create
    @deportista = Deportista.new(deportista_params)

    if @deportista.save
      redirect_to admin_deportista_path(@deportista), notice: "Deportista creado correctamente."
    else
      load_socios_disponibles
      render :new, status: :unprocessable_entity
    end
  end

  def edit
  end

  def update
    if @deportista.update(deportista_params)
      redirect_to admin_deportista_path(@deportista), notice: "Deportista actualizado correctamente."
    else
      load_socios_disponibles
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    if @deportista.destroy
      redirect_to admin_deportistas_path, notice: "Deportista eliminado correctamente."
    else
      redirect_to admin_deportista_path(@deportista), alert: @deportista.errors.full_messages.to_sentence
    end
  end

  private

  def set_deportista
    @deportista = Deportista.find(params[:id])
  end

  def load_socios_disponibles
    @socios = Socio.left_outer_joins(:deportista)
                   .where(deportistas: { id: [ nil, @deportista.id ] })
                   .order(:apellido, :nombre)
  end

  def deportista_params
    params.require(:deportista).permit(:socio_id, :edad)
  end
end
