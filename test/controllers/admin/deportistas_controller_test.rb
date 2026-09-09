require "test_helper"

class Admin::DeportistasControllerTest < ActionDispatch::IntegrationTest
  setup do
    @admin = User.create!(email: "admin-deportistas@example.com", password: "password", role: :admin)
    sign_in @admin
    @socio = Socio.create!(nombre: "Ana", apellido: "López", email: "ana@example.com")
    @deportista = Deportista.create!(socio: @socio, edad: 25)
  end

  test "index" do
    get admin_deportistas_url

    assert_response :success
  end

  test "show" do
    get admin_deportista_url(@deportista)

    assert_response :success
  end

  test "create with valid attributes" do
    socio_disponible = Socio.create!(nombre: "Bruno", apellido: "Díaz", email: "bruno@example.com")

    assert_difference("Deportista.count") do
      post admin_deportistas_url, params: { deportista: { socio_id: socio_disponible.id, edad: 30 } }
    end

    assert_redirected_to admin_deportista_url(Deportista.last)
  end

  test "create with invalid attributes" do
    assert_no_difference("Deportista.count") do
      post admin_deportistas_url, params: { deportista: { socio_id: @socio.id, edad: "" } }
    end

    assert_response :unprocessable_entity
  end

  test "update" do
    patch admin_deportista_url(@deportista), params: { deportista: { edad: 26 } }

    assert_redirected_to admin_deportista_url(@deportista)
    assert_equal 26, @deportista.reload.edad
  end

  test "destroy" do
    assert_difference("Deportista.count", -1) do
      delete admin_deportista_url(@deportista)
    end

    assert_redirected_to admin_deportistas_url
  end
end
