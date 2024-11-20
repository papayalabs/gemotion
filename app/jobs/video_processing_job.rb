require 'open3'
require 'shellwords'
class VideoProcessingJob < ApplicationJob
  queue_as :default

  sidekiq_options retry: false


  def perform(id)
    video_dedicace = VideoDedicace.find(id)
    video = video_dedicace.creator_end_dedication_video
    dedicace = video_dedicace.dedicace.video
    return unless video.attached?

    # Paths to the uploaded files
    input_path = ActiveStorage::Blob.service.path_for(video.blob.key)
    theme_video_path = ActiveStorage::Blob.service.path_for(dedicace.blob.key)
    temp_output_path = "#{Rails.root}/tmp/#{SecureRandom.uuid}.mp4"
    overlay_output_path = "#{Rails.root}/tmp/#{SecureRandom.uuid}_overlay.mp4"
    transparent_video_path = "#{Rails.root}/tmp/#{SecureRandom.uuid}_transparent.mp4"
    # output_video_path = "#{Rails.root}/tmp/#{SecureRandom.uuid}_processed_video.mp4"

    # Step 1: Reprocess video to MP4 with H.264 codec and AAC audio
    system(<<~CMD.squish)
      ffmpeg -y -i #{Shellwords.escape(input_path)} \
      -c:v libx264 -pix_fmt yuv420p -preset fast -crf 23 \
      -c:a aac -ar 44100 -r 30 \
      -movflags +faststart \
      #{Shellwords.escape(temp_output_path)}
    CMD

    p "+" * 100 + "python" + "+" * 100
    python_script = "#{Rails.root}/lib/python/process_video.py"

    # Run Python script and capture output
    stdout, stderr, status = Open3.capture3("python3.10 #{python_script} #{Shellwords.escape(temp_output_path)} #{Shellwords.escape(transparent_video_path)} #{Shellwords.escape(theme_video_path)}")

    # Check if the Python script ran successfully
    if status.success? && File.exist?(transparent_video_path)
      # Attach processed video
      video.blob.open do |file|
        File.open(transparent_video_path) do |processed_file|
          video.attach(io: processed_file, filename: "#{video.filename.base}.mp4", content_type: "video/mp4")
        end
      end
    else
      # Handle error from Python script
      raise "Python script failed: #{stderr}"
    end

    # Clean up temporary files
    [temp_output_path, overlay_output_path, transparent_video_path].each do |path|
      File.delete(path) if File.exist?(path)
    end
  end
end
