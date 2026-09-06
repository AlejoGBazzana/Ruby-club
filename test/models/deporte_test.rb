require "test_helper"

class DeporteTest < ActiveSupport::TestCase
  def setup
    @deporte = Deporte.new(nombre: "Tenis")
  end

  test "deporte valido con nombre" do
    assert @deporte.valid?
    assert @deporte.save
  end

  test "deporte requiere nombre" do
    @deporte.nombre = ""
    assert_not @deporte.valid?
    assert @deporte.errors.of_kind?(:nombre, :blank)
  end

  test "nombre de deporte es unico e insensible a mayusculas" do
    @deporte.save!
    duplicado = Deporte.new(nombre: "TENIS")
    assert_not duplicado.valid?
    assert duplicado.errors.of_kind?(:nombre, :taken)
  end

  test "asociacion con actividades y deportistas" do
    @deporte.save!
    socio = Socio.create!(nombre: "Manu", apellido: "Ginobili", email: "manu@club.com")
    deportista = Deportista.create!(socio: socio, edad: 46)
    @deporte.deportistas << deportista

    actividad = Actividad.create!(
      nombre: "Entrenamiento Primera",
      fecha: Date.tomorrow,
      horario: Time.current,
      cupo: 15,
      deporte: @deporte
    )

    assert_includes @deporte.deportistas, deportista
    assert_includes @deporte.actividades, actividad
  end

  test "no se puede eliminar deporte si tiene actividades asociadas (restrict_with_error)" do
    @deporte.save!
    Actividad.create!(
      nombre: "Escuelita",
      fecha: Date.tomorrow,
      horario: Time.current,
      cupo: 10,
      deporte: @deporte
    )

    assert_no_difference("Deporte.count") do
      assert_not @deporte.destroy
    end
    assert_not_empty @deporte.errors[:base]
  end
end
