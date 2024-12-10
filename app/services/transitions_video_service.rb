class TransitionsVideoService
  def initialize(temp_dir, ts_videos)
    @temp_dir = temp_dir
    @ts_videos = ts_videos
  end

  def normalize_video(input_path, output_path)
    system("ffmpeg -y -i \"#{input_path}\" -vf \"scale=1920:1080,setsar=1\" -r 30 -c:v libx264 -preset fast -crf 18 -c:a aac -ar 44100 -ac 2 -strict experimental \"#{output_path}\"")
  end

  def concatenate_final_video_with_dissolve_crossfade_transition
    final_music_path = ActiveStorage::Blob.service.send(:path_for, @video.music.music.key) if @video.whole_video?

    # Normalize all input videos
    normalized_videos = []
    @ts_videos.uniq.each_with_index do |video, index|
      normalized_path = @temp_dir.join("normalized_#{index}.mp4")
      normalize_video(video, normalized_path)
      normalized_videos << normalized_path
    end

    # Generate the crossfade segments dynamically
    filter_complex = []
    inputs = normalized_videos.map.with_index { |video, index| "-i \"#{video}\"" }.join(" ")
    crossfade_index = 0

    normalized_videos.each_with_index do |video, index|
      next_video = normalized_videos[index + 1]
      break if next_video.nil?

      video_duration = `ffprobe -v error -show_entries format=duration -of default=noprint_wrappers=1:nokey=1 "#{video}"`.strip.to_f
      transition_duration = 1 # seconds

      filter_complex << "[#{index}:v:0][#{index + 1}:v:0]xfade=transition=dissolve:duration=#{transition_duration}:offset=#{video_duration - transition_duration}[v#{crossfade_index}];"
      filter_complex << "[#{index}:a:0][#{index + 1}:a:0]acrossfade=d=#{transition_duration}[a#{crossfade_index}];"
      crossfade_index += 1
    end

    # Add final concatenation step
    concat_inputs = crossfade_index.times.map { |i| "[v#{i}][a#{i}]" }.join
    filter_complex << "#{concat_inputs}concat=n=#{crossfade_index}:v=1:a=1[outv][outa]"

    # Adjust final filter_complex
    final_concatenated_path = @temp_dir.join("final_concatenated.mp4")
    ffmpeg_command = "ffmpeg -y #{inputs} -filter_complex \"#{filter_complex.join}\" " \
                     "-map \"[outv]\" -map \"[outa]\" -c:v libx264 -pix_fmt yuv420p -c:a aac -ar 44100 -movflags +faststart \"#{final_concatenated_path}\""

    system(ffmpeg_command)

    # Convert the concatenated video to the final MP4
    final_video_path = @temp_dir.join("final_video.mp4")
    if @video.whole_video? && final_music_path
      add_to_mlt_music(final_music_path, "music_whole_video.mp3", "music_whole_video")
      upload_to_archive("music_whole_video.mp3", final_music_path)

      p "+" * 100 + "concatenate_final_video_with_music_on_whole_video" + "+" * 100
      system(
        "ffmpeg -y -i \"#{final_concatenated_path}\" -i \"#{final_music_path}\" " \
        "-filter_complex \"anullsrc=channel_layout=stereo:sample_rate=44100[a0];[1:a:0]volume=0.5[a1];[a0][a1]amix=inputs=2:duration=shortest[aout]\" " \
        "-map 0:v:0 -map \"[aout]\" -c:v libx264 -pix_fmt yuv420p -r 30 -c:a aac -ar 44100 -movflags +faststart -shortest \"#{final_video_path}\""
      )
      p "-" * 100 + "concatenate_final_video_with_music_on_whole_video" + "-" * 100
    else
      rebuild_final_video_with_music_by_chapters(final_video_path)
    end

    final_video_path
  end
end
