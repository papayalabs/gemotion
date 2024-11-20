class User < ApplicationRecord
  # Include default devise modules. Others available are:
  # :confirmable, :lockable, :timeoutable, :trackable and :omniauthable
  devise :database_authenticatable, :registerable,
         :recoverable, :rememberable, :validatable

  has_many :videos, dependent: :destroy
  has_many :invitations, class_name: 'Collaboration', foreign_key: 'inviting_user_id', dependent: :destroy
  has_many :collaborations, class_name: 'Collaboration', foreign_key: 'invited_user_id', dependent: :destroy
  has_one :collaborator_dedicace, through: :collaborations
  has_many :collaborator_chapters, through: :collaborations

  validates :first_name, presence: true
  validates :last_name, presence: true
  validates :phone, presence: true

  def full_name
    "#{first_name} #{last_name}".strip if first_name.present? || last_name.present?
  end

end
