require_relative "api_test_helper"

class Api::V1::ActividadesControllerTest < ActionDispatch::IntegrationTest
  include ApiTestHelper

  test "authenticated users can list activities with their deporte" do
    user = User.create!(email: "activities@example.com", password: "password", role: :user)
    token = user.generate_api_token!
    deporte = Deporte.create!(nombre: "Natación")
    actividad = Actividad.create!(nombre: "Pileta libre", fecha: Date.tomorrow, horario: Time.zone.parse("10:30"), cupo: 12, deporte: deporte)

    get api_v1_actividades_url, headers: authorization_headers(token), as: :json

    assert_response :success
    activity = json_response.fetch("actividades").find { |item| item["id"] == actividad.id }
    assert_equal "Pileta libre", activity["nombre"]
    assert_equal "10:30", activity["horario"]
    assert_equal 12, activity["cupo"]
    assert_equal deporte.id, activity.dig("deporte", "id")
    assert_equal "Natación", activity.dig("deporte", "nombre")
  end
end
