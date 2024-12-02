class AddWaveformToMusics < ActiveRecord::Migration[7.1]
  def change
    add_column :musics, :waveform, :json
  end
end
