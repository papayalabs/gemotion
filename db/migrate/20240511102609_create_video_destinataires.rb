class CreateVideoDestinataires < ActiveRecord::Migration[7.1]
  def change
    create_table :video_destinataires do |t|
      t.integer :genre
      t.integer :age
      t.string :name
      t.text :more_info
      t.references :video, null: false, foreign_key: true
      t.text :specific_request

      t.timestamps
    end
  end
end
