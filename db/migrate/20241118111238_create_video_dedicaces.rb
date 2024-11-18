class CreateVideoDedicaces < ActiveRecord::Migration[7.1]
  def change
    create_table :video_dedicaces do |t|
      t.references :dedicace, null: false, foreign_key: true
      t.references :video, null: false, foreign_key: true
      t.string :car_position
      t.timestamps
    end
  end
end
