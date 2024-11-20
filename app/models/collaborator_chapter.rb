class CollaboratorChapter < ApplicationRecord
  include ChapterSharedBehavior

  # Additional relationships specific to CollaboratorChapter
  belongs_to :collaboration
  has_one :collaborator_user, through: :collaboration, source: :invited_user

  # Optional: Validation for collaboration
  validates :collaboration, presence: true
end
