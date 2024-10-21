class CreateVideoMusics < ActiveRecord::Migration[7.1]
  def change
    create_table :video_musics do |t|
      t.references :music, null: false, foreign_key: true
      t.references :video, null: false, foreign_key: true

      t.timestamps
    end
  end
end
