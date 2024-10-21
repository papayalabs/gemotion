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

    params[:previews].each do |preview|
      unless preview.blank?
        p = Preview.create(image: preview)
        @video.video_previews.create(preview: p)
      end
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
    if @video.video_chapters.create(chapter_to_create) && @video.video_chapters.update(chapter_to_updates.keys,
                                                                                       chapter_to_updates.values) && chapter_to_delete.delete_all
      @video.update(stop_at: @video.next_step)
      redirect_to send("#{@video.next_step}_path")
    else
      @video.update(stop_at: @video.current_step)
      @chapterstype = ChapterType.all
      render select_chapters_path, status: :unprocessable_entity
    end
  end

  def music_post
    if params[:music].nil?
      flash[:alert] = "Vous devez sélectionner au moins une musique"
      return render music_path, status: :unprocessable_entity
    end

    # Utilisation de find_by pour avoir un objet nil si pas trouvé.
    music = Music.find_by(id: params[:music])
    if music.nil?
      flash[:alert] = "Sélection incorrecte. La musique n'existe pas."
      return render music_path, status: :unprocessable_entity
    end

    @video.music = music

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
    @video_chapter.element.attach params[:element]

    flash[:notice] = "Contenu ajouté."
    redirect_to content_path
  end

  def skip_content
    skip_element(content_path)
  end

  def content_dedicace
    temp_dir = Rails.root.join("tmp", SecureRandom.hex)
    FileUtils.mkdir_p(temp_dir)

    chapter_videos = @video.video_chapters.map { |vc| vc.element }

    if chapter_videos.empty?
      flash[:alert] = "Aucune vidéo de chapitre disponible pour la concaténation."
      FileUtils.rm_rf(temp_dir)
      return redirect_to content_dedicace_path
    end

    # Convertir les vidéos en MPEG-TS sans réencodage
    ts_videos = chapter_videos.map.with_index do |video, index|
      input_path = ActiveStorage::Blob.service.send(:path_for, video.key)
      output_path = temp_dir.join("video_#{index}.ts")
      # Conversion en MPEG-TS
      system("ffmpeg -y -i \"#{input_path}\" -c copy -bsf:v h264_mp4toannexb -f mpegts \"#{output_path}\"")
      output_path.to_s
    end

    # Créer la liste des fichiers TS à concaténer
    ts_files = ts_videos.join("|")

    concatenated_ts_path = temp_dir.join("concatenated.ts")
    # Concaténer les fichiers TS sans réencodage
    system("ffmpeg -y -i \"concat:#{ts_files}\" -c copy -f mpegts \"#{concatenated_ts_path}\"")

    # Convertir le fichier TS concaténé en MP4
    concatenated_video_path = temp_dir.join("concatenated_video.mp4")
    system("ffmpeg -y -i \"#{concatenated_ts_path}\" -c copy \"#{concatenated_video_path}\"")

    unless File.exist?(concatenated_video_path)
      flash[:alert] = "La concaténation des vidéos a échoué."
      FileUtils.rm_rf(temp_dir)
      return redirect_to content_dedicace_path
    end

    # Ajouter la musique de fond tout en conservant le son original des vidéos
    music_path = ActiveStorage::Blob.service.send(:path_for, @video.music.music.key)
    final_video_path = temp_dir.join("final_video_with_music.mp4")
    # Mixer l'audio des vidéos avec la musique
    system("ffmpeg -y -i \"#{concatenated_video_path}\" -i \"#{music_path}\" -filter_complex \"[0:a]volume=1.0[a0];[1:a]volume=0.5[a1];[a0][a1]amix=inputs=2:duration=shortest[aout]\" -map 0:v -map \"[aout]\" -c:v copy -c:a aac -shortest \"#{final_video_path}\"")

    unless File.exist?(final_video_path)
      flash[:alert] = "L'ajout de la musique de fond a échoué."
      FileUtils.rm_rf(temp_dir)
      return redirect_to content_dedicace_path
    end

    # Ajouter la vidéo dédicace comme overlay avec opacité après avoir généré la vidéo finale
    theme_video = ActiveStorage::Blob.service.send(:path_for, @video.dedicace.video.key)
    video_with_overlay_path = temp_dir.join("final_video_with_overlay.mp4")
    # Appliquer la vidéo overlay avec opacité 0.3 sur la vidéo finale, et limiter la durée de l'overlay à celle de la vidéo principale
    system("ffmpeg -y -i \"#{final_video_path}\" -i \"#{theme_video}\" -filter_complex \"[1]format=rgba,colorchannelmixer=aa=0.3[overlay];[0][overlay]overlay=0:0:format=auto,format=yuv420p,trim=duration=$(ffprobe -i #{final_video_path} -show_entries format=duration -v quiet -of csv='p=0')\" -c:a copy \"#{video_with_overlay_path}\"")

    unless File.exist?(video_with_overlay_path)
      flash[:alert] = "L'ajout de la vidéo dédicace en overlay a échoué."
      FileUtils.rm_rf(temp_dir)
      return redirect_to content_dedicace_path
    end

    # Attacher la vidéo finale avec musique et overlay
    @video.final_video.attach(io: File.open(video_with_overlay_path), filename: "final_video_with_overlay.mp4")
    @final_video_url = url_for(@video.final_video)

    FileUtils.rm_rf(temp_dir)

    flash[:notice] = "La vidéo finale avec musique et overlay a été générée avec succès."
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
