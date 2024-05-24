class CreateVideos < ActiveRecord::Migration[7.1]
  def change
    create_table :videos do |t|
      t.integer :video_type, null: false
      t.string :stop_at, null: false, default: 'start'
      t.integer :occasion
      t.datetime :end_date
      t.integer :theme
      t.text :theme_specific_request
      t.string :token

      t.text :music_specific_request
      t.text :dedicace_specific_request
      
      t.timestamps
    end
  end
end
