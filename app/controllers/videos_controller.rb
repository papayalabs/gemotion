require "fileutils"
require "zip"
class VideosController < ApplicationController
  before_action :select_video, except: %i[start start_post go_back join update_video_music_type]
  before_action :define_chapter_type, only: %i[select_chapters select_chapters_post]
  before_action :define_music, only: %i[music music_post]
  before_action :define_dedicace, only: %i[dedicace dedicace_post]
  before_action :select_join_video, only: %i[join]
  before_action :define_video_chapters, only: %i[content content_post]

  def start
    # TODO: with last user
    @video = Video.last
    return if @video.nil?
    return unless @video.current_step != "start"

    redirect_to send("#{@video.current_step}_path"), notice: "Reprenez votre vidéo en cours."

    # TODO: delete current video if user confirmation
  end

  ##
  # Cette méthode pose problème si l'on utilise turbo car le préchargement
  # provoque le recul en arrière. Il faut donc desactiver turbo sur les liens
  # souhaitant ce servir de step_back_path.
  # Utilise le template dans videos/shared/_back_button.html.erb pour récupérer
  # un lien fonctionnel
  def go_back
    # TODO: change with current_user.videos.last
    @video = Video.last
    redirect_to start_path, alert: "Aucune vidéo trouvé." if @video.nil?

    @video.stop_at = @video.previous_step
    if @video.save
      redirect_to send("#{@video.current_step}_path")
    else
      redirect_to send("#{@video.current_step}_path"), alert: "Impossible de revenir en arrière"
    end
  end

  def start_post
    # Creation d'une nouvelle vidéo
    @video = Video.new
    return render start_path, status: :unprocessable_entity if params[:video_type].nil?

    # Le type de la vidéo depuis le radio button du formulaire
    @video.video_type = params[:video_type].downcase
    # On est à la première étape de la vidéo
    @video.stop_at = @video.way.first
    # Generate the unique identifier of the video
    @video.generate_token

    # Validate and create the video
    if @video.validate_start && @video.save
      redirect_to send("#{@video.next_step}_path")
    else
      render start_path, status: :unprocessable_entity
    end
  end

  def occasion_post
    @video.occasion = params[:occasion]
    @video.stop_at = @video.next_step

    if @video.validate_occasion && @video.save
      redirect_to send("#{@video.next_step}_path")
    else
      @video.update(stop_at: @video.current_step)
      render occasion_path, status: :unprocessable_entity
    end
  end

  def destinataire_post
    @vd = @video.video_destinataires.new(genre: params[:sexe_destinataire])
    @video.stop_at = @video.next_step

    if @video.validate_destinataire(@vd) && @vd.save && @video.save
      redirect_to send("#{@video.next_step}_path")
    else
      @video.update(stop_at: @video.current_step)
      render destinataire_path, status: :unprocessable_entity
    end
  end

  def info_destinataire_post
    # for skip destinataire page
    @vd = @video.video_destinataires.create(genre: 2)
    ##############################
    @vd = @video.video_destinataires.last
    @vd.age = params[:age_destinataire]
    @vd.name = params[:name_destinataire]
    @vd.more_info = params[:more_info_destinataire]
    if params[:special_request_destinataire].present?
      @video.theme = "specific_request"
      @video.theme_specific_request = params[:special_request_destinataire]
    end

    @video.stop_at = @video.next_step

    if @video.validate_info_destinataire(@vd) && @vd.save && @video.save
      redirect_to send("#{@video.next_step}_path")
    else
      @video.update(stop_at: @video.current_step)
      return render info_destinataire_path, status: :unprocessable_entity
    end

    nil if params[:special_request_destinataire].nil?
    # TODO: send email to PO.
  end

  def date_fin_post
    return render date_fin_path, status: :unprocessable_entity if params[:end_date].blank?

    @video.end_date = DateTime.parse(params[:end_date])
    @video.stop_at = @video.next_step

    if @video.validate_date_fin && @video.save
      redirect_to send("#{@video.next_step}_path")
    else
      @video.update(stop_at: @video.current_step)
      render date_fin_path, status: :unprocessable_entity
    end
  end

  def introduction_post
    @video.theme = params[:theme]
    @video.theme_specific_request = params[:special_request]
    @video.stop_at = @video.next_step
    if @video.validate_introduction && @video.save
      redirect_to send("#{@video.next_step}_path")
    else
      @video.update(stop_at: @video.current_step)
      render introduction_path, status: :unprocessable_entity
    end
  end

  def photo_intro_post
    @video.previews.destroy_all unless params[:previews] == [""] && @video.previews.count > 0

    ordered_previews = params[:image_order]&.split(',') || []
    previews_to_create = []

    params[:previews].each_with_index do |preview, index|
      next if preview.blank?

      p = Preview.create(image: preview)

      # Adjusted Order Index Logic
      order_index = ordered_previews.index(index.to_s) # Still using index from params
      order_index = order_index.nil? ? index : ordered_previews[order_index].to_i # Correctly assigning based on ordered_previews

      previews_to_create << { preview: p, order: order_index }
    end

    previews_to_create.sort_by! { |h| h[:order] }

    previews_to_create.each do |preview_hash|
      @video.video_previews.create(preview: preview_hash[:preview], order: preview_hash[:order])
    end

    @video.stop_at = @video.next_step if @video.validate_photo_intro
    if @video.validate_photo_intro && @video.save
      redirect_to send("#{@video.next_step}_path")
    else
      flash[:alert] = "Vous devez sélectionner au moins une photo"
      @video.update(stop_at: @video.current_step)
      redirect_to photo_intro_path
    end
  end

  def select_chapters
  end

  def select_chapters_post
    # On authorize que certain parametre
    params_allow = params.permit(chapters: %i[select text])["chapters"]

    chapter_to_create = [] # Un tableau a remplir de chapitre a créer
    chapter_to_updates = {} # Un hash a remplir de chapitre a modifier

    # Si le chapitre est déjà sélectionné, on doit le modifier
    find_chapters = [] # On crée un tableau servant à la requete SQL IN pour ne récupérer que des chapitres déjà crée
    params_allow.each { |k, v| find_chapters.append(k) if v["select"] == "true" }
    # On cherche avec la request SQL IN les video_chapters ayant déjà un chapitre lié à l'ancien
    chapter_to_updates_model = @video.video_chapters.where(chapter_type_id: find_chapters)
    chapter_to_delete = @video.video_chapters.where.not(chapter_type_id: find_chapters)
    id_chapter_type = [] # L'id uniquement des chapitre_type en relation avec les chapitres video a modifier.
    chapter_to_updates_by_chapter_type = {} # Un hash permettant de faire une recherche par le chapitre_type
    chapter_to_updates_model.each do |k|
      id_chapter_type.append(k.chapter_type_id.to_s)
      chapter_to_updates_by_chapter_type[k.chapter_type_id.to_s] = k
    end

    # On ne se prépare à créer que les éléments qu'il faut.
    params_allow.each do |k, v|
      # Si un chapitre existe déjà avec ce type de chapitre, on ne le crée pas ...
      if id_chapter_type.include?(k)
        # Si le chapitre est toujours sélectionné, on le modifie
        if v["select"] == "true"
          video_chapter = chapter_to_updates_by_chapter_type[k]
          chapter_to_updates[video_chapter.id] = {
            text: v["text"]
          }
        end
      elsif v["select"] == "true"
        # Si l'élément est bien séléctionné
        chapter_to_create.append({ chapter_type_id: k, text: v["text"] })
        # On l'ajoute dans la liste des éléments à supprimer
        # ... on le modifie
      end
    end

    # 12 chapitres maximum
    if (chapter_to_create.size + chapter_to_updates.size) >= 12
      flash[:alert] = "Ne sélectionnez que 12 chapitres maximum"
      return render select_chapters_path, status: :unprocessable_entity
    end

    # Création, Mise à jour et suppression

    if @video.video_chapters.create(chapter_to_create) &&
      @video.video_chapters.update(chapter_to_updates.keys, chapter_to_updates.values)

      @video.video_chapters.each do |chapter|
        chapter.video_music.destroy if chapter.video_music
      end

      chapter_to_delete.destroy_all

      @video.update(stop_at: @video.next_step)
      redirect_to send("#{@video.next_step}_path")
    else
      @video.update(stop_at: @video.current_step)
      @chapterstype = ChapterType.all
      render select_chapters_path, status: :unprocessable_entity
    end
  end

  def music_post
    # Check for params indicating the whole video or chapters
    if params[:music].nil? && params.keys.none? { |key| key.start_with?('music_') }
      flash[:alert] = "Vous devez sélectionner au moins une musique"
      return render music_path, status: :unprocessable_entity
    end

    # Handle the "whole video" case
    if params[:music]
      music = Music.find_by(id: params[:music])
      if music.nil?
        flash[:alert] = "Sélection incorrecte. La musique n'existe pas."
        return render music_path, status: :unprocessable_entity
      end
      @video.music = music
    end

    # Handle the "by chapters" case
    params.each do |key, value|
      if key.start_with?('music_')
        chapter_id = key.split('_').last.to_i
        music_id = value.to_i

        video_chapter = @video.video_chapters.find_by(id: chapter_id)
        if video_chapter
          music = Music.find_by(id: music_id)
          if music
            # Delete the old VideoMusic object if it exists
            video_chapter.video_music&.destroy

            # Create a new VideoMusic object
            VideoMusic.create(music: music, video_chapter: video_chapter)
          else
            flash[:alert] = "Musique non trouvée pour le chapitre #{chapter_id}."
            return render music_path, status: :unprocessable_entity
          end
        end
      end
    end

    @video.stop_at = @video.next_step

    if @video.save
      redirect_to send("#{@video.next_step}_path")
    else
      @video.update(stop_at: @video.current_step)
      render music_path, status: :unprocessable_entity
    end
  end

  def dedicace_post
    if params[:dedicace].nil?
      flash[:alert] = "Vous devez séléctionnez une dedicace"
      return render dedicace_path, status: :unprocessable_entity
    end

    # Utilisation de find_by pour avoir un objet nil si pas trouvé.
    dedicace = Dedicace.find_by(id: params[:dedicace])
    if dedicace.nil?
      flash[:alert] = "Sélection incorrecte. La dedicace n'existe pas."
      return render dedicace_path, status: :unprocessable_entity
    end

    @video.dedicace = dedicace
    @video.stop_at = @video.next_step

    if @video.save
      redirect_to send("#{@video.next_step}_path")
    else
      @video.update(stop_at: @video.current_step)
      render dedicace_path, status: :unprocessable_entity
    end
  end

  def share_post
    # Le mailer fonctionne mais pas le join
    email = params[:email]
    if email.blank?
      flash[:alert] = "Un email doit être indiqué pour envoyer l'invitation."
      return render share_path, status: :unprocessable_entity
    end

    InvitationMailer.with(url: join_url(@video.token), email:).send_invitation.deliver_later
    flash[:notice] = "Invitation envoyé."
    redirect_to share_path
  end

  def join
    # Cette étape nécessite l'authentification car pour l'instant nous ne faisons pas d'identifiant de vidéo par utilisateur.
  end

  def skip_share
    skip_element(share_path)
  end

  def content_post
    @video_chapter = @video.video_chapters.find(params[:id])

    # Attach videos
    if params[:videos].present? && params[:videos] != [""]
      @video_chapter.videos.purge
      params[:videos].reject(&:blank?).each do |video|
        @video_chapter.videos.attach(video)
      end
    end

    # Attach photos
    if params[:photos].present? && params[:photos] != [""]
      @video_chapter.photos.purge
      params[:photos].reject(&:blank?).each do |photo|
        @video_chapter.photos.attach(photo)
      end
    end

    flash[:notice] = "Contenu ajouté."
    redirect_to content_path
  end

  def skip_content
    skip_element(content_path)
  end

  # def content_dedicace
  #   temp_dir = Rails.root.join("tmp", SecureRandom.hex)
  #   FileUtils.mkdir_p(temp_dir)

  #   chapter_videos = @video.video_chapters.map { |vc| vc.element }

  #   if chapter_videos.empty?
  #     flash[:alert] = "Aucune vidéo de chapitre disponible pour la concaténation."
  #     FileUtils.rm_rf(temp_dir)
  #     return redirect_to content_dedicace_path
  #   end

  #   # Convertir les vidéos en MPEG-TS sans réencodage
  #   ts_videos = chapter_videos.map.with_index do |video, index|
  #     input_path = ActiveStorage::Blob.service.send(:path_for, video.key)
  #     output_path = temp_dir.join("video_#{index}.ts")
  #     # Conversion en MPEG-TS
  #     system("ffmpeg -y -i \"#{input_path}\" -c copy -bsf:v h264_mp4toannexb -f mpegts \"#{output_path}\"")
  #     output_path.to_s
  #   end

  #   # Créer la liste des fichiers TS à concaténer
  #   ts_files = ts_videos.join("|")

  #   concatenated_ts_path = temp_dir.join("concatenated.ts")
  #   # Concaténer les fichiers TS sans réencodage
  #   system("ffmpeg -y -i \"concat:#{ts_files}\" -c copy -f mpegts \"#{concatenated_ts_path}\"")

  #   # Convertir le fichier TS concaténé en MP4
  #   concatenated_video_path = temp_dir.join("concatenated_video.mp4")
  #   system("ffmpeg -y -i \"#{concatenated_ts_path}\" -c copy \"#{concatenated_video_path}\"")

  #   unless File.exist?(concatenated_video_path)
  #     flash[:alert] = "La concaténation des vidéos a échoué."
  #     FileUtils.rm_rf(temp_dir)
  #     return redirect_to content_dedicace_path
  #   end

  #   # Ajouter la musique de fond tout en conservant le son original des vidéos
  #   # music_path = ActiveStorage::Blob.service.send(:path_for, @video.whole_video? ? @video.music.music.key : Music.first.music.key)
  #   music_path = ActiveStorage::Blob.service.send(:path_for, @video.music.music.key)
  #   final_video_path = temp_dir.join("final_video_with_music.mp4")
  #   # Mixer l'audio des vidéos avec la musique
  #   system("ffmpeg -y -i \"#{concatenated_video_path}\" -i \"#{music_path}\" -filter_complex \"[0:a]volume=1.0[a0];[1:a]volume=0.5[a1];[a0][a1]amix=inputs=2:duration=shortest[aout]\" -map 0:v -map \"[aout]\" -c:v copy -c:a aac -shortest \"#{final_video_path}\"")

  #   unless File.exist?(final_video_path)
  #     flash[:alert] = "L'ajout de la musique de fond a échoué."
  #     FileUtils.rm_rf(temp_dir)
  #     return redirect_to content_dedicace_path
  #   end

  #   # Ajouter la vidéo dédicace comme overlay avec opacité après avoir généré la vidéo finale
  #   theme_video = ActiveStorage::Blob.service.send(:path_for, @video.dedicace.video.key)
  #   video_with_overlay_path = temp_dir.join("final_video_with_overlay.mp4")
  #   # Appliquer la vidéo overlay avec opacité 0.3 sur la vidéo finale, et limiter la durée de l'overlay à celle de la vidéo principale
  #   system("ffmpeg -y -i \"#{final_video_path}\" -i \"#{theme_video}\" -filter_complex \"[1]format=rgba,colorchannelmixer=aa=0.3[overlay];[0][overlay]overlay=0:0:format=auto,format=yuv420p,trim=duration=$(ffprobe -i #{final_video_path} -show_entries format=duration -v quiet -of csv='p=0')\" -c:a copy \"#{video_with_overlay_path}\"")

  #   unless File.exist?(video_with_overlay_path)
  #     flash[:alert] = "L'ajout de la vidéo dédicace en overlay a échoué."
  #     FileUtils.rm_rf(temp_dir)
  #     return redirect_to content_dedicace_path
  #   end

  #   # Attacher la vidéo finale avec musique et overlay
  #   @video.final_video.attach(io: File.open(video_with_overlay_path), filename: "final_video_with_overlay.mp4")
  #   @final_video_url = url_for(@video.final_video)

  #   FileUtils.rm_rf(temp_dir)

  #   flash[:notice] = "La vidéo finale avec musique et overlay a été générée avec succès."
  # end

  def content_dedicace
    temp_dir = Rails.root.join("tmp", SecureRandom.hex)
    FileUtils.mkdir_p(temp_dir)

    # Retrieve previews sorted by order
    preview_assets = @video.video_previews.includes(:preview).sort_by(&:order)

    # Get chapter assets
    chapter_assets = @video.video_chapters.includes(:chapter_type).map do |vc|
      {
        videos: vc.videos,
        photos: vc.photos,
        music: vc.video_music.music,
        chapter_type_image: vc.chapter_type.image, # Assuming chapter_type has an image
        text: vc.text # Get the text for this chapter
      }
    end

    if chapter_assets.empty? || preview_assets.empty?
      flash[:alert] = "Aucune vidéo, photo ou aperçu de chapitre disponible."
      FileUtils.rm_rf(temp_dir)
      return redirect_to content_dedicace_path
    end

    ts_videos = []

    # Process the previews
    preview_assets.each_with_index do |preview, index|
      preview_path = ActiveStorage::Blob.service.send(:path_for, preview.preview.image.key)
      output_path = temp_dir.join("preview_#{index}.ts")
      system("ffmpeg -y -loop 1 -i \"#{preview_path}\" -c:v libx264 -t 3 -vf \"scale=1280:720\" -pix_fmt yuv420p \"#{output_path}\"")
      ts_videos << output_path.to_s
    end

    # Prepare to hold the final music path based on music type
    final_music_path = nil

    if @video.music_type == "whole_video"
      final_music_path = ActiveStorage::Blob.service.send(:path_for, @video.music.music.key)
    end

    chapter_assets.each_with_index do |assets, chapter_index|
      chapter_music_path = ActiveStorage::Blob.service.send(:path_for, assets[:music].music.key) if @video.music_type == "by_chapters"

      # Create a video segment with chapter image and text
      chapter_image_path = ActiveStorage::Blob.service.send(:path_for, assets[:chapter_type_image].key) if assets[:chapter_type_image]
      chapter_text = assets[:text]
      text_output_path = temp_dir.join("chapter_intro_#{chapter_index}.ts")

      # Create a video for the chapter's intro with the image and text
      if chapter_image_path && chapter_text.present?
        system("ffmpeg -y -loop 1 -i \"#{chapter_image_path}\" -vf drawtext=\"text='#{chapter_text}':fontcolor=white:fontsize=24:x=(W-w)/2:y=(H-h)/2\" -t 3 -c:v libx264 -pix_fmt yuv420p \"#{text_output_path}\"")
        ts_videos << text_output_path.to_s
      else
        flash[:alert] = "L'image ou le texte du chapitre #{chapter_index + 1} est manquant."
        FileUtils.rm_rf(temp_dir)
        return redirect_to content_dedicace_path
      end

      # Process videos
      assets[:videos].each_with_index do |video, video_index|
        input_path = ActiveStorage::Blob.service.send(:path_for, video.key)
        output_path = temp_dir.join("video_#{chapter_index}_#{video_index}.ts")
        system("ffmpeg -y -i \"#{input_path}\" -c copy -bsf:v h264_mp4toannexb -f mpegts \"#{output_path}\"")
        ts_videos << output_path.to_s
      end

      # Process photos
      assets[:photos].each_with_index do |photo, photo_index|
        input_path = ActiveStorage::Blob.service.send(:path_for, photo.key)
        output_path = temp_dir.join("photo_#{chapter_index}_#{photo_index}.ts")
        system("ffmpeg -y -loop 1 -i \"#{input_path}\" -c:v libx264 -t 3 -vf \"scale=1280:720\" -pix_fmt yuv420p \"#{output_path}\"")
        ts_videos << output_path.to_s
      end

      # Concatenate chapter's videos and photos into one video
      chapter_ts_files = ts_videos.last((assets[:videos].count + assets[:photos].count + 1)) # +1 for the intro
      chapter_ts_file_list = chapter_ts_files.join("|")

      concatenated_ts_path = temp_dir.join("chapter_#{chapter_index}_concatenated.ts")
      system("ffmpeg -y -i \"concat:#{chapter_ts_file_list}\" -c copy -f mpegts \"#{concatenated_ts_path}\"")

      # Convert the chapter TS to MP4
      chapter_concatenated_video_path = temp_dir.join("chapter_#{chapter_index}_concatenated_video.mp4")
      system("ffmpeg -y -i \"#{concatenated_ts_path}\" -c copy \"#{chapter_concatenated_video_path}\"")

      # Handle music mixing
      if @video.music_type == "by_chapters"
        if File.exist?(chapter_music_path)
          final_chapter_video_path = temp_dir.join("final_chapter_video_with_music.mp4")
          system("ffmpeg -y -i \"#{chapter_concatenated_video_path}\" -i \"#{chapter_music_path}\" -filter_complex \"[0:a]volume=1.0[a0];[1:a]volume=0.5[a1];[a0][a1]amix=inputs=2:duration=shortest[aout]\" -map 0:v -map \"[aout]\" -c:v copy -c:a aac -shortest \"#{final_chapter_video_path}\"")

          unless File.exist?(final_chapter_video_path)
            flash[:alert] = "L'ajout de la musique de chapitre a échoué pour le chapitre #{chapter_index + 1}."
            FileUtils.rm_rf(temp_dir)
            return redirect_to content_dedicace_path
          end

          ts_videos << final_chapter_video_path.to_s
        else
          flash[:alert] = "Musique manquante pour le chapitre #{chapter_index + 1}."
          FileUtils.rm_rf(temp_dir)
          return redirect_to content_dedicace_path
        end
      else
        ts_videos << chapter_concatenated_video_path.to_s
      end
    end

    # Now concatenate all final chapter videos into one final video
    final_video_ts_file_list = ts_videos.join("|")
    final_concatenated_ts_path = temp_dir.join("final_concatenated.ts")
    system("ffmpeg -y -i \"concat:#{final_video_ts_file_list}\" -c copy -f mpegts \"#{final_concatenated_ts_path}\"")

    # Convert the final TS to MP4
    final_video_path = temp_dir.join("final_video.mp4")
    if @video.music_type == "whole_video" && final_music_path
      # Mix the final music into the whole video
      system("ffmpeg -y -i \"#{final_concatenated_ts_path}\" -i \"#{final_music_path}\" -filter_complex \"[0:a]volume=1.0[a0];[1:a]volume=0.5[a1];[a0][a1]amix=inputs=2:duration=shortest[aout]\" -map 0:v -map \"[aout]\" -c:v copy -c:a aac -shortest \"#{final_video_path}\"")
    else
      system("ffmpeg -y -i \"#{final_concatenated_ts_path}\" -c copy \"#{final_video_path}\"")
    end

    unless File.exist?(final_video_path)
      flash[:alert] = "La concaténation des vidéos finales a échoué."
      FileUtils.rm_rf(temp_dir)
      return redirect_to content_dedicace_path
    end

    # Attach the final video
    @video.final_video.attach(io: File.open(final_video_path), filename: "final_video.mp4")
    @final_video_url = url_for(@video.final_video)

    FileUtils.rm_rf(temp_dir)

    flash[:notice] = "La vidéo finale avec musique par chapitre a été générée avec succès."
  end

  def get_video_duration(video_path)
    output = `ffprobe -i #{video_path} -show_entries format=duration -v quiet -of csv="p=0"`
    output.strip
  end

  def content_dedicace_post
    params[:contents].each do |file|
      dc = @video.dedicace_contents.create(position: @video.dedicace_contents.count)
      dc.content.attach(file)
    end

    flash[:notice] = "Contenu ajouté."
    redirect_to content_dedicace_path
  end

  def skip_content_dedicace
    skip_element(content_dedicace_path)
  end

  def update_video_music_type
    @video = Video.find(params[:id])
    if @video.update(music_type: params[:video][:music_type])
      head :no_content # Respond with a 204 No Content status to avoid template rendering
    else
      render plain: "Failed to update music type", status: :unprocessable_entity
    end
  end

  private

  def generate_fcpxml(final_video_path, video_path, music_path)
    <<~XML
      <?xml version="1.0" encoding="UTF-8"?>
      <!DOCTYPE fcpxml>
      <fcpxml version="1.8">
        <resources>
          <format id="r1" name="FFVideoFormat1080p24" frameDuration="1001/24000s" width="1920" height="1080"/>
          <asset id="video" src="#{video_path}" start="0s" duration="3600s" hasAudio="1" hasVideo="1"/>
          <asset id="music" src="#{music_path}" start="0s" duration="3600s" hasAudio="1" hasVideo="0"/>
          <asset id="final_video" src="#{final_video_path}" start="0s" duration="3600s" hasAudio="1" hasVideo="1"/>
        </resources>
        <library>
          <event name="Event">
            <project name="Project">
              <sequence duration="3600s" format="r1">
                <spine>
                  <asset-clip name="Final Video" offset="0s" ref="final_video" duration="3600s" start="0s">
                  </asset-clip>
                  <asset-clip name="Music" offset="0s" ref="music" duration="3600s" start="0s">
                  </asset-clip>
                </spine>
              </sequence>
            </project>
          </event>
        </library>
      </fcpxml>
    XML
  end

  def select_video
    # TODO: change when user login to current_user.videos.last
    @video = Video.last
    # On check si une vidéo existe
    if @video.nil?
      redirect_to start_path, alert: "Aucune vidéo trouvé."
    # Si une vidéo existe, on doit être sur la bonne étape
    elsif ![@video.next_step.downcase, "#{@video.next_step.downcase}_post",
            "skip_#{@video.next_step.downcase}"].include?(params[:action].downcase)
      redirect_to send("#{@video.next_step}_path"),
                  alert: "Vous devez finaliser cette étape avant de passer à la prochaine."
    end
  end

  def define_chapter_type
    # On va cherche la query directement dans SQL
    q_results = ActiveRecord::Base.connection.exec_query('
      SELECT DISTINCT "chapter_types".id, "chapter_types".created_at, "video_chapters".text
      FROM "chapter_types"
      LEFT OUTER JOIN "video_chapters" ON "video_chapters"."chapter_type_id" = "chapter_types"."id" AND video_chapters.video_id = $1
      ORDER BY "chapter_types".created_at ASC',
                                                         "selectChapterWithData",
                                                         [@video.id])
    # On recupere le resultat est filtre pour n'avoir que les ID de chapters_types
    r_only_id = q_results.rows.map { |v| v[0] }
    # On recupere les ChaptersType (le modèle Rails).
    chapter_types = ChapterType.where(id: r_only_id)
    # On transforme cela en hash (pour effectuer une accessation en 0(n))
    chapter_types_h = chapter_types.index_by { |ct| ct.id }

    @chapterstype = q_results.as_json.map do |k|
      { ct: chapter_types_h[k["id"]], text: k["text"], select: k["text"].present? }
    end
  end

  def define_music
    @musics = Music.all
  end

  def define_dedicace
    @dedicaces = Dedicace.all
  end

  def select_join_video
    @video = Video.find_by!(token: params[:id])
  end

  def define_video_chapters
    @video_chapters = @video.video_chapters
  end

  def skip_element(error_path)
    @video.stop_at = @video.next_step

    if @video.save
      redirect_to send("#{@video.next_step}_path")
    else
      @video.update(stop_at: @video.current_step)
      render error_path, status: :unprocessable_entity
    end
  end
end
