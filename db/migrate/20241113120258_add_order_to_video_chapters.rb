class AddOrderToVideoChapters < ActiveRecord::Migration[7.1]
  def change
    add_column :video_chapters, :order, :integer
  end
end
