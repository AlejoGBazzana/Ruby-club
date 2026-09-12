class Socio < ApplicationRecord
  has_one :deportista, dependent: :restrict_with_error
  has_one :user, dependent: :nullify
  has_one_attached :foto_perfil

  TIPOS_DE_FOTO_PERFIL_PERMITIDOS = %w[image/jpeg image/png image/webp].freeze
  TAMANO_MAXIMO_FOTO_PERFIL = 5.megabytes

  before_validation :establecer_fecha_inscripcion, on: :create

  validates :nombre, presence: true
  validates :apellido, presence: true
  validates :email, presence: true,
                    uniqueness: { case_sensitive: false },
                    format: { with: URI::MailTo::EMAIL_REGEXP }
  validates :fecha_inscripcion, presence: true
  validate :foto_perfil_valida

  def nombre_completo
    "#{nombre} #{apellido}".strip
  end

  private

  def foto_perfil_valida
    return unless foto_perfil.attached?

    if foto_perfil.blob.byte_size > TAMANO_MAXIMO_FOTO_PERFIL
      errors.add(:foto_perfil, "debe pesar como máximo 5 MB")
    end

    unless TIPOS_DE_FOTO_PERFIL_PERMITIDOS.include?(foto_perfil.blob.content_type)
      errors.add(:foto_perfil, "debe ser una imagen JPEG, PNG o WebP")
    end
  end

  def establecer_fecha_inscripcion
    self.fecha_inscripcion ||= Date.current
  end
end
