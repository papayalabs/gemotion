class ContentDedicaceService
  def initialize(video)
    @video = video
    @temp_dir = Rails.root.join("tmp", SecureRandom.hex)
    FileUtils.mkdir_p(@temp_dir)
    @ts_videos = []
  end

  def call
    if @video.music_type == "whole_video"
      process_with_music_whole_video
    elsif @video.music_type == "by_chapters"
      process_with_music_by_chapters
    else
      return { error: "Type de musique non pris en charge." }
    end

    final_video_path = concatenate_final_video

    unless File.exist?(final_video_path)
      return { error: "La concaténation des vidéos finales a échoué." }
    end

    attach_final_video(final_video_path)
    FileUtils.rm_rf(@temp_dir)
    { success: true }
  end

  private

  def process_with_music_whole_video
    process_previews # first 3 previews
  end

  def process_with_music_by_chapters
    process_previews # first 3 previews
  end

  def process_previews
    preview_assets = @video.video_previews.includes(:preview).sort_by(&:order)
    preview_assets.each_with_index do |preview, index|
      preview_path = ActiveStorage::Blob.service.send(:path_for, preview.preview.image.key)
      output_path = temp_dir.join("preview_#{index}.ts")
      system(
        "ffmpeg -y -loop 1 -i \"#{preview_path}\" " \
        "-f lavfi -i anullsrc=r=44100:cl=stereo " \
        "-c:v libx264 -c:a aac -t 3 -vf \"scale=1280:720\" -pix_fmt yuv420p " \
        "\"#{output_path}\""
      )
      ts_videos << output_path.to_s
    end
  end




end




# class ContentDedicaceService
#   def initialize(video)
#     @video = video
#     @temp_dir = Rails.root.join("tmp", SecureRandom.hex)
#     FileUtils.mkdir_p(@temp_dir)
#     @ts_videos = []
#   end

#   def call
#     preview_assets = fetch_preview_assets
#     chapter_assets = fetch_chapter_assets

#     return { error: "Aucune vidéo, photo ou aperçu de chapitre disponible." } if chapter_assets.empty? || preview_assets.empty?

#     process_previews(preview_assets)
#     process_chapters(chapter_assets)

#     final_video_path = concatenate_final_video

#     unless File.exist?(final_video_path)
#       return { error: "La concaténation des vidéos finales a échoué." }
#     end

#     attach_final_video(final_video_path)

#     FileUtils.rm_rf(@temp_dir)
#     { success: true }
#   end

#   private

#   def fetch_preview_assets
#     @video.video_previews.includes(:preview).sort_by(&:order)
#   end

#   def fetch_chapter_assets
#     @video.video_chapters.includes(:chapter_type).map do |vc|
#       {
#         videos: vc.ordered_videos,
#         photos: vc.ordered_photos,
#         music: vc.video_music&.music,
#         chapter_type_image: vc.chapter_type.image,
#         text: vc.text
#       }
#     end
#   end

#   def process_previews(preview_assets)
#     preview_assets.each_with_index do |preview, index|
#       preview_path = ActiveStorage::Blob.service.send(:path_for, preview.preview.image.key)
#       output_path = @temp_dir.join("preview_#{index}.ts")
#       system("ffmpeg -y -loop 1 -i \"#{preview_path}\" -f lavfi -i anullsrc=r=44100:cl=stereo -c:v libx264 -c:a aac -t 3 -vf \"scale=1280:720\" -pix_fmt yuv420p \"#{output_path}\"")
#       @ts_videos << output_path.to_s
#     end
#   end

#   def process_chapters(chapter_assets)
#     chapter_assets.each_with_index do |assets, chapter_index|
#       chapter_music_path = fetch_chapter_music(assets)
#       text_output_path = process_chapter_intro(assets, chapter_index)

#       return if text_output_path.nil?

#       process_videos(assets, chapter_index)
#       process_photos(assets, chapter_index)

#       concatenate_chapter_videos(chapter_index, assets, chapter_music_path)
#     end
#   end

#   def fetch_chapter_music(assets)
#     if @video.music_type == "by_chapters"
#       ActiveStorage::Blob.service.send(:path_for, assets[:music].music.key) if assets[:music]
#     end
#   end

#   def process_chapter_intro(assets, chapter_index)
#     chapter_image_path = ActiveStorage::Blob.service.send(:path_for, assets[:chapter_type_image].key) if assets[:chapter_type_image]
#     chapter_text = assets[:text]
#     return nil unless chapter_image_path && chapter_text.present?

