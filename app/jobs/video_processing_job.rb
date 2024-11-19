class VideoProcessingJob < ApplicationJob
  queue_as :default

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

    # Step 1: Reprocess video to MP4 with H.264 codec and AAC audio
    system(<<~CMD.squish)
      ffmpeg -y -i #{Shellwords.escape(input_path)} \
      -c:v libx264 -pix_fmt yuv420p -preset fast -crf 23 \
      -c:a aac -ar 44100 -r 30 \
      -movflags +faststart \
      #{Shellwords.escape(temp_output_path)}
    CMD
    p "+" * 100 + "duration" + "+" * 100
    # Step 1: Get the duration of the primary video
    video_duration = `ffprobe -i #{Shellwords.escape(temp_output_path)} -show_entries format=duration -v quiet -of csv="p=0"`.strip
    p video_duration
    p "+" * 100 + "duration" + "+" * 100

    # Step 2: Apply overlay with transparency and correct labeling
    system(<<~CMD.squish)
      ffmpeg -y -i #{Shellwords.escape(temp_output_path)} \
      -i #{Shellwords.escape(theme_video_path)} \
      -filter_complex "\
        [1]format=rgba,colorchannelmixer=aa=0.3[overlay]; \
        [0][overlay]overlay=0:0:format=auto,trim=duration=#{video_duration}[v]" \
      -map "[v]" -map 0:a -c:v libx264 -c:a aac -ar 44100 -shortest -movflags +faststart \
      #{Shellwords.escape(overlay_output_path)}
    CMD

    # Step 3: Replace the uploaded file with the final video with overlay
    video.blob.open do |file|
      File.open(overlay_output_path) do |processed_file|
        video.attach(io: processed_file, filename: "#{video.filename.base}.mp4", content_type: "video/mp4")
      end
    end

    # # Clean up temporary files
    [temp_output_path, overlay_output_path].each do |path|
      File.delete(path) if File.exist?(path)
    end
  end
end
    # system("ffmpeg -y -i #{Shellwords.escape(temp_output_path)} -i #{Shellwords.escape(theme_video_path)} -filter_complex \"[1]format=rgba,colorchannelmixer=aa=0.3[overlay];[0][overlay]overlay=0:0:format=auto,format=yuv420p,trim=duration=#{video_duration}\" -c:a copy #{Shellwords.escape(overlay_output_path)}")
