require "test_helper"

class Admin::DeportesControllerTest < ActionDispatch::IntegrationTest
  setup do
    @admin = User.create!(email: "admin-deportes@example.com", password: "password", role: :admin)
    sign_in @admin
    @deporte = Deporte.create!(nombre: "Tenis")
  end

  test "index" do
    get admin_deportes_url

    assert_response :success
  end

  test "show" do
    get admin_deporte_url(@deporte)

    assert_response :success
  end

  test "create with valid attributes" do
    assert_difference("Deporte.count") do
      post admin_deportes_url, params: { deporte: { nombre: "Natación" } }
    end

    assert_redirected_to admin_deporte_url(Deporte.last)
  end

  test "create with invalid attributes" do
    assert_no_difference("Deporte.count") do
      post admin_deportes_url, params: { deporte: { nombre: "" } }
    end

    assert_response :unprocessable_entity
  end

  test "update" do
    patch admin_deporte_url(@deporte), params: { deporte: { nombre: "Tenis de mesa" } }

    assert_redirected_to admin_deporte_url(@deporte)
    assert_equal "Tenis de mesa", @deporte.reload.nombre
  end

  test "destroy" do
    assert_difference("Deporte.count", -1) do
      delete admin_deporte_url(@deporte)
    end

    assert_redirected_to admin_deportes_url
  end
end
