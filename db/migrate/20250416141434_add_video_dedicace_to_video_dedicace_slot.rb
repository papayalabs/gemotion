class AddVideoDedicaceToVideoDedicaceSlot < ActiveRecord::Migration[7.1]
  def change
    add_reference :video_dedicace_slots, :video_dedicace, null: false, foreign_key: true
  end
end
