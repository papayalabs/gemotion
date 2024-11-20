class CreateCollaboratorChapters < ActiveRecord::Migration[7.1]
  def change
    create_table :collaborator_chapters do |t|
      t.string :text, null: false
      t.string :videos_order, default: ""
      t.string :photos_order, default: ""
      t.json :ordered_videos_ids, default: []
      t.json :ordered_images_ids, default: []
      t.string :slide_color
      t.string :text_family
      t.string :text_style
      t.integer :text_size
      t.integer :order

      t.references :chapter_type, null: false, foreign_key: true
      t.references :video, null: false, foreign_key: true
      t.references :collaboration, null: false, foreign_key: true

      t.timestamps
    end
  end
end
