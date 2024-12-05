class AddWaveformToCollaboratorChapters < ActiveRecord::Migration[7.1]
  def change
    add_column :collaborator_chapters, :waveform, :json
  end
end
