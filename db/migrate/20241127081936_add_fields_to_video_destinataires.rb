class AddFieldsToVideoDestinataires < ActiveRecord::Migration[7.1]
  def change
    add_column :video_destinataires, :passions_and_hobbies, :text
    add_column :video_destinataires, :personality_description, :text
    add_column :video_destinataires, :favorite_quotes, :text
  end
end
