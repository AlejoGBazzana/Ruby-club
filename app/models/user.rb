require "digest"
require "securerandom"

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

  def generate_api_token!
    token = SecureRandom.urlsafe_base64(48)
    update!(api_token_digest: self.class.digest_api_token(token))
    token
  end

  def invalidate_api_token!
    update!(api_token_digest: nil)
  end

  def self.authenticate_api_token(token)
    return if token.blank?

    find_by(api_token_digest: digest_api_token(token))
  end

  def self.digest_api_token(token)
    Digest::SHA256.hexdigest(token)
  end
end
