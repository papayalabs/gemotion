class AddMusicTypeToVideo < ActiveRecord::Migration[7.1]
  def change
    add_column :videos, :music_type, :integer, default: 0, null: false
  end
end
