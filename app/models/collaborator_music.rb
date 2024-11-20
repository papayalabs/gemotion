class CollaboratorMusic < ApplicationRecord
  belongs_to :music
  belongs_to :collaborator_chapter, optional: true
end
