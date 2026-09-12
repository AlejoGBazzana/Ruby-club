require "test_helper"

class SocioTest < ActiveSupport::TestCase
  def setup
    @socio_valido = Socio.new(
      nombre: "Carlos",
      apellido: "Tevez",
      email: "carlos.tevez@club.com"
    )
  end

  test "crear socio valido asigna fecha_inscripcion automaticamente" do
    assert @socio_valido.valid?
    assert @socio_valido.save
    assert_equal Date.current, @socio_valido.fecha_inscripcion
  end

  test "socio requiere nombre" do
    @socio_valido.nombre = ""
    assert_not @socio_valido.valid?
    assert @socio_valido.errors.of_kind?(:nombre, :blank)
  end

  test "socio requiere apellido" do
    @socio_valido.apellido = ""
    assert_not @socio_valido.valid?
    assert @socio_valido.errors.of_kind?(:apellido, :blank)
  end

  test "socio requiere email" do
    @socio_valido.email = ""
    assert_not @socio_valido.valid?
    assert @socio_valido.errors.of_kind?(:email, :blank)
  end

  test "email de socio debe tener formato valido" do
    ["invalido", "sin_arroba.com", "usuario@"].each do |email_invalido|
      @socio_valido.email = email_invalido
      assert_not @socio_valido.valid?, "#{email_invalido} debería ser inválido"
      assert @socio_valido.errors.of_kind?(:email, :invalid)
    end
  end

  test "email de socio es unico e insensible a mayusculas" do
    @socio_valido.save!
    socio_duplicado = Socio.new(
      nombre: "Otro",
      apellido: "Socio",
      email: "CARLOS.TEVEZ@CLUB.COM"
    )
    assert_not socio_duplicado.valid?
    assert socio_duplicado.errors.of_kind?(:email, :taken)
  end

  test "socio no puede tener dos deportistas" do
    @socio_valido.save!
    Deportista.create!(socio: @socio_valido, edad: 25)

    segundo_deportista = Deportista.new(socio: @socio_valido, edad: 30)
    assert_not segundo_deportista.valid?
    assert segundo_deportista.errors.of_kind?(:socio_id, :taken)
  end

  test "no se puede eliminar socio si tiene deportista asociado (restrict_with_error)" do
    @socio_valido.save!
    Deportista.create!(socio: @socio_valido, edad: 20)

    assert_no_difference("Socio.count") do
      assert_not @socio_valido.destroy
    end
    assert_not_empty @socio_valido.errors[:base]
  end

  test "nombre_completo devuelve nombre y apellido concatenados" do
    assert_equal "Carlos Tevez", @socio_valido.nombre_completo
  end

  test "permite adjuntar una foto de perfil valida" do
    @socio_valido.foto_perfil.attach(
      io: StringIO.new("contenido de imagen"),
      filename: "perfil.png",
      content_type: "image/png"
    )

    assert @socio_valido.save
    assert_predicate @socio_valido.foto_perfil, :attached?
    assert_equal "image/png", @socio_valido.foto_perfil.blob.content_type
  end

  test "rechaza una foto de perfil con tipo no permitido" do
    @socio_valido.foto_perfil.attach(
      io: StringIO.new("contenido de documento"),
      filename: "perfil.pdf",
      content_type: "application/pdf"
    )

    assert_not @socio_valido.valid?
    assert_includes @socio_valido.errors[:foto_perfil], "debe ser una imagen JPEG, PNG o WebP"
  end
end
