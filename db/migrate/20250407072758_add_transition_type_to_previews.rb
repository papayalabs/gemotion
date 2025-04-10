class AddTransitionTypeToPreviews < ActiveRecord::Migration[7.1]
  def change
    add_column :previews, :transition_type, :string
  end
end
