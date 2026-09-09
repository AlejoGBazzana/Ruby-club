class Socio < ApplicationRecord
  has_one :deportista, dependent: :restrict_with_error
  has_one :user, dependent: :nullify

  before_validation :establecer_fecha_inscripcion, on: :create

  validates :nombre, presence: true
  validates :apellido, presence: true
  validates :email, presence: true,
                    uniqueness: { case_sensitive: false },
                    format: { with: URI::MailTo::EMAIL_REGEXP }
  validates :fecha_inscripcion, presence: true

  def nombre_completo
    "#{nombre} #{apellido}".strip
  end

  private

  def establecer_fecha_inscripcion
    self.fecha_inscripcion ||= Date.current
  end
end
