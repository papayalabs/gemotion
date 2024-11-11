class AddTitleDescriptionToVideo < ActiveRecord::Migration[7.1]
  def change
    add_column :videos, :title, :string
    add_column :videos, :description, :string
  end
end
