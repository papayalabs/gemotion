class AddSpecialRequestMusicToVideo < ActiveRecord::Migration[7.1]
  def change
    add_column :videos, :special_request_music, :text
  end
end
