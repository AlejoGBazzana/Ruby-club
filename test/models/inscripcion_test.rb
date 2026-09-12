require "test_helper"

class InscripcionTest < ActiveSupport::TestCase
  include ActionMailer::TestHelper
  def setup
    @socio1 = Socio.create!(nombre: "Juan", apellido: "Perez", email: "juan.perez@club.com")
    @socio2 = Socio.create!(nombre: "Pedro", apellido: "Gomez", email: "pedro.gomez@club.com")
    @socio3 = Socio.create!(nombre: "Lucas", apellido: "Rodriguez", email: "lucas.rodriguez@club.com")

    @deportista1 = Deportista.create!(socio: @socio1, edad: 20)
    @deportista2 = Deportista.create!(socio: @socio2, edad: 22)
    @deportista3 = Deportista.create!(socio: @socio3, edad: 24)

    @deporte = Deporte.create!(nombre: "Fútbol")
    @actividad = Actividad.create!(
      nombre: "Torneo Fin de Semana",
      fecha: Date.tomorrow,
      horario: Time.parse("15:00:00"),
      cupo: 2,
      deporte: @deporte
    )
  end

  test "inscripcion valida asigna fecha_inscripcion automaticamente y estado pendiente por defecto" do
    inscripcion = Inscripcion.new(deportista: @deportista1, actividad: @actividad)
    assert inscripcion.valid?
    assert inscripcion.save
    assert_equal Date.current, inscripcion.fecha_inscripcion
    assert_equal "pendiente", inscripcion.estado
    assert inscripcion.activa?
    assert_not inscripcion.cancelada?
  end

  test "inscripcion requiere deportista" do
    inscripcion = Inscripcion.new(actividad: @actividad, estado: "pendiente")
    assert_not inscripcion.valid?
    assert inscripcion.errors.of_kind?(:deportista, :blank)
  end

  test "inscripcion requiere actividad" do
    inscripcion = Inscripcion.new(deportista: @deportista1, estado: "pendiente")
    assert_not inscripcion.valid?
    assert inscripcion.errors.of_kind?(:actividad, :blank)
  end

  test "estado de inscripcion debe pertenecer a los estados definidos" do
    ["pendiente", "confirmada", "cancelada"].each do |estado_valido|
      inscripcion = Inscripcion.new(deportista: @deportista1, actividad: @actividad, estado: estado_valido)
      assert inscripcion.valid?, "#{estado_valido} debería ser un estado válido"
    end

    inscripcion_invalida = Inscripcion.new(deportista: @deportista1, actividad: @actividad, estado: "finalizada")
    assert_not inscripcion_invalida.valid?
    assert inscripcion_invalida.errors.of_kind?(:estado, :inclusion)
  end

  # Regla 1: No se puede superar el cupo de una Actividad
  test "no se puede superar el cupo de una actividad con inscripciones activas" do
    Inscripcion.create!(deportista: @deportista1, actividad: @actividad, estado: "confirmada")
    Inscripcion.create!(deportista: @deportista2, actividad: @actividad, estado: "pendiente")

    assert_equal 2, @actividad.cantidad_inscripciones_activas
    assert @actividad.completa?

    # Tercer deportista intenta inscribirse en actividad con cupo 2
    tercera_inscripcion = Inscripcion.new(deportista: @deportista3, actividad: @actividad, estado: "pendiente")
    assert_not tercera_inscripcion.valid?
    assert_includes tercera_inscripcion.errors[:base], "La actividad ha alcanzado su cupo máximo"
    assert_not tercera_inscripcion.save
  end

  # Regla 2: Inscripciones canceladas no ocupan cupo
  test "inscripciones canceladas no ocupan cupo permitiendo nueva inscripcion activa" do
    inscripcion1 = Inscripcion.create!(deportista: @deportista1, actividad: @actividad, estado: "confirmada")
    Inscripcion.create!(deportista: @deportista2, actividad: @actividad, estado: "pendiente")

    assert @actividad.completa?

    # Cancelamos la primera
    inscripcion1.cancelar!
    assert inscripcion1.cancelada?
    assert_not inscripcion1.activa?
    assert_not @actividad.completa?

    # Ahora el deportista 3 sí puede inscribirse
    tercera_inscripcion = Inscripcion.new(deportista: @deportista3, actividad: @actividad, estado: "confirmada")
    assert tercera_inscripcion.valid?
    assert tercera_inscripcion.save
    assert @actividad.completa?
  end

  # Regla 3: No puede existir más de una inscripción activa del mismo Deportista para la misma Actividad
  test "un deportista no puede tener dos inscripciones activas para la misma actividad" do
    Inscripcion.create!(deportista: @deportista1, actividad: @actividad, estado: "pendiente")

    segunda_inscripcion = Inscripcion.new(deportista: @deportista1, actividad: @actividad, estado: "confirmada")
    assert_not segunda_inscripcion.valid?
    assert_includes segunda_inscripcion.errors[:base], "El deportista ya cuenta con una inscripción activa en esta actividad"
  end

  # Regla 4: Se permite volver a inscribirse después de cancelar la inscripción anterior
  test "un deportista puede volver a inscribirse despues de cancelar su inscripcion previa" do
    primera = Inscripcion.create!(deportista: @deportista1, actividad: @actividad, estado: "pendiente")
    primera.cancelar!
    assert primera.cancelada?

    # Nueva inscripción para el mismo deportista en la misma actividad
    segunda = Inscripcion.new(deportista: @deportista1, actividad: @actividad, estado: "confirmada")
    assert segunda.valid?
    assert segunda.save
    assert_equal 2, Inscripcion.where(deportista: @deportista1, actividad: @actividad).count
  end

  test "indice de base de datos protege contra doble inscripcion activa aun saltando validaciones" do
    Inscripcion.create!(deportista: @deportista1, actividad: @actividad, estado: "pendiente")

    segunda = Inscripcion.new(
      deportista: @deportista1,
      actividad: @actividad,
      estado: "confirmada",
      fecha_inscripcion: Date.current
    )

    assert_raises(ActiveRecord::RecordNotUnique) do
      segunda.save!(validate: false)
    end
  end

  test "metodos confirmar! y cancelar! actualizan el estado correctamente" do
    inscripcion = Inscripcion.create!(deportista: @deportista1, actividad: @actividad, estado: "pendiente")
    assert inscripcion.activa?

    inscripcion.confirmar!
    assert_equal "confirmada", inscripcion.estado
    assert inscripcion.activa?

    inscripcion.cancelar!
    assert_equal "cancelada", inscripcion.estado
    assert_not inscripcion.activa?
    assert inscripcion.cancelada?
  end

  test "envia una confirmacion solo al pasar de pendiente a confirmada" do
    inscripcion = Inscripcion.create!(deportista: @deportista1, actividad: @actividad, estado: "pendiente")

    assert_emails 1 do
      inscripcion.confirmar!
    end

    correo = ActionMailer::Base.deliveries.last
    assert_equal [@socio1.email], correo.to

    ActionMailer::Base.deliveries.clear
    assert_no_emails do
      inscripcion.update!(fecha_inscripcion: Date.yesterday)
    end
  end

  test "no envia correo para inscripciones pendientes ni canceladas" do
    assert_no_emails do
      inscripcion = Inscripcion.create!(deportista: @deportista1, actividad: @actividad, estado: "pendiente")
      inscripcion.cancelar!
    end
  end
end
