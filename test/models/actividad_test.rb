require "test_helper"

class ActividadTest < ActiveSupport::TestCase
  def setup
    @deporte = Deporte.create!(nombre: "Natación")
    @actividad = Actividad.new(
      nombre: "Pileta Libre",
      fecha: Date.tomorrow,
      horario: Time.parse("10:00:00"),
      cupo: 3,
      deporte: @deporte
    )
  end

  test "actividad valida con todos sus atributos" do
    assert @actividad.valid?
    assert @actividad.save
  end

  test "actividad requiere nombre" do
    @actividad.nombre = ""
    assert_not @actividad.valid?
    assert @actividad.errors.of_kind?(:nombre, :blank)
  end

  test "actividad requiere fecha" do
    @actividad.fecha = nil
    assert_not @actividad.valid?
    assert @actividad.errors.of_kind?(:fecha, :blank)
  end

  test "actividad requiere horario" do
    @actividad.horario = nil
    assert_not @actividad.valid?
    assert @actividad.errors.of_kind?(:horario, :blank)
  end

  test "actividad requiere deporte" do
    @actividad.deporte = nil
    assert_not @actividad.valid?
    assert @actividad.errors.of_kind?(:deporte, :blank)
  end

  test "actividad requiere cupo" do
    @actividad.cupo = nil
    assert_not @actividad.valid?
    assert @actividad.errors.of_kind?(:cupo, :blank)
  end

  test "cupo de actividad debe ser mayor que cero" do
    @actividad.cupo = 0
    assert_not @actividad.valid?
    assert @actividad.errors.of_kind?(:cupo, :greater_than)

    @actividad.cupo = -5
    assert_not @actividad.valid?
    assert @actividad.errors.of_kind?(:cupo, :greater_than)
  end

  test "cupo de actividad debe ser un numero entero" do
    @actividad.cupo = 3.5
    assert_not @actividad.valid?
    assert @actividad.errors.of_kind?(:cupo, :not_an_integer)
  end

  test "calculo de inscripciones activas, cupo disponible y completitud" do
    @actividad.save!
    assert_equal 0, @actividad.cantidad_inscripciones_activas
    assert_equal 3, @actividad.cupo_disponible
    assert_not @actividad.completa?

    socio1 = Socio.create!(nombre: "Ana", apellido: "Lopez", email: "ana@club.com")
    deportista1 = Deportista.create!(socio: socio1, edad: 22)
    Inscripcion.create!(deportista: deportista1, actividad: @actividad, estado: "confirmada")

    assert_equal 1, @actividad.cantidad_inscripciones_activas
    assert_equal 2, @actividad.cupo_disponible
    assert_not @actividad.completa?

    socio2 = Socio.create!(nombre: "Beto", apellido: "Perez", email: "beto@club.com")
    deportista2 = Deportista.create!(socio: socio2, edad: 24)
    Inscripcion.create!(deportista: deportista2, actividad: @actividad, estado: "pendiente")

    assert_equal 2, @actividad.cantidad_inscripciones_activas
    assert_equal 1, @actividad.cupo_disponible
    assert_not @actividad.completa?

    socio3 = Socio.create!(nombre: "Caro", apellido: "Diaz", email: "caro@club.com")
    deportista3 = Deportista.create!(socio: socio3, edad: 26)
    Inscripcion.create!(deportista: deportista3, actividad: @actividad, estado: "confirmada")

    assert_equal 3, @actividad.cantidad_inscripciones_activas
    assert_equal 0, @actividad.cupo_disponible
    assert @actividad.completa?
  end

  test "inscripciones canceladas no ocupan lugar del cupo" do
    @actividad.cupo = 1
    @actividad.save!

    socio1 = Socio.create!(nombre: "Ana", apellido: "Lopez", email: "ana@club.com")
    deportista1 = Deportista.create!(socio: socio1, edad: 22)
    inscripcion1 = Inscripcion.create!(deportista: deportista1, actividad: @actividad, estado: "confirmada")

    assert @actividad.completa?
    assert_equal 0, @actividad.cupo_disponible

    inscripcion1.cancelar!

    assert_not @actividad.completa?
    assert_equal 1, @actividad.cupo_disponible
    assert_equal 0, @actividad.cantidad_inscripciones_activas
  end

  test "asociacion con deportistas a traves de inscripciones" do
    @actividad.save!
    socio = Socio.create!(nombre: "Dario", apellido: "Silva", email: "dario@club.com")
    deportista = Deportista.create!(socio: socio, edad: 30)
    Inscripcion.create!(deportista: deportista, actividad: @actividad, estado: "confirmada")

    assert_includes @actividad.deportistas, deportista
  end

  test "no se puede eliminar actividad si tiene inscripciones (restrict_with_error)" do
    @actividad.save!
    socio = Socio.create!(nombre: "Elena", apellido: "Gomez", email: "elena@club.com")
    deportista = Deportista.create!(socio: socio, edad: 28)
    Inscripcion.create!(deportista: deportista, actividad: @actividad, estado: "pendiente")

    assert_no_difference("Actividad.count") do
      assert_not @actividad.destroy
    end
    assert_not_empty @actividad.errors[:base]
  end
end
