class CollaboratorChapter < ApplicationRecord
  include ChapterSharedBehavior

  scope :approved, -> { where(approved_by_creator: true) }
  scope :pending_approval, -> { where(approved_by_creator: false) }

  # Additional relationships specific to CollaboratorChapter
  belongs_to :collaboration
  has_one :collaborator_music, dependent: :destroy
  has_one :collaborator_user, through: :collaboration, source: :invited_user

  # Optional: Validation for collaboration
  validates :collaboration, presence: true
  before_destroy :remove_collaborator_music

  private

  def remove_collaborator_music
    collaborator_music&.destroy
  end
end
