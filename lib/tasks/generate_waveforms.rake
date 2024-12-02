namespace :music do
  desc "Generate waveform data for music files"

  task generate_waveforms: :environment do
    require 'open3'

    Music.where(waveform: nil).each do |music|
      next unless music.music.attached?

      music_file_path = Rails.root.join("tmp", "audio_#{music.id}.mp3")
      waveform_json_path = Rails.root.join("tmp", "waveform_#{music.id}.json")

      # Download the attached file to a temporary location
      File.open(music_file_path, 'wb') do |file|
        file.write(music.music.download)
      end

      # Generate waveform JSON using audiowaveform
      command = <<~CMD
        audiowaveform -i "#{music_file_path}" -o "#{waveform_json_path}" --pixels-per-second 50 --bits 8
      CMD

      stdout, stderr, status = Open3.capture3(command)
      p stdout
      p stderr
      if status.success?
        puts "Waveform generated for music ID #{music.id}"

        # Read JSON file and store it in the database
        waveform_data = File.read(waveform_json_path)
        music.update!(waveform: JSON.parse(waveform_data))
      else
        puts "Failed to generate waveform for music ID #{music.id}: #{stderr}"
      end

      # Cleanup temporary files
      File.delete(music_file_path) if File.exist?(music_file_path)
      File.delete(waveform_json_path) if File.exist?(waveform_json_path)
    end
  end
end