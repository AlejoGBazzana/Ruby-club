class Deporte < ApplicationRecord
  has_and_belongs_to_many :deportistas
  has_many :actividades, dependent: :restrict_with_error

  validates :nombre, presence: true,
                     uniqueness: { case_sensitive: false }
end
