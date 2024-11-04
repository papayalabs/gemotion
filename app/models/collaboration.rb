class Collaboration < ApplicationRecord
  belongs_to :video
  belongs_to :inviting_user, class_name: 'User'
  belongs_to :invited_user, class_name: 'User', optional: true

  validates :invited_email, presence: true
end