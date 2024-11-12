class AddFieldsToVideoChapters < ActiveRecord::Migration[7.1]
  def change
    add_column :video_chapters, :slide_color, :string
    add_column :video_chapters, :text_family, :string
    add_column :video_chapters, :text_style, :string
    add_column :video_chapters, :text_size, :integer
  end
end
