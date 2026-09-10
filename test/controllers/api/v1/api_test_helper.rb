require "test_helper"

module ApiTestHelper
  def json_response
    JSON.parse(response.body)
  end

  def authorization_headers(token)
    { "Authorization" => "Bearer #{token}" }
  end

  def create_user_with_deportista(email:, nombre: "Ana", apellido: "López", edad: 25)
    socio = Socio.create!(nombre: nombre, apellido: apellido, email: "socio-#{email}")
    deportista = Deportista.create!(socio: socio, edad: edad)
    user = User.create!(email: email, password: "password", role: :user, socio: socio)

    [user, deportista]
  end
end
