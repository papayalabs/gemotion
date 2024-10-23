class AddOrderToVideoChapterAttachments < ActiveRecord::Migration[7.1]
  def change
    add_column :video_chapters, :ordered_videos_ids, :json, default: []
    add_column :video_chapters, :ordered_images_ids, :json, default: []
  end
end
