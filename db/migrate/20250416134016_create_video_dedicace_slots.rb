class CreateVideoDedicaceSlots < ActiveRecord::Migration[7.1]
  def change
    create_table :video_dedicace_slots do |t|
      t.integer :slot

      t.timestamps
    end
  end
end
