class CreateDedicaceContents < ActiveRecord::Migration[7.1]
  def change
    create_table :dedicace_contents do |t|
      t.references :video, null: false, foreign_key: true
      t.integer :position

      t.timestamps
    end
  end
end