#     text_output_path = @temp_dir.join("chapter_intro_#{chapter_index}.ts")
#     system("ffmpeg -y -loop 1 -i \"#{chapter_image_path}\" -f lavfi -i anullsrc=r=44100:cl=stereo -vf \"scale=iw:-2, drawtext=text='#{chapter_text}':fontcolor=white:fontsize=24:x=(w-text_w)/2:y=(h-text_h)/2\" -t 3 -c:v libx264 -pix_fmt yuv420p -c:a aac -shortest \"#{text_output_path}\"")
#     @ts_videos << text_output_path.to_s
#     text_output_path
#   end

#   def process_videos(assets, chapter_index)
#     assets[:videos].each_with_index do |video, video_index|
#       input_path = ActiveStorage::Blob.service.send(:path_for, video.key)
#       output_path = @temp_dir.join("video_#{chapter_index}_#{video_index}.ts")
#       system("ffmpeg -y -i \"#{input_path}\" -c copy -bsf:v h264_mp4toannexb -f mpegts \"#{output_path}\"")
#       @ts_videos << output_path.to_s
#     end
#   end

#   def process_photos(assets, chapter_index)
#     assets[:photos].each_with_index do |photo, photo_index|
#       input_path = ActiveStorage::Blob.service.send(:path_for, photo.key)
#       output_path = @temp_dir.join("photo_#{chapter_index}_#{photo_index}.ts")
#       system("ffmpeg -y -loop 1 -i \"#{input_path}\" -f lavfi -i anullsrc=r=44100:cl=stereo -c:v libx264 -t 3 -vf \"scale=1280:720\" -map 0:v -map 1:a -c:a aac -pix_fmt yuv420p \"#{output_path}\"")
#       @ts_videos << output_path.to_s
#     end
#   end

#   def concatenate_chapter_videos(chapter_index, assets, chapter_music_path)
#     chapter_ts_files = @ts_videos.last((assets[:videos].count + assets[:photos].count + 1)) # +1 for the intro
#     chapter_ts_file_list = chapter_ts_files.join("|")
#     concatenated_ts_path = @temp_dir.join("chapter_#{chapter_index}_concatenated.ts")
#     system("ffmpeg -y -i \"concat:#{chapter_ts_file_list}\" -c copy -f mpegts \"#{concatenated_ts_path}\"")

#     # Convert the chapter TS to MP4
#     chapter_concatenated_video_path = @temp_dir.join("chapter_#{chapter_index}_concatenated_video.mp4")
#     system("ffmpeg -y -i \"#{concatenated_ts_path}\" -c copy \"#{chapter_concatenated_video_path}\"")

#     if @video.music_type == "by_chapters" && chapter_music_path
#       add_music_to_chapter(chapter_concatenated_video_path, chapter_music_path, chapter_index)
#     else
#       @ts_videos << chapter_concatenated_video_path.to_s
#     end
#   end

#   def add_music_to_chapter(chapter_concatenated_video_path, chapter_music_path, chapter_index)
#     final_chapter_video_path = @temp_dir.join("final_chapter_#{chapter_index}_video_with_music.mp4")
#     system("ffmpeg -y -i \"#{chapter_concatenated_video_path}\" -i \"#{chapter_music_path}\" -filter_complex \"anullsrc=channel_layout=stereo:sample_rate=44100[a0];[1:a:0]volume=0.5[a1];[a0][a1]amix=inputs=2:duration=shortest[aout]\" -map 0:v:0 -map \"[aout]\" -c:v copy -c:a aac -movflags +faststart -shortest \"#{final_chapter_video_path}\"")
#     unless File.exist?(final_chapter_video_path)
#       raise "L'ajout de la musique de chapitre a échoué pour le chapitre #{chapter_index + 1}."
#     end

#     @ts_videos << final_chapter_video_path.to_s
#   end

#   def concatenate_final_video
#     final_video_ts_file_list = @ts_videos.join("|")
#     final_concatenated_ts_path = @temp_dir.join("final_concatenated.ts")
#     system("ffmpeg -y -i \"concat:#{final_video_ts_file_list}\" -c copy -f mpegts \"#{final_concatenated_ts_path}\"")

#     # Convert the final TS to MP4
#     final_video_path = @temp_dir.join("final_video.mp4")
#     system("ffmpeg -y -i \"#{final_concatenated_ts_path}\" -c copy \"#{final_video_path}\"")

#     final_video_path
#   end

#   def attach_final_video(final_video_path)
#     @video.final_video.attach(io: File.open(final_video_path), filename: "final_video.mp4")
#     @final_video_url = url_for(@video.final_video)

#     final_video_xml_path = @temp_dir.join("final_video_project.mlt")
#     system("melt #{final_video_path} -consumer xml:#{final_video_xml_path}")
#     @video.final_video_xml.attach(io: File.open(final_video_xml_path), filename: "final_video_project.mlt")
#   end
# end