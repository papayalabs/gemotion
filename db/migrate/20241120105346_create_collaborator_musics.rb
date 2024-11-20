class CreateCollaboratorMusics < ActiveRecord::Migration[7.1]
  def change
    create_table :collaborator_musics do |t|
      t.references :music, null: false, foreign_key: true
      t.references :collaborator_chapter, foreign_key: true

      t.timestamps
    end
  end
end
