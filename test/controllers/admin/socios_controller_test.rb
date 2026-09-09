require "test_helper"

class Admin::SociosControllerTest < ActionDispatch::IntegrationTest
  setup do
    @admin = User.create!(email: "admin-socios@example.com", password: "password", role: :admin)
    sign_in @admin
    @socio = Socio.create!(nombre: "Ana", apellido: "López", email: "ana@example.com")
  end

  test "index" do
    get admin_socios_url

    assert_response :success
  end

  test "show" do
    get admin_socio_url(@socio)

    assert_response :success
  end

  test "create with valid attributes" do
    assert_difference("Socio.count") do
      post admin_socios_url, params: { socio: { nombre: "Bruno", apellido: "Díaz", email: "bruno@example.com", fecha_inscripcion: Date.current } }
    end

    assert_redirected_to admin_socio_url(Socio.last)
  end

  test "create with invalid attributes" do
    assert_no_difference("Socio.count") do
      post admin_socios_url, params: { socio: { nombre: "", apellido: "Díaz", email: "bruno@example.com" } }
    end

    assert_response :unprocessable_entity
  end

  test "update" do
    patch admin_socio_url(@socio), params: { socio: { nombre: "Ana María" } }

    assert_redirected_to admin_socio_url(@socio)
    assert_equal "Ana María", @socio.reload.nombre
  end

  test "destroy" do
    assert_difference("Socio.count", -1) do
      delete admin_socio_url(@socio)
    end

    assert_redirected_to admin_socios_url
  end
end
