require_relative "api_test_helper"

class Api::V1::InscripcionesControllerTest < ActionDispatch::IntegrationTest
  include ApiTestHelper

  setup do
    @user, @deportista = create_user_with_deportista(email: "owner@example.com", nombre: "Ana", apellido: "López")
    @other_user, @other_deportista = create_user_with_deportista(email: "other@example.com", nombre: "Bruno", apellido: "Díaz")
    @token = @user.generate_api_token!
    @other_token = @other_user.generate_api_token!
    deporte = Deporte.create!(nombre: "Tenis")
    @actividad = Actividad.create!(nombre: "Entrenamiento", fecha: Date.tomorrow, horario: Time.zone.parse("10:00"), cupo: 3, deporte: deporte)
  end

  test "lists only the authenticated users own inscripciones" do
    own_inscripcion = Inscripcion.create!(deportista: @deportista, actividad: @actividad, estado: "pendiente")
    Inscripcion.create!(deportista: @other_deportista, actividad: @actividad, estado: "confirmada")

    get api_v1_inscripciones_url, headers: authorization_headers(@token), as: :json

    assert_response :success
    assert_equal [own_inscripcion.id], json_response.fetch("inscripciones").map { |inscripcion| inscripcion["id"] }
  end

  test "does not expose or cancel another users inscripcion" do
    other_inscripcion = Inscripcion.create!(deportista: @other_deportista, actividad: @actividad, estado: "pendiente")

    delete api_v1_inscripcion_url(other_inscripcion), headers: authorization_headers(@token), as: :json

    assert_response :not_found
    assert other_inscripcion.reload.activa?
  end

  test "creates a pending inscripcion for the authenticated deportista" do
    assert_difference("Inscripcion.count") do
      post api_v1_inscripciones_url, params: { actividad_id: @actividad.id }, headers: authorization_headers(@token), as: :json
    end

    assert_response :created
    assert_equal "pendiente", json_response.dig("inscripcion", "estado")
    assert_equal @actividad.id, json_response.dig("inscripcion", "actividad", "id")
    assert_equal @deportista, Inscripcion.last.deportista
  end

  test "requires an actividad id when creating an inscripcion" do
    post api_v1_inscripciones_url, params: {}, headers: authorization_headers(@token), as: :json

    assert_response :bad_request
    assert_equal "bad_request", json_response.dig("error", "code")
  end

  test "rejects an inscripcion when the activity is full" do
    @actividad.update!(cupo: 1)
    Inscripcion.create!(deportista: @other_deportista, actividad: @actividad, estado: "confirmada")

    post api_v1_inscripciones_url, params: { actividad_id: @actividad.id }, headers: authorization_headers(@token), as: :json

    assert_response :unprocessable_entity
    assert_includes json_response.dig("error", "details"), "La actividad ha alcanzado su cupo máximo"
  end

  test "rejects a duplicate active inscripcion" do
    Inscripcion.create!(deportista: @deportista, actividad: @actividad, estado: "pendiente")

    post api_v1_inscripciones_url, params: { actividad_id: @actividad.id }, headers: authorization_headers(@token), as: :json

    assert_response :unprocessable_entity
    assert_includes json_response.dig("error", "details"), "El deportista ya cuenta con una inscripción activa en esta actividad"
  end

  test "allows reinscription after a previous cancellation" do
    previous = Inscripcion.create!(deportista: @deportista, actividad: @actividad, estado: "pendiente")
    previous.cancelar!

    assert_difference("Inscripcion.count") do
      post api_v1_inscripciones_url, params: { actividad_id: @actividad.id }, headers: authorization_headers(@token), as: :json
    end

    assert_response :created
    assert_equal "pendiente", json_response.dig("inscripcion", "estado")
  end

  test "cancels an own inscripcion without deleting it and frees the cupo" do
    @actividad.update!(cupo: 1)
    own_inscripcion = Inscripcion.create!(deportista: @deportista, actividad: @actividad, estado: "confirmada")

    assert_no_difference("Inscripcion.count") do
      delete api_v1_inscripcion_url(own_inscripcion), headers: authorization_headers(@token), as: :json
    end

    assert_response :no_content
    assert own_inscripcion.reload.cancelada?
    assert_equal 1, @actividad.reload.cupo_disponible

    post api_v1_inscripciones_url, params: { actividad_id: @actividad.id }, headers: authorization_headers(@other_token), as: :json

    assert_response :created
  end

  test "returns a business error when the user has no deportista" do
    user = User.create!(email: "without-deportista@example.com", password: "password", role: :user)
    token = user.generate_api_token!

    get api_v1_inscripciones_url, headers: authorization_headers(token), as: :json

    assert_response :unprocessable_entity
    assert_equal "deportista_required", json_response.dig("error", "code")
  end
end
