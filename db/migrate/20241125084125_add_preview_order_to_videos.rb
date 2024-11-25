class AddPreviewOrderToVideos < ActiveRecord::Migration[7.1]
  def change
    add_column :videos, :previews_order, :text, array: true, default: []
  end
end
