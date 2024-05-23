class CreateChapterTypes < ActiveRecord::Migration[7.1]
  def change
    create_table :chapter_types do |t|
      t.string :name

      t.timestamps
    end
  end
end
