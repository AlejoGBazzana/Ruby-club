require "test_helper"

class DeportistaTest < ActiveSupport::TestCase
  def setup
    @socio = Socio.create!(
      nombre: "Lionel",
      apellido: "Messi",
      email: "lionel.messi@club.com"
    )
    @deportista = Deportista.new(socio: @socio, edad: 36)
  end

  test "deportista valido con socio y edad" do
    assert @deportista.valid?
    assert @deportista.save
  end

  test "deportista requiere socio" do
    @deportista.socio = nil
    assert_not @deportista.valid?
    assert @deportista.errors.of_kind?(:socio, :blank)
  end

  test "un socio no puede tener mas de un deportista" do
    @deportista.save!
    segundo = Deportista.new(socio: @socio, edad: 20)
    assert_not segundo.valid?
    assert segundo.errors.of_kind?(:socio_id, :taken)
  end

  test "deportista requiere edad" do
    @deportista.edad = nil
    assert_not @deportista.valid?
    assert @deportista.errors.of_kind?(:edad, :blank)
  end

  test "edad de deportista no puede ser negativa" do
    @deportista.edad = -1
    assert_not @deportista.valid?
    assert @deportista.errors.of_kind?(:edad, :greater_than_or_equal_to)
  end

  test "edad de deportista debe ser un numero entero" do
    @deportista.edad = 15.5
    assert_not @deportista.valid?
    assert @deportista.errors.of_kind?(:edad, :not_an_integer)
  end

  test "edad de deportista puede ser cero" do
    @deportista.edad = 0
    assert @deportista.valid?
  end

  test "deportista delega datos de identidad hacia socio sin tener atributo nombre propio" do
    assert_respond_to @deportista, :nombre
    assert_respond_to @deportista, :apellido
    assert_respond_to @deportista, :email
    assert_respond_to @deportista, :nombre_completo

    assert_equal "Lionel", @deportista.nombre
    assert_equal "Messi", @deportista.apellido
    assert_equal "lionel.messi@club.com", @deportista.email
    assert_equal "Lionel Messi", @deportista.nombre_completo

    assert_not Deportista.column_names.include?("nombre")
  end

  test "asociacion N a M con deportes" do
    @deportista.save!
    futbol = Deporte.create!(nombre: "Fútbol")
    padel = Deporte.create!(nombre: "Pádel")

    @deportista.deportes << futbol
    @deportista.deportes << padel

    assert_equal 2, @deportista.deportes.count
    assert_includes futbol.deportistas, @deportista
  end

  test "no permite duplicar la relacion entre el mismo deportista y deporte a nivel de base de datos" do
    @deportista.save!
    futbol = Deporte.create!(nombre: "Fútbol")
    @deportista.deportes << futbol

    assert_raises(ActiveRecord::RecordNotUnique) do
      @deportista.deportes << futbol
    end
  end

  test "no se puede eliminar deportista si tiene inscripciones (restrict_with_error)" do
    @deportista.save!
    deporte = Deporte.create!(nombre: "Tenis")
    actividad = Actividad.create!(
      nombre: "Clase Tenis",
      fecha: Date.tomorrow,
      horario: Time.current,
      cupo: 5,
      deporte: deporte
    )
    Inscripcion.create!(deportista: @deportista, actividad: actividad, estado: "confirmada")

    assert_no_difference("Deportista.count") do
      assert_not @deportista.destroy
    end
    assert_not_empty @deportista.errors[:base]
  end
end
