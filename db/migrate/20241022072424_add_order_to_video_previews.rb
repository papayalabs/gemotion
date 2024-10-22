class AddOrderToVideoPreviews < ActiveRecord::Migration[7.1]
  def change
    add_column :video_previews, :order, :integer
  end
end
