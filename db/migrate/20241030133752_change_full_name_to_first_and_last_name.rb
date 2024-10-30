class ChangeFullNameToFirstAndLastName < ActiveRecord::Migration[7.1]
  def change
    # Remove the full_name column
    remove_column :users, :full_name, :string

    # Add first_name and last_name columns
    add_column :users, :first_name, :string
    add_column :users, :last_name, :string
  end
end
