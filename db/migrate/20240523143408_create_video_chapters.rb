class CreateVideoChapters < ActiveRecord::Migration[7.1]
  def change
    create_table :video_chapters do |t|
      t.references :chapter_type, null: false, foreign_key: true
      t.references :video, null: false, foreign_key: true
      t.text :text, null: false

      t.timestamps
    end
  end
end
