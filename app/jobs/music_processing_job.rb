require 'open3'

class MusicProcessingJob < ApplicationJob
  queue_as :default

  sidekiq_options retry: false

  def perform(video_chapter_id, file_path)
    video_chapter = VideoChapter.find(video_chapter_id)

    # Ensure the file exists
    unless File.exist?(file_path)
      Rails.logger.error "File not found: #{file_path}"
      return
    end

    waveform_json_path = Rails.root.join("tmp", "waveform_#{video_chapter_id}.json")

    # Generate waveform JSON using audiowaveform
    command = <<~CMD
      audiowaveform -i "#{file_path}" -o "#{waveform_json_path}" --pixels-per-second 50 --bits 8
    CMD

    stdout, stderr, status = Open3.capture3(command)

    if status.success?
      Rails.logger.info "Waveform successfully generated for VideoChapter ID #{video_chapter_id}"

      # Read and parse the generated waveform JSON
      waveform_data = File.read(waveform_json_path)
      video_chapter.update!(waveform: JSON.parse(waveform_data))

      Rails.logger.info "Waveform data saved for VideoChapter ID #{video_chapter_id}"
    else
      Rails.logger.error "Failed to generate waveform for VideoChapter ID #{video_chapter_id}: #{stderr}"
    end
  ensure
    # Cleanup temporary files
    File.delete(file_path) if File.exist?(file_path)
    File.delete(waveform_json_path) if File.exist?(waveform_json_path)
  end
end