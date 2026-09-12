class InscripcionMailer < ApplicationMailer
  def confirmacion(inscripcion)
    @inscripcion = inscripcion
    @deportista = inscripcion.deportista
    @socio = @deportista.socio
    @actividad = inscripcion.actividad

    mail(
      to: @socio.email,
      subject: "Confirmación de inscripción a #{@actividad.nombre}"
    )
  end
end
