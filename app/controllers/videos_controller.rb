require "fileutils"
require "zip"
class VideosController < ApplicationController
  before_action :authenticate_user!, except: :join
  before_action :select_video, except: %i[go_back go_to_select_chapters dedicace_de_fin_patch join update_video_music_type concat_status delete_video_chapter]
  before_action :define_chapter_type, only: %i[select_chapters select_chapters_post]
  before_action :define_music, only: %i[music music_post edit_video]
  before_action :define_dedicace, only: %i[dedicace dedicace_post]
  before_action :select_join_video, only: %i[join]
  before_action :define_video_chapters, only: %i[content content_post]

  def start
    # authorize @video, :start?, policy_class: VideoPolicy

    return if @video.nil?
    return unless @video.current_step != "start"

    redirect_to send("#{@video.current_step}_path"), notice: "Reprenez votre vidéo en cours." if @video.current_step != "start"

    # TODO: delete current video if user confirmation
  end

  ##
  # Cette méthode pose problème si l'on utilise turbo car le préchargement
  # provoque le recul en arrière. Il faut donc desactiver turbo sur les liens
  # souhaitant ce servir de step_back_path.
  # Utilise le template dans videos/shared/_back_button.html.erb pour récupérer
  # un lien fonctionnel
  def go_back
    @video = current_user.videos.where.not(project_status: [:finished, :closed]).order(created_at: :desc).first
    p @video
    authorize @video, :go_back?, policy_class: VideoPolicy
    redirect_to start_path, alert: "Aucune vidéo trouvé." if @video.nil?

    @video.stop_at = @video.previous_step
    if @video.save
      redirect_to send("#{@video.current_step}_path")
    else
      redirect_to send("#{@video.current_step}_path"), alert: "Impossible de revenir en arrière"
    end
  end

  def go_to_select_chapters
    @video = current_user.videos.where.not(project_status: [:finished, :closed]).order(created_at: :desc).first
    @video.update(stop_at: "photo_intro")
    redirect_to select_chapters_path, alert: "Aucune vidéo trouvé."
  end

  def start_post

    if current_user.videos.where.not(project_status: [:finished, :closed]).count == 0 || current_user.videos.count == 0
      @video = Video.new(user: current_user)
      @video.user = current_user
      skip_authorization
      return render start_path, status: :unprocessable_entity if params[:video_type].nil?
      @video.video_type = params[:video_type].downcase

      @video.stop_at = @video.way.first
      @video.generate_token

    else
      authorize @video, :start_post?, policy_class: VideoPolicy
      @video.video_type = params[:video_type].downcase
    end

    if @video.validate_start && @video.save
      redirect_to send("#{@video.next_step}_path")
    else
      render start_path, status: :unprocessable_entity
    end
  end

  def occasion_post
    authorize @video, :occasion_post?, policy_class: VideoPolicy
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
    authorize @video, :destinataire_post?, policy_class: VideoPolicy
    @vd = @video.video_destinataires.new(genre: params[:sexe_destinataire])
    @video.stop_at = @video.next_step

    if @video.validate_destinataire(@vd) && @vd.save && @video.save
      redirect_to send("#{@video.next_step}_path")
    else
      @video.update(stop_at: @video.current_step)
      render destinataire_path, status: :unprocessable_entity
    end
  end

  def info_destinataire
    authorize @video, :info_destinataire?, policy_class: VideoPolicy
  end

  def info_destinataire_post
    authorize @video, :info_destinataire_post?, policy_class: VideoPolicy
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
    authorize @video, :date_fin_post?, policy_class: VideoPolicy
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
    authorize @video, :introduction_post?, policy_class: VideoPolicy
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
    authorize @video, :photo_intro_post?, policy_class: VideoPolicy
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
    authorize @video, :select_chapters?, policy_class: VideoPolicy
  end

  def select_chapters_post
    authorize @video, :select_chapters_post?, policy_class: VideoPolicy
    # On authorize que certain parametre
    params_allow = params.permit(chapters: %i[select text slide_color text_family text_style text_size])["chapters"]

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
            text: v["text"],
            slide_color: v["slide_color"],
            text_family: v["text_family"],
            text_style: v["text_style"],
            text_size: v["text_size"]
          }
        end
      elsif v["select"] == "true"
        # Si l'élément est bien séléctionné
        chapter_to_create.append({ chapter_type_id: k, text: v["text"],
                                   slide_color: v["slide_color"], text_family: v["text_family"],
                                   text_style: v["text_style"], text_size: v["text_size"]})
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
    authorize @video, :music_post?, policy_class: VideoPolicy
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
    authorize @video, :dedicace_post?, policy_class: VideoPolicy
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
    authorize @video, :share_post?, policy_class: VideoPolicy
    # Le mailer fonctionne mais pas le join
    email = params[:email]
    if email.blank?
      flash[:alert] = "Un email doit être indiqué pour envoyer l'invitation."
      return render share_path, status: :unprocessable_entity
    end

    # create Collab obj
    collab_user = User.find_by_email(params[:email])
    if collab_user == @video.user
      flash[:alert] = "Il s'agit de l'e-mail du créateur du projet, veuillez utiliser l'e-mail correct."
      return render share_path, status: :unprocessable_entity
    end

    @video.update(video_type: :colab) #update to collab if was solo before
    collaboration = Collaboration.create!(
      video: @video,
      inviting_user: current_user,
      invited_email: params[:email],
      invited_user: collab_user # may be nil if user doesn't exist yet
    )

    InvitationMailer.with(url: join_url(@video.token), email:).send_invitation.deliver_later
    flash[:notice] = "Invitation envoyé."
    redirect_to share_path
  end

  def join
    if current_user.present? && @video.user != current_user
      @video.update(video_type: :colab) #update to collab if was solo before
      @existing_collaboration = Collaboration.find_by(
        video: @video,
        invited_user: current_user
      )
      if @existing_collaboration.nil?
        collaboration = Collaboration.create!(
          video: @video,
          inviting_user: @video.user,
          invited_email: current_user.email,
          invited_user: current_user
        )
      end
    else
      session[:collab_video_id] = @video.id # Store the video ID for later redirection
      redirect_to new_user_session_path
    end
  end

  def skip_share
    # authorize @video, :skip_share?
    skip_element(share_path)
  end

  def content_post
    authorize @video, :content_post?, policy_class: VideoPolicy
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

    # Handle ordering for photos
    if params[:images_order].present?
      image_ids = parse_order(params[:images_order], @video_chapter.photos)
      @video_chapter.ordered_images_ids = image_ids
      @video_chapter.save
    end

    # Handle ordering for videos
    if params[:videos_order].present?
      video_ids = parse_order(params[:videos_order], @video_chapter.videos)
      @video_chapter.ordered_videos_ids = video_ids
      @video_chapter.save
    end

    flash[:notice] = "Content added."
    redirect_to content_path
  end

  def skip_content
    # authorize @video, :skip_content?
    skip_element(content_path)
  end

  def content_dedicace
    authorize @video, :content_dedicace?, policy_class: VideoPolicy
    # Check if a refresh has been requested
    if params[:refresh]
      # Update the status to processing
      @video.update!(concat_status: :processing)

      # Purge existing final video attachments
      @video.final_video.purge if @video.final_video.attached?
      @video.final_video_xml.purge if @video.final_video_xml.attached?

      # Enqueue the job to process the video again
      ContentDedicaceJob.perform_later(@video.id)
      flash[:notice] = "Le traitement de la vidéo a été relancé en arrière-plan."

      # Redirect to the same action without the refresh parameter
      redirect_to content_dedicace_path(@video) and return
    end

    # Check if the final video is already attached
    if @video.final_video.attached?
      @final_video_url = url_for(@video.final_video)
      @zip_url = url_for(@video.final_video_xml) if @video.final_video_xml.attached?
    else
      # Start processing if no final video exists
      unless @video.concat_status == 'processing' # Check if not already processing
        @video.update!(concat_status: :processing)
        ContentDedicaceJob.perform_later(@video.id)
        flash[:notice] = "Le traitement de la vidéo a été lancé en arrière-plan."
      else
        flash[:notice] = "Le traitement de la vidéo est déjà en cours."
      end
    end
  end

  def dedicace_de_fin
    authorize @video, :dedicace_de_fin?, policy_class: VideoPolicy
    @dedicace = @video.dedicace
  end

  def dedicace_de_fin_patch
    @dedicace = Dedicace.find(params[:id])
    video = Video.find_by(dedicace_id: params[:id])
    authorize video, :dedicace_de_fin_patch?, policy_class: VideoPolicy

    # position = params[:dedicace][:car_position]


    # @video.stop_at = @video.next_step

    # if @video.save
    #   redirect_to send("#{@video.next_step}_path")
    # else
    #   @video.update(stop_at: @video.current_step)
    #   render dedicace_path, status: :unprocessable_entity
    # end

    if params[:dedicace].present? &&
       params[:dedicace][:creator_end_dedication_video].present? || params[:dedicace][:creator_end_dedication_video_uploaded].present?
      file = params[:dedicace][:creator_end_dedication_video].present? ? params[:dedicace][:creator_end_dedication_video] : params[:dedicace][:creator_end_dedication_video_uploaded]
      @dedicace.creator_end_dedication_video.attach(file)
      # @dedicace.update(car_position: position)
      if @dedicace.save
        redirect_to dedicace_de_fin_path, notice: 'Video successfully updated.'
      else
        render :edit, alert: 'Failed to update video.'
      end
    else
      redirect_to dedicace_de_fin_path, alert: 'No video file provided.'
    end
  end

  def skip_dedicace_de_fin
    # authorize @video, :skip_content_dedicace?
    skip_element(dedicace_de_fin_path)
  end

  def confirmation
    authorize @video, :confirmation?, policy_class: VideoPolicy
  end

  def confirmation_post
    authorize @video, :confirmation_post?, policy_class: VideoPolicy
    # Le mailer fonctionne mais pas le join
    email = params[:email]
    if email.blank?
      flash[:alert] = "Un email doit être indiqué pour envoyer l'invitation."
      return render confirmation_path, status: :unprocessable_entity
    end

    collab_user = User.find_by_email(params[:email])
    if collab_user == @video.user
      flash[:alert] = "Il s'agit de l'e-mail du créateur du projet, veuillez utiliser l'e-mail correct."
      return render share_path, status: :unprocessable_entity
    end

    @video.update(video_type: :colab) #update to collab if was solo before
    collaboration = Collaboration.create!(
      video: @video,
      inviting_user: current_user,
      invited_email: params[:email],
      invited_user: collab_user # may be nil if user doesn't exist yet
    )

    InvitationMailer.with(url: join_url(@video.token), email:).send_invitation.deliver_later
    flash[:notice] = "Invitation envoyé."
    redirect_to confirmation_path
  end

  def skip_confirmation
    skip_element(confirmation_path)
  end

  def deadline
    authorize @video, :deadline?, policy_class: VideoPolicy
  end

  def deadline_post
    authorize @video, :deadline_post?, policy_class: VideoPolicy
    return render deadline_path, status: :unprocessable_entity if params[:end_date].blank?

    @video.end_date = DateTime.parse(params[:end_date])
    @video.stop_at = @video.next_step

    if @video.validate_date_fin && @video.save
      redirect_to send("#{@video.next_step}_path")
    else
      @video.update(stop_at: @video.current_step)
      render deadline_path, status: :unprocessable_entity
    end
  end

  def skip_deadline
    skip_element(deadline_path)
  end

  def edit_video
    authorize @video, :edit_video?, policy_class: VideoPolicy
    @chapters = @video.video_chapters.order(:order).includes(:chapter_type, videos_attachments: :blob, photos_attachments: :blob)
  end

  def edit_video_post
    authorize @video, :edit_video_post?, policy_class: VideoPolicy

    # Update the order of chapters
    if params[:chapter_order].present?
      chapter_ids = params[:chapter_order].split(',').map(&:to_i)
      chapter_ids.each_with_index do |id, index|
        chapter = @video.video_chapters.find_by(id: id)
        chapter.update(order: index + 1) if chapter
      end
    end

    # Update text and music for each chapter
    params[:chapters]&.each do |chapter_id, chapter_data|
      chapter = @video.video_chapters.find_by(id: chapter_id)
      next unless chapter

      # Update the text
      chapter.update(text: chapter_data[:text]) if chapter_data[:text].present?

      # Update or create the associated video_music record
      if chapter_data[:music_id].present?
        if chapter.video_music.present?
          chapter.video_music.update(music_id: chapter_data[:music_id])
        else
          chapter.create_video_music(music_id: chapter_data[:music_id])
        end
      end
    end

    redirect_to edit_video_path, notice: 'Video chapters reordered successfully'
  end

  def payment

  end

  def skip_edit_video
    # authorize @video, :skip_content_dedicace?
    skip_element(edit_video_path)
  end

  def delete_video_chapter
    video_chapter = VideoChapter.find(params[:id]) # Use the appropriate ID from the params
    authorize video_chapter.video, :delete_video_chapter?, policy_class: VideoPolicy
    if video_chapter.destroy
      respond_to do |format|
        format.html { redirect_to edit_video_path, notice: 'Chapter deleted successfully.' }
        format.json { render json: { message: 'Chapter deleted successfully' }, status: :ok }
      end
    else
      respond_to do |format|
        format.html { redirect_to edit_video_path, alert: 'Failed to delete the chapter.' }
        format.json { render json: { error: 'Failed to delete the chapter' }, status: :unprocessable_entity }
      end
    end
  end

  def get_video_duration(video_path)
    # authorize @video, :get_video_duration?
    output = `ffprobe -i #{video_path} -show_entries format=duration -v quiet -of csv="p=0"`
    output.strip
  end

  def content_dedicace_post
    authorize @video, :content_dedicace_post?, policy_class: VideoPolicy
    params[:contents].each do |file|
      dc = @video.dedicace_contents.create(position: @video.dedicace_contents.count)
      dc.content.attach(file)
    end

    flash[:notice] = "Contenu ajouté."
    redirect_to content_dedicace_path
  end

  def skip_content_dedicace
    # authorize @video, :skip_content_dedicace?
    skip_element(content_dedicace_path)
  end

  def update_video_music_type
    @video = Video.find(params[:id])
    authorize @video, :update_video_music_type?, policy_class: VideoPolicy

    if @video.update(music_type: params[:video][:music_type])
      head :no_content # Respond with a 204 No Content status to avoid template rendering
    else
      render plain: "Failed to update music type", status: :unprocessable_entity
    end
  end

  def concat_status
    video = Video.find(params[:id])
    authorize video, :concat_status?, policy_class: VideoPolicy
    render json: { concat_status: video.concat_status }
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
    @video = current_user.videos.where.not(project_status: [:finished, :closed]).order(created_at: :desc).first
    # On check si une vidéo existe
    if @video.nil?
      redirect_to start_path, alert: "Aucune vidéo trouvé." unless request.path == start_path
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
      SELECT DISTINCT "chapter_types".id, "chapter_types".created_at, "video_chapters".text, "video_chapters".slide_color, "video_chapters".text_family, "video_chapters".text_style, "video_chapters".text_size
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
      { ct: chapter_types_h[k["id"]], text: k["text"],
        slide_color: k["slide_color"], text_family: k["text_family"],
        text_style: k["text_style"], text_size: k["text_size"],
        select: k["text"].present? }
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

  # Helper method to parse order and ensure matching with attachment IDs
  def parse_order(order_param, attachments)
    order_param.split(',').map do |filename|
      attachments.find { |attachment| attachment.blob.filename.to_s == filename }&.blob_id
    end.compact
  end
end

