class Deportista < ApplicationRecord
  belongs_to :socio
  has_and_belongs_to_many :deportes
  has_many :inscripciones, dependent: :restrict_with_error
  has_many :actividades, through: :inscripciones

  validates :edad, presence: true,
                   numericality: { only_integer: true, greater_than_or_equal_to: 0 }
  validates :socio_id, uniqueness: true

  delegate :nombre, :apellido, :email, :fecha_inscripcion, to: :socio, allow_nil: true

  def nombre_completo
    socio&.nombre_completo
  end
end
