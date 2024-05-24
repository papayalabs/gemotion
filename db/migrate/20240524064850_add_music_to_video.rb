class AddMusicToVideo < ActiveRecord::Migration[7.1]
  def change
    add_reference :videos, :music, foreign_key: true
  end
end
