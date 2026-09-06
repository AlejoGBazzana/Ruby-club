puts "Iniciando carga de seeds..."

# Limpieza ordenada previa para permitir re-ejecución limpia
Inscripcion.delete_all
Actividad.delete_all
ActiveRecord::Base.connection.execute("DELETE FROM deportes_deportistas")
Deportista.delete_all
Deporte.delete_all
Socio.delete_all

# 1. Socios
puts "Creando socios..."
socio_juan = Socio.create!(
  nombre: "Juan",
  apellido: "Pérez",
  email: "juan.perez@club.com",
  fecha_inscripcion: 6.months.ago.to_date
)

socio_maria = Socio.create!(
  nombre: "María",
  apellido: "González",
  email: "maria.gonzalez@club.com",
  fecha_inscripcion: 4.months.ago.to_date
)

socio_carlos = Socio.create!(
  nombre: "Carlos",
  apellido: "Tevez",
  email: "carlos.tevez@club.com",
  fecha_inscripcion: 3.months.ago.to_date
)

socio_lucia = Socio.create!(
  nombre: "Lucía",
  apellido: "Fernández",
  email: "lucia.fernandez@club.com",
  fecha_inscripcion: 2.months.ago.to_date
)

# Socios que no son deportistas (socios sociales/adherentes)
socio_social1 = Socio.create!(
  nombre: "Roberto",
  apellido: "Sánchez",
  email: "roberto.sanchez@club.com",
  fecha_inscripcion: 1.year.ago.to_date
)

socio_social2 = Socio.create!(
  nombre: "Patricia",
  apellido: "Benítez",
  email: "patricia.benitez@club.com",
  fecha_inscripcion: 1.month.ago.to_date
)

# 2. Deportes
puts "Creando deportes..."
futbol = Deporte.create!(nombre: "Fútbol")
tenis = Deporte.create!(nombre: "Tenis")
natacion = Deporte.create!(nombre: "Natación")
basquet = Deporte.create!(nombre: "Básquetbol")
padel = Deporte.create!(nombre: "Pádel")

# 3. Deportistas (asociados obligatoriamente a un socio)
puts "Creando deportistas y vinculando a deportes..."
deportista_juan = Deportista.create!(socio: socio_juan, edad: 28)
deportista_maria = Deportista.create!(socio: socio_maria, edad: 24)
deportista_carlos = Deportista.create!(socio: socio_carlos, edad: 35)
deportista_lucia = Deportista.create!(socio: socio_lucia, edad: 19)

# Relaciones N:M Deportista - Deporte
deportista_juan.deportes << [futbol, padel]
deportista_maria.deportes << [tenis, natacion]
deportista_carlos.deportes << [futbol, basquet]
deportista_lucia.deportes << [natacion, tenis]

# 4. Actividades
puts "Creando actividades..."
# Caso A: Con cupo disponible (cupo 5, 2 activas)
clase_natacion = Actividad.create!(
  nombre: "Natación Adultos - Inicial",
  fecha: Date.current + 7.days,
  horario: Time.parse("10:00:00"),
  cupo: 5,
  deporte: natacion
)

# Caso B: Actividad completa (cupo 2, 2 activas)
torneo_tenis = Actividad.create!(
  nombre: "Torneo de Tenis Dobles",
  fecha: Date.current + 10.days,
  horario: Time.parse("14:30:00"),
  cupo: 2,
  deporte: tenis
)

# Caso C: Para probar cancelación y reinscripción posterior (cupo 3)
entrenamiento_futbol = Actividad.create!(
  nombre: "Práctica de Fútbol Masculino",
  fecha: Date.current + 3.days,
  horario: Time.parse("18:00:00"),
  cupo: 3,
  deporte: futbol
)

# 5. Inscripciones con diversos estados
puts "Creando inscripciones..."

# En Natación: 1 confirmada, 1 pendiente -> Cupo disponible = 3
Inscripcion.create!(
  deportista: deportista_maria,
  actividad: clase_natacion,
  fecha_inscripcion: 2.days.ago.to_date,
  estado: "confirmada"
)

Inscripcion.create!(
  deportista: deportista_lucia,
  actividad: clase_natacion,
  fecha_inscripcion: 1.day.ago.to_date,
  estado: "pendiente"
)

# En Torneo de Tenis: 2 activas -> Cupo completo
Inscripcion.create!(
  deportista: deportista_maria,
  actividad: torneo_tenis,
  fecha_inscripcion: 3.days.ago.to_date,
  estado: "confirmada"
)

Inscripcion.create!(
  deportista: deportista_lucia,
  actividad: torneo_tenis,
  fecha_inscripcion: 2.days.ago.to_date,
  estado: "pendiente"
)

# En Fútbol: Demostración de cancelación y reinscripción
# Carlos se inscribió hace 5 días y canceló
Inscripcion.create!(
  deportista: deportista_carlos,
  actividad: entrenamiento_futbol,
  fecha_inscripcion: 5.days.ago.to_date,
  estado: "cancelada"
)

# Carlos se reinscribe ayer (válido porque la anterior está cancelada)
Inscripcion.create!(
  deportista: deportista_carlos,
  actividad: entrenamiento_futbol,
  fecha_inscripcion: 1.day.ago.to_date,
  estado: "confirmada"
)

# Juan se inscribe hoy en fútbol
Inscripcion.create!(
  deportista: deportista_juan,
  actividad: entrenamiento_futbol,
  fecha_inscripcion: Date.current,
  estado: "pendiente"
)

puts "=== Seeds cargados con éxito ==="
puts "- Socios creados: #{Socio.count} (#{Deportista.count} son deportistas, #{Socio.count - Deportista.count} son solo socios)"
puts "- Deportes creados: #{Deporte.count}"
puts "- Deportistas creados: #{Deportista.count}"
puts "- Actividades creadas: #{Actividad.count}"
puts "- Inscripciones totales: #{Inscripcion.count} (#{Inscripcion.activas.count} activas, #{Inscripcion.canceladas.count} canceladas)"
puts "  * Natación: #{clase_natacion.cantidad_inscripciones_activas}/#{clase_natacion.cupo} (Disponible: #{clase_natacion.cupo_disponible}, Completa: #{clase_natacion.completa?})"
puts "  * Torneo Tenis: #{torneo_tenis.cantidad_inscripciones_activas}/#{torneo_tenis.cupo} (Disponible: #{torneo_tenis.cupo_disponible}, Completa: #{torneo_tenis.completa?})"
puts "  * Fútbol: #{entrenamiento_futbol.cantidad_inscripciones_activas}/#{entrenamiento_futbol.cupo} (1 cancelada + 2 activas con reinscripción exitosa)"
