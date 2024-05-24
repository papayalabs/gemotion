class AddDedicaceToVideo < ActiveRecord::Migration[7.1]
  def change
    add_reference :videos, :dedicace, foreign_key: true
  end
end
