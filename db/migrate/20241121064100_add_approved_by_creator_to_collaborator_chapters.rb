class AddApprovedByCreatorToCollaboratorChapters < ActiveRecord::Migration[7.1]
  def change
    add_column :collaborator_chapters, :approved_by_creator, :boolean, default: false, null: false
  end
end
