require "open3"

class MusicProcessingJob < ApplicationJob
  queue_as :default

  sidekiq_options retry: false

  def perform(chapter_class_name, chapter_id, file_path)
    chapter_class = chapter_class_name.constantize
    chapter = chapter_class.find(chapter_id)

    # Ensure the file exists
    unless File.exist?(file_path)
      Rails.logger.error "File not found: #{file_path}"
      return
    end

    # Temporary path for waveform JSON, including class name to avoid collisions
    sanitized_class_name = chapter_class_name.underscore
    waveform_json_path = Rails.root.join("tmp", "waveform_#{sanitized_class_name}_#{chapter_id}.json")

    # Generate waveform JSON using audiowaveform
    command = <<~CMD
      audiowaveform -i "#{file_path}" -o "#{waveform_json_path}" --pixels-per-second 50 --bits 8
    CMD

    stdout, stderr, status = Open3.capture3(command)

    if status.success?
      Rails.logger.info "Waveform successfully generated for #{chapter_class_name} ID #{chapter_id}"

      # Read and parse the generated waveform JSON
      waveform_data = File.read(waveform_json_path)
      chapter.update!(waveform: JSON.parse(waveform_data))

      Rails.logger.info "Waveform data saved for #{chapter_class_name} ID #{chapter_id}"
    else
      Rails.logger.error "Failed to generate waveform for #{chapter_class_name} ID #{chapter_id}: #{stderr}"
    end
  ensure
    # Cleanup temporary files
    File.delete(file_path) if File.exist?(file_path)
    File.delete(waveform_json_path) if File.exist?(waveform_json_path)
  end
end
