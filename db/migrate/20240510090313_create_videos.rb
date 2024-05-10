class CreateVideos < ActiveRecord::Migration[7.1]
  def change
    create_table :videos do |t|
      t.integer :video_type, null: false
      t.string :stop_at, null: false, default: 'start'
      t.integer :occasion

      t.timestamps
    end
  end
end
