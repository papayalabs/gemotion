require "open3"
require "shellwords"
class RemoveBackgroundJob < ApplicationJob
  queue_as :default

  def perform(video_dedicace_slot_id, input_path, slot_number)
    video_dedicace_slot = VideoDedicaceSlot.find(video_dedicace_slot_id)

    Rails.logger.info("Processing video #{video_dedicace_slot.video_dedicace.id} with slot number #{slot_number}")

    # Create temporary paths
    timestamp = Time.now.to_i
    converted_path = Rails.root.join("tmp", "converted_video_#{video_dedicace_slot_id}_#{slot_number}_#{timestamp}.mp4")
    output_path = Rails.root.join("tmp", "processed_video_#{video_dedicace_slot_id}_#{slot_number}_#{timestamp}.mp4")

    Rails.logger.info("Input path: #{input_path}")
    Rails.logger.info("Converted path: #{converted_path}")
    Rails.logger.info("Output path: #{output_path}")

    # First convert WebM to MP4 with optimized settings
    Rails.logger.info("Converting WebM to MP4")
    convert_result = system("ffmpeg -i #{Shellwords.escape(input_path)} " \
                          "-c:v libx264 " \
                          "-preset veryfast " \
                          "-crf 23 " \
                          "-tune zerolatency " \
                          "-movflags +faststart " \
                          "-c:a aac " \
                          "-ac 2 " \
                          "-b:a 128k " \
                          "-y " \
                          "#{Shellwords.escape(converted_path)}")

    unless convert_result
      Rails.logger.error("Failed to convert WebM to MP4")
      return {
        success: false,
        errors: ["Failed to convert video format"]
      }
    end

    unless File.exist?(converted_path)
      Rails.logger.error("Converted video file not created")
      return {
        success: false,
        errors: ["Converted video file not created"]
      }
    end

    # Call Python script with the correct Python environment
    python_script = Rails.root.join("lib/scripts/remove_background.py")

    # Use the system Python or the virtual environment Python
    python_path = if File.exist?(Rails.root.join("venv/bin/python"))
                    Rails.root.join("venv/bin/python").to_s
                  else
                    "python3"
                  end

    # Execute the Python script and capture output
    Rails.logger.info("Executing Python script")
    result = system("#{python_path} #{python_script} #{Shellwords.escape(converted_path)} #{Shellwords.escape(output_path)}")

    Rails.logger.info("Result: #{result}")

    unless result
      Rails.logger.error("Failed to process video with Python script")
      return {
        success: false,
        errors: ["Failed to process video"]
      }
    end

    unless File.exist?(output_path)
      Rails.logger.error("Output video file not created")
      return {
        success: false,
        errors: ["Output video file not created"]
      }
    end

    begin
      # Attach processed video to video_dedicace
      video_dedicace_slot.video.attach(
        io: File.open(output_path),
        filename: "processed_video_#{slot_number}_#{timestamp}.mp4",
        content_type: "video/mp4"
      )

      # Generate preview from first frame and remove green background
      preview_path = Rails.root.join("tmp", "preview_#{video_dedicace_slot_id}_#{slot_number}_#{timestamp}.png")
      preview_result = system("ffmpeg -i #{output_path} -vframes 1 -vf \"chromakey=0x00FF00:0.1:0.2\" -f image2 -update 1 #{preview_path}")

      unless preview_result
        Rails.logger.error("Failed to generate preview")
        return {
          success: false,
          errors: ["Failed to generate preview"]
        }
      end

      if File.exist?(preview_path)
        video_dedicace_slot.preview.attach(
          io: File.open(preview_path),
          filename: "preview_#{slot_number}_#{timestamp}.png",
          content_type: "image/png"
        )
      end

      # Clean up temporary files
      File.delete(input_path) if File.exist?(input_path)
      File.delete(converted_path) if File.exist?(converted_path)
      File.delete(output_path) if File.exist?(output_path)
      File.delete(preview_path) if File.exist?(preview_path)

      # Get the host from Rails configuration
      host = Rails.application.config.action_mailer.default_url_options[:host]

      # Create URLs with the host
      video_url = video_dedicace_slot.video.attached? ? Rails.application.routes.url_helpers.url_for(video_dedicace_slot.video) : nil
      preview_url = video_dedicace_slot.preview.attached? ? Rails.application.routes.url_helpers.url_for(video_dedicace_slot.preview) : nil

      video_dedicace_slot.save!

      {
        success: true,
        video_url:,
        preview_url:
      }
    rescue StandardError => e
      Rails.logger.error("Error in video processing: #{e.message}")
      {
        success: false,
        errors: ["Error processing video: #{e.message}"]
      }
    end
  end
end
