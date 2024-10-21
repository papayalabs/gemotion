class CreateVideoPreviews < ActiveRecord::Migration[7.1]
  def change
    create_table :video_previews do |t|
      t.references :preview, null: false, foreign_key: true
      t.references :video, null: false, foreign_key: true

      t.timestamps
    end
  end
end
