require "test_helper"

class InscripcionMailerTest < ActionMailer::TestCase
  setup do
    socio = Socio.create!(nombre: "Ana", apellido: "López", email: "ana@example.com")
    deportista = Deportista.create!(socio: socio, edad: 25)
    deporte = Deporte.create!(nombre: "Tenis")
    actividad = Actividad.create!(
      nombre: "Entrenamiento",
      fecha: Date.new(2026, 9, 12),
      horario: Time.zone.parse("10:00"),
      cupo: 3,
      deporte: deporte
    )
    @inscripcion = Inscripcion.create!(deportista: deportista, actividad: actividad, estado: "pendiente")
    @inscripcion.update_column(:estado, "confirmada")
  end

  test "confirmacion incluye los datos esenciales de la inscripcion" do
    correo = InscripcionMailer.confirmacion(@inscripcion)

    assert_equal ["ana@example.com"], correo.to
    assert_equal ["notificaciones@rubyclub.test"], correo.from
    assert_equal "Confirmación de inscripción a Entrenamiento", correo.subject

    contenido = correo.text_part.body.decoded
    assert_includes contenido, "Ana López"
    assert_includes contenido, "Entrenamiento"
    assert_includes contenido, "Tenis"
    assert_includes contenido, "12/09/2026"
    assert_includes contenido, "10:00"
    assert_includes contenido, "Confirmada"
  end
end
