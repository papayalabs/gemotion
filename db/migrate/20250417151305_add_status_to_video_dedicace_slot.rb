class AddStatusToVideoDedicaceSlot < ActiveRecord::Migration[7.1]
  def change
    add_column :video_dedicace_slots, :status, :string
  end
end
