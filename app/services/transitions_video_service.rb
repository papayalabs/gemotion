class TransitionsVideoService
  def initialize(temp_dir)
    @temp_dir = temp_dir
  end

  def create_transition_wipelt_videos(ts_videos, transition_duration = 1)
    raise ArgumentError, "At least 2 videos are required for transitions." if ts_videos.size < 2

    # Paths
    output_video_path = @temp_dir.join("final_video_with_transitions.mp4")
    normalized_videos = []

    filtered_videos = ts_videos.reject do |file|
      File.basename(file).match?(/^chapter_\d+_concatenated_video\./)
    end
    # Normalize each video
    filtered_videos.each_with_index do |video, index|
      normalized_path = @temp_dir.join("normalized_video_#{index}.mp4")
      normalize_video(video, normalized_path)
      normalized_videos << normalized_path
    end

    # Create transitions between each pair of normalized videos
    intermediate_videos = []
    normalized_videos.each_cons(2).with_index do |(video1, video2), index|
      transition_output = @temp_dir.join("transition_#{index}.mp4")
      intermediate_videos << transition_output

      ffmpeg_command = <<~CMD
        ffmpeg -i #{Shellwords.escape(video1.to_s)} -i #{Shellwords.escape(video2.to_s)} -filter_complex "
        [0:v]format=pix_fmts=yuv420p,scale=1920:1080[base];
        [1:v]format=pix_fmts=yuv420p,scale=1920:1080[next];
        [base][next]xfade=transition=cube:duration=#{transition_duration}:offset=0[out]" \
        -map "[out]" -c:v libx264 -crf 23 -preset veryfast #{Shellwords.escape(transition_output.to_s)}
      CMD

      # Execute the command
      raise "Failed to create transition #{index}" unless system(ffmpeg_command)
    end

    # Concatenate all videos with transitions
    concat_list = @temp_dir.join("concat_list.txt")
    File.open(concat_list, "w") do |file|
      intermediate_videos.each do |path|
        file.puts("file '#{path}'")
      end
    end

    concat_command = <<~CMD
      ffmpeg -f concat -safe 0 -i #{Shellwords.escape(concat_list.to_s)} \
        -c copy #{Shellwords.escape(output_video_path.to_s)}
    CMD

    # Execute the concatenation
    raise "Failed to concatenate videos" unless system(concat_command)

    # Clean up intermediate files (optional)
    (normalized_videos + intermediate_videos).each { |file| File.delete(file) if File.exist?(file) }
    File.delete(concat_list) if File.exist?(concat_list)

    # Return the final output path
    output_video_path
  end

  def cube_view(ts_videos)
    # Ensure we have exactly six input videos
    raise ArgumentError, "At least 6 video inputs are required to create a cube view." if ts_videos.size < 6

    # Paths
    cube_video_path = @temp_dir.join("cube_video.mp4")

    # Normalize input videos
    normalized_video_paths = ts_videos.first(6).each_with_index.map do |current_video_path, index|
      normalized_video_path = @temp_dir.join("normalized_video_#{index}.mp4")
      normalize_video(current_video_path, normalized_video_path)
      normalized_video_path
    end

    # Combine normalized videos into a single cubemap
    # Use v360 to create a cubemap layout
    filter_complex = %(
      [0:v]v360=input=equirect:output=cubemap:layout=3x2[front];
      [front]split=6[face0][face1][face2][face3][face4][face5];
      [face0]scale=300:300[front];
      [face1]scale=300:300[back];
      [face2]scale=300:300[left];
      [face3]scale=300:300[right];
      [face4]scale=300:300[top];
      [face5]scale=300:300[bottom];
      [front][left]overlay=W/4:H/4[tmp1];
      [tmp1][right]overlay=W/3:H/3[tmp2];
      [tmp2][top]overlay=W/6:H/6[tmp3];
      [tmp3][bottom]overlay=W/7:H/7[tmp4];
      [tmp4][back]overlay=W/8:H/8[out]
    ).strip

    # Build input arguments for ffmpeg
    inputs = normalized_video_paths.map { |path| "-i #{Shellwords.escape(path)}" }.join(" ")

    # Build the ffmpeg command
    ffmpeg_command = <<~CMD
      ffmpeg \
        #{inputs} \
        -filter_complex "#{filter_complex}" \
        -map "[out]" #{Shellwords.escape(cube_video_path.to_s)} \
        -c:v libx264 -crf 23 -preset veryfast
    CMD

    # Execute the ffmpeg command
    result = system(ffmpeg_command)

    # Check for errors
    raise "FFmpeg failed to create the cubemap view. Check the inputs and filters." unless result

    # Return the path to the cubemap video
    cube_video_path
  end

  def cube_rotation_transitions(ts_videos)
    transition_videos = []
    previous_video_path = nil

    ts_videos.each_with_index do |current_video_path, index|
      # Normalize the current video
      normalized_video_path = @temp_dir.join("normalized_video_#{index}.mp4")
      normalize_video(current_video_path, normalized_video_path)

      if previous_video_path
        # Apply cube rotation transition between the previous and current video
        transition_path = @temp_dir.join("transition_#{index}.mp4")

        ffmpeg_command = <<-CMD
          ffmpeg -y -i "#{previous_video_path}" -i "#{normalized_video_path}" -filter_complex "
          [0:v]setpts=PTS-STARTPTS,scale=1920:1080,setsar=1,format=rgba[v0];
          [1:v]setpts=PTS-STARTPTS,scale=1920:1080,setsar=1,format=rgba[v1];
          [v0]rotate=PI*sin(PI*t/3):c=black:ow=1920:oh=1080[rotated];
          [rotated][v1]blend=all_expr='if(gte(T,0.5),B,A)'[outv];
          [0:a]atrim=start=0:end=3,asetpts=PTS-STARTPTS[a0];
          [1:a]atrim=start=0:end=3,asetpts=PTS-STARTPTS[a1];
          [a0][a1]acrossfade=d=1[outa]
          " -map "[outv]" -map "[outa]" \
          -c:v libx264 -preset fast -crf 18 -c:a aac -strict experimental "#{transition_path}"
        CMD

        # Execute the FFmpeg command
        system(ffmpeg_command)

        unless File.exist?(transition_path)
          raise "Transition video creation failed for #{previous_video_path} and #{current_video_path}"
        end

        transition_videos << transition_path
      end

      previous_video_path = normalized_video_path
    end

    # Concatenate all transitions and normalized videos
    concatenate_videos_with_transitions(transition_videos, ts_videos)
  end

  def concatenate_videos_with_transitions(transition_videos, ts_videos)
    final_video_path = @temp_dir.join("final_transition_video.mp4")

    # Prepare the list of all transition videos and original normalized videos
    files = transition_videos.map { |path| "file '#{path}'" }
    File.open(@temp_dir.join("transition_file_list.txt"), "w") { |f| f.puts(files.join("\n")) }

    # FFmpeg command to concatenate all videos
    ffmpeg_command = <<-CMD
      ffmpeg -y -f concat -safe 0 -i "#{@temp_dir.join('transition_file_list.txt')}" \
      -c:v libx264 -preset fast -crf 18 -c:a aac "#{final_video_path}"
    CMD

    system(ffmpeg_command)

    raise "Final video creation failed" unless File.exist?(final_video_path)

    final_video_path
  end

  def normalize_video(input_path, output_path)
    # Normalize video to a consistent resolution and frame rate
    ffmpeg_command = <<~CMD
      ffmpeg -i #{Shellwords.escape(input_path.to_s)} \
        -vf "scale=1920:1080,fps=30" \
        -c:v libx264 -crf 23 -preset veryfast \
        -c:a aac -b:a 128k \
        #{Shellwords.escape(output_path.to_s)}
    CMD

    raise "Failed to normalize video: #{input_path}" unless system(ffmpeg_command)
  end

  # def normalize_video(input_path, output_path)
  #   system("ffmpeg -y -i \"#{input_path}\" -vf \"scale=1920:1080,setsar=1\" -r 30 -c:v libx264 -preset fast -crf 18 -c:a aac -ar 44100 -ac 2 -strict experimental \"#{output_path}\"")
  # end

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
