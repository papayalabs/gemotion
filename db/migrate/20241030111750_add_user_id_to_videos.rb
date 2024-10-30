class AddUserIdToVideos < ActiveRecord::Migration[7.1]
  def change
    add_reference :videos, :user, null: false, foreign_key: true, index: true
  end
end
