class CreateCollaborations < ActiveRecord::Migration[7.1]
  def change
    create_table :collaborations do |t|
      t.references :video, null: false, foreign_key: true
      t.references :inviting_user, null: false, foreign_key: { to_table: :users }
      t.references :invited_user, foreign_key: { to_table: :users }
      t.string :invited_email, null: false

      t.timestamps
    end
  end
end
