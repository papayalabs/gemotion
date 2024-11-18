class AddMoreOrdersToVideoChapters < ActiveRecord::Migration[7.1]
  def change
    add_column :video_chapters, :videos_order, :string, default: ''
    add_column :video_chapters, :photos_order, :string, default: ''
  end
end
