require "test_helper"

class Admin::ActividadesControllerTest < ActionDispatch::IntegrationTest
  setup do
    @admin = User.create!(email: "admin-actividades@example.com", password: "password", role: :admin)
    sign_in @admin
    @deporte = Deporte.create!(nombre: "Tenis")
    @actividad = Actividad.create!(nombre: "Entrenamiento", fecha: Date.tomorrow, horario: Time.zone.parse("10:00"), cupo: 10, deporte: @deporte)
  end

  test "index" do
    get admin_actividades_url

    assert_response :success
  end

  test "show" do
    get admin_actividad_url(@actividad)

    assert_response :success
  end

  test "create with valid attributes" do
    assert_difference("Actividad.count") do
      post admin_actividades_url, params: { actividad: { nombre: "Torneo", fecha: Date.tomorrow, horario: "15:00", cupo: 20, deporte_id: @deporte.id } }
    end

    assert_redirected_to admin_actividad_url(Actividad.last)
  end

  test "create with invalid attributes" do
    assert_no_difference("Actividad.count") do
      post admin_actividades_url, params: { actividad: { nombre: "", fecha: Date.tomorrow, horario: "15:00", cupo: 20, deporte_id: @deporte.id } }
    end

    assert_response :unprocessable_entity
  end

  test "update" do
    patch admin_actividad_url(@actividad), params: { actividad: { cupo: 12 } }

    assert_redirected_to admin_actividad_url(@actividad)
    assert_equal 12, @actividad.reload.cupo
  end

  test "destroy" do
    assert_difference("Actividad.count", -1) do
      delete admin_actividad_url(@actividad)
    end

    assert_redirected_to admin_actividades_url
  end
end
