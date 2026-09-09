class User < ApplicationRecord
  # Include default devise modules. Others available are:
  # :confirmable, :lockable, :timeoutable, :trackable and :omniauthable
  devise :database_authenticatable, :registerable,
         :recoverable, :rememberable, :validatable

  ROLES = %w[admin superadmin user].freeze

  enum :role, { user: "user", admin: "admin", superadmin: "superadmin" }, default: :user, validate: true

  belongs_to :socio, optional: true

  validates :role, presence: true, inclusion: { in: ROLES }

  def administrative?
    admin? || superadmin?
  end

  def can_access_admin?
    administrative?
  end
end
