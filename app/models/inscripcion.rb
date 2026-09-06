class Inscripcion < ApplicationRecord
  ESTADOS = %w[pendiente confirmada cancelada].freeze
  ESTADOS_ACTIVOS = %w[pendiente confirmada].freeze

  belongs_to :deportista
  belongs_to :actividad

  before_validation :establecer_fecha_inscripcion, on: :create

  validates :deportista, presence: true
  validates :actividad, presence: true
  validates :fecha_inscripcion, presence: true
  validates :estado, presence: true, inclusion: { in: ESTADOS }

  validate :unica_inscripcion_activa, if: :activa?
  validate :verificar_cupo_disponible, if: :activa?

  scope :activas, -> { where(estado: ESTADOS_ACTIVOS) }
  scope :canceladas, -> { where(estado: "cancelada") }

  def activa?
    ESTADOS_ACTIVOS.include?(estado)
  end

  def cancelada?
    estado == "cancelada"
  end

  def cancelar!
    update!(estado: "cancelada")
  end

  def confirmar!
    update!(estado: "confirmada")
  end

  private

  def establecer_fecha_inscripcion
    self.fecha_inscripcion ||= Date.current
  end

  def unica_inscripcion_activa
    return unless deportista_id && actividad_id

    inscripciones = Inscripcion.activas.where(deportista_id: deportista_id, actividad_id: actividad_id)
    inscripciones = inscripciones.where.not(id: id) if persisted?

    if inscripciones.exists?
      errors.add(:base, "El deportista ya cuenta con una inscripción activa en esta actividad")
    end
  end

  def verificar_cupo_disponible
    return unless actividad

    activas_existentes = actividad.inscripciones.activas
    activas_existentes = activas_existentes.where.not(id: id) if persisted?

    if activas_existentes.count >= actividad.cupo
      errors.add(:base, "La actividad ha alcanzado su cupo máximo")
    end
  end
end
