class User < ApplicationRecord
  # Include default devise modules. Others available are:
  # :confirmable, :lockable, :timeoutable, :trackable and :omniauthable
  devise :database_authenticatable, :registerable,
         :recoverable, :rememberable, :validatable

  has_many :videos, dependent: :destroy
  validates :first_name, presence: true
  validates :last_name, presence: true
  validates :phone, presence: true

  def full_name
    "#{first_name} #{last_name}".strip if first_name.present? || last_name.present?
  end

end
