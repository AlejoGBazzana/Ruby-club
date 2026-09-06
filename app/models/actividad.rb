class Actividad < ApplicationRecord
  belongs_to :deporte
  has_many :inscripciones, dependent: :restrict_with_error
  has_many :deportistas, through: :inscripciones

  validates :nombre, presence: true
  validates :fecha, presence: true
  validates :horario, presence: true
  validates :cupo, presence: true,
                   numericality: { only_integer: true, greater_than: 0 }

  def inscripciones_activas
    inscripciones.activas
  end

  def cantidad_inscripciones_activas
    if inscripciones.loaded?
      inscripciones.count(&:activa?)
    else
      inscripciones.activas.count
    end
  end

  def cupo_disponible
    return 0 unless cupo

    [cupo - cantidad_inscripciones_activas, 0].max
  end

  def completa?
    return true unless cupo

    cantidad_inscripciones_activas >= cupo
  end
end
