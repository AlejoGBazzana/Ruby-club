require "test_helper"

class Admin::InscripcionesControllerTest < ActionDispatch::IntegrationTest
  setup do
    @admin = User.create!(email: "admin-inscripciones@example.com", password: "password", role: :admin)
    sign_in @admin
    @socio = Socio.create!(nombre: "Ana", apellido: "López", email: "ana@example.com")
    @otro_socio = Socio.create!(nombre: "Bruno", apellido: "Díaz", email: "bruno@example.com")
    @deportista = Deportista.create!(socio: @socio, edad: 25)
    @otro_deportista = Deportista.create!(socio: @otro_socio, edad: 30)
    @deporte = Deporte.create!(nombre: "Tenis")
    @actividad = Actividad.create!(nombre: "Entrenamiento", fecha: Date.tomorrow, horario: Time.zone.parse("10:00"), cupo: 3, deporte: @deporte)
    @inscripcion = Inscripcion.create!(deportista: @deportista, actividad: @actividad, estado: "pendiente")
  end

  test "index" do
    get admin_inscripciones_url

    assert_response :success
  end

  test "show" do
    get admin_inscripcion_url(@inscripcion)

    assert_response :success
  end

  test "create with valid attributes" do
    assert_difference("Inscripcion.count") do
      post admin_inscripciones_url, params: { inscripcion: { deportista_id: @otro_deportista.id, actividad_id: @actividad.id, fecha_inscripcion: Date.current, estado: "confirmada" } }
    end

    assert_redirected_to admin_inscripcion_url(Inscripcion.last)
  end

  test "create with invalid attributes" do
    assert_no_difference("Inscripcion.count") do
      post admin_inscripciones_url, params: { inscripcion: { deportista_id: @otro_deportista.id, actividad_id: @actividad.id, fecha_inscripcion: Date.current, estado: "" } }
    end

    assert_response :unprocessable_entity
  end

  test "update" do
    patch admin_inscripcion_url(@inscripcion), params: { inscripcion: { estado: "confirmada" } }

    assert_redirected_to admin_inscripcion_url(@inscripcion)
    assert_equal "confirmada", @inscripcion.reload.estado
  end

  test "destroy" do
    assert_difference("Inscripcion.count", -1) do
      delete admin_inscripcion_url(@inscripcion)
    end

    assert_redirected_to admin_inscripciones_url
  end
end
