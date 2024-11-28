namespace :videos do
  desc "Generate image previews for videos in app/assets/videos/previews"
  task generate_previews: :environment do
    require "fileutils"

    video_dir = Rails.root.join("app/assets/videos/previews")
    preview_dir = Rails.root.join("app/assets/images/previews")

    FileUtils.mkdir_p(preview_dir) # Ensure the output directory exists

    Dir.glob(video_dir.join("*.mp4")) do |video_path|
      video_name = File.basename(video_path, ".mp4")
      thumbnail_path = preview_dir.join("#{video_name}-thumbnail.png")

      puts "Processing #{video_name}..."

      system("ffmpeg -i #{Shellwords.escape(video_path)} -ss 00:00:01 -vframes 1 -vf scale=600:-1 #{Shellwords.escape(thumbnail_path)}")
      puts "Generated preview for #{video_name} at #{thumbnail_path}"
    end

    puts "Thumbnail generation complete!"
  end
end