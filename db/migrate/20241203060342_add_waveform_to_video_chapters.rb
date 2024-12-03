class AddWaveformToVideoChapters < ActiveRecord::Migration[7.1]
  def change
    add_column :video_chapters, :waveform, :json
  end
end
