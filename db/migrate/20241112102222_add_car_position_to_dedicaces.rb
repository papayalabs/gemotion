class AddCarPositionToDedicaces < ActiveRecord::Migration[7.1]
  def change
    add_column :dedicaces, :car_position, :string
  end
end
