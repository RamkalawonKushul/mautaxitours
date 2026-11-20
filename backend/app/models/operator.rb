class Operator < ApplicationRecord
  has_many :operator_assignments, dependent: :restrict_with_error

  validates :name, presence: true
  validates :email, format: { with: URI::MailTo::EMAIL_REGEXP }, allow_blank: true

  scope :active, -> { where(active: true).order(:name) }
end
