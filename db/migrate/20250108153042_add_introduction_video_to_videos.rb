class AddIntroductionVideoToVideos < ActiveRecord::Migration[7.1]
  def change
    add_column :videos, :introduction_video, :integer, default: 0, null: false
  end
end
