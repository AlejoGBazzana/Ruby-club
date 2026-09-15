require "test_helper"

class FrontendControllerTest < ActionDispatch::IntegrationTest
  test "debe acceder a la ruta raíz y responder con éxito" do
    get root_url
    assert_response :success
    assert_select "title", text: /Ruby Club/
  end

  test "debe acceder a la pantalla de login" do
    get login_url
    assert_response :success
    assert_select "h1.login-title", text: "Ruby Club"
    assert_select "form"
    assert_select "input[type=email]"
    assert_select "input[type=password]"
  end

  test "debe acceder a la pantalla de actividades" do
    get actividades_url
    assert_response :success
    assert_select "h1.page-title", text: "Actividades Deportivas"
    assert_select ".club-navbar"
  end

  test "debe acceder al detalle de una actividad" do
    deporte = Deporte.create!(nombre: "Fútbol Test")
    actividad = Actividad.create!(
      nombre: "Práctica Test",
      fecha: Date.tomorrow,
      horario: Time.zone.parse("15:00"),
      cupo: 10,
      deporte: deporte
    )

    get actividad_detalle_url(actividad)
    assert_response :success
    assert_select "a.back-link", text: /Volver a Actividades/
  end

  test "debe acceder a la pantalla de mis inscripciones" do
    get mis_inscripciones_url
    assert_response :success
    assert_select "h1.page-title", text: "Mis Inscripciones"
    assert_select "h2.section-heading", text: /Inscripciones Activas/
  end
end
