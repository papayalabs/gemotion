class VideosController < ApplicationController
  before_action :select_video, except: %i[ start start_post go_back join]
  before_action :define_chapter_type, only: %i[select_chapters select_chapters_post]
  before_action :define_music, only: %i[music music_post]
  before_action :define_dedicace, only: %i[dedicace dedicace_post]
  before_action :select_join_video, only: %i[join]
  before_action :define_video_chapters, only: %i[content content_post]

  def start
    #TODO: with last user
    @video = Video.last
    unless @video.nil?
      redirect_to send("#{@video.next_step()}_path"), notice: "Reprenez votre vidéo en cours."
    end
    # TODO: delete current video if user confirmation
  end

  ##
  # Cette méthode pose problème si l'on utilise turbo car le préchargement
  # provoque le recul en arrière. Il faut donc desactiver turbo sur les liens
  # souhaitant ce servir de step_back_path.
  # Utilise le template dans videos/shared/_back_button.html.erb pour récupérer
  # un lien fonctionnel
  def go_back
    #TODO: change with current_user.videos.last
    @video = Video.last
    if @video.nil?
      redirect_to start_path, alert: "Aucune vidéo trouvé."
    end

    @video.stop_at = @video.previous_step
    if @video.save()
      redirect_to send("#{@video.current_step()}_path")
    else
      redirect_to send("#{@video.current_step()}_path"), alert: "Impossible de revenir en arrière"
    end
  end

  def start_post
    # Creation d'une nouvelle vidéo
    @video = Video.new
    if params[:video_type].nil?
      return render start_path, status: :unprocessable_entity
    end
    # Le type de la vidéo depuis le radio button du formulaire
    @video.video_type = params[:video_type].downcase
    # On est à la première étape de la vidéo
    @video.stop_at = @video.way.first
    # Generate the unique identifier of the video
    @video.generate_token

    # Validate and create the video
    if @video.validate_start() && @video.save()
      redirect_to send("#{@video.next_step()}_path")
    else
      render start_path, status: :unprocessable_entity
    end
  end

  def occasion_post
   @video.occasion = params[:occasion]
   @video.stop_at = @video.next_step()

   if @video.validate_occasion() && @video.save()
      redirect_to send("#{@video.next_step()}_path")
   else
      @video.update(stop_at: @video.current_step)
      render occasion_path, status: :unprocessable_entity
   end
  end

  def destinataire_post
    @vd = @video.video_destinataires.new(genre: params[:sexe_destinataire])
    @video.stop_at = @video.next_step()

   if @video.validate_destinataire(@vd) && @vd.save() && @video.save()
      redirect_to send("#{@video.next_step()}_path")
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
    unless params[:special_request_destinataire].blank?
      @video.theme = 'specific_request'
      @video.theme_specific_request = params[:special_request_destinataire]
    end

    @video.stop_at = @video.next_step()

    if @video.validate_info_destinataire(@vd) && @vd.save() && @video.save()
      redirect_to send("#{@video.next_step()}_path")
    else
      @video.update(stop_at: @video.current_step)
      return render info_destinataire_path, status: :unprocessable_entity
    end

    unless params[:special_request_destinataire].nil?
      # TODO: send email to PO.
    end
  end


  def date_fin_post
    if params[:end_date].blank?
      return render date_fin_path, status: :unprocessable_entity
    end

    @video.end_date = DateTime.parse(params[:end_date])
    @video.stop_at = @video.next_step()

    if @video.validate_date_fin() && @video.save()
      redirect_to send("#{@video.next_step()}_path")
    else
      @video.update(stop_at: @video.current_step)
      return render date_fin_path, status: :unprocessable_entity
    end
  end

  def introduction_post
    @video.theme = params[:theme]
    @video.theme_specific_request = params[:special_request]
    @video.stop_at = @video.next_step()
    if @video.validate_introduction() && @video.save()
      redirect_to send("#{@video.next_step()}_path")
    else
      @video.update(stop_at: @video.current_step)
      return render introduction_path, status: :unprocessable_entity
    end
  end

  def photo_intro_post
    @video.stop_at = @video.next_step()

    if @video.validate_photo_intro() && @video.save()
      redirect_to send("#{@video.next_step()}_path")
    else
      @video.update(stop_at: @video.current_step)
      return render photo_intro_path, status: :unprocessable_entity
    end
  end

  def select_chapters
  end

  def select_chapters_post
    # On authorize que certain parametre
    params_allow = params.permit(chapters: [:select, :text])['chapters']
    
    chapter_to_create = [] # Un tableau a remplir de chapitre a créer
    chapter_to_updates = {} # Un hash a remplir de chapitre a modifier
    
    # Si le chapitre est déjà sélectionné, on doit le modifier 
    find_chapters = [] # On crée un tableau servant à la requete SQL IN pour ne récupérer que des chapitres déjà crée
    params_allow.each { |k, v| find_chapters.append(k) if v['select'] == 'true' }
    # On cherche avec la request SQL IN les video_chapters ayant déjà un chapitre lié à l'ancien
    chapter_to_updates_model = @video.video_chapters.where(chapter_type_id: find_chapters)
    chapter_to_delete = @video.video_chapters.where.not(chapter_type_id: find_chapters)
    id_chapter_type = [] # L'id uniquement des chapitre_type en relation avec les chapitres video a modifier.
    chapter_to_updates_by_chapter_type = {} # Un hash permettant de faire une recherche par le chapitre_type
    chapter_to_updates_model.each { |k| 
      id_chapter_type.append(k.chapter_type_id.to_s)
      chapter_to_updates_by_chapter_type[k.chapter_type_id.to_s] = k
    }

    # On ne se prépare à créer que les éléments qu'il faut.
    params_allow.each do |k,v|
      # Si un chapitre existe déjà avec ce type de chapitre, on ne le crée pas ...
      unless id_chapter_type.include?(k) 
        # Si l'élément est bien séléctionné
        if v['select'] == 'true'
          # On l'ajoute dans la liste des éléments à supprimer
          chapter_to_create.append({chapter_type_id: k, text: v['text']})
        end
      # ... on le modifie
      else
        # Si le chapitre est toujours sélectionné, on le modifie
        if v['select'] == 'true'
          video_chapter = chapter_to_updates_by_chapter_type[k]
          chapter_to_updates[video_chapter.id] = {
            text: v['text']
          }
        end
      end
    end

    # 12 chapitres maximum
    if (chapter_to_create.size + chapter_to_updates.size) >= 12
      flash[:alert] = "Ne sélectionnez que 12 chapitres maximum"
      return render select_chapters_path, status: :unprocessable_entity
    end
    
    # Création, Mise à jour et suppression
    if @video.video_chapters.create(chapter_to_create) && @video.video_chapters.update(chapter_to_updates.keys, chapter_to_updates.values) && chapter_to_delete.delete_all
      @video.update(stop_at: @video.next_step())
      redirect_to send("#{@video.next_step()}_path")
    else
      @video.update(stop_at: @video.current_step)
      @chapterstype = ChapterType.all
      return render select_chapters_path, status: :unprocessable_entity
    end
  end

  def music_post
    if params[:music].nil?
      flash[:alert] = "Vous devez séléctionnez une musique"
      return render music_path, status: :unprocessable_entity
    end

    # Utilisation de find_by pour avoir un objet nil si pas trouvé.
    music = Music.find_by(id: params[:music])
    if music.nil?
      flash[:alert] = "Sélection incorrecte. La musique n'existe pas."
      return render music_path, status: :unprocessable_entity
    end

    @video.music = music
    @video.stop_at = @video.next_step()

    if @video.save()
      redirect_to send("#{@video.next_step()}_path")
    else
      @video.update(stop_at: @video.current_step)
      return render music_path, status: :unprocessable_entity
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
    @video.stop_at = @video.next_step()

    if @video.save()
      redirect_to send("#{@video.next_step()}_path")
    else
      @video.update(stop_at: @video.current_step)
      return render dedicace_path, status: :unprocessable_entity
    end
  end

  def share_post
    # Le mailer fonctionne mais pas le join
    email = params[:email]
    if email.blank?
      flash[:alert] = "Un email doit être indiqué pour envoyer l'invitation."
      return render share_path, status: :unprocessable_entity
    end

    InvitationMailer.with(url: join_url(@video.token), email: email).send_invitation.deliver_later
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

  private

  def select_video
    # TODO: change when user login to current_user.videos.last
    @video = Video.last
    # On check si une vidéo existe
    if @video.nil?
      redirect_to start_path, alert: "Aucune vidéo trouvé."
    # Si une vidéo existe, on doit être sur la bonne étape
    elsif ![@video.next_step.downcase(), "#{@video.next_step.downcase()}_post", "skip_#{@video.next_step.downcase()}"].include?(params[:action].downcase())
      redirect_to send("#{@video.next_step()}_path"), alert: "Vous devez finaliser cette étape avant de passer à la prochaine."
    end
  end

  def define_chapter_type
    # On va cherche la query directement dans SQL
    q_results = ActiveRecord::Base.connection.exec_query('
      SELECT DISTINCT "chapter_types".id, "chapter_types".created_at, "video_chapters".text 
      FROM "chapter_types" 
      LEFT OUTER JOIN "video_chapters" ON "video_chapters"."chapter_type_id" = "chapter_types"."id" AND video_chapters.video_id = $1 
      ORDER BY "chapter_types".created_at ASC', 
      'selectChapterWithData', 
      [@video.id])
    # On recupere le resultat est filtre pour n'avoir que les ID de chapters_types
    r_only_id = q_results.rows.map { |v| v[0] }
    # On recupere les ChaptersType (le modèle Rails).
    chapter_types = ChapterType.where(id: r_only_id)
    # On transforme cela en hash (pour effectuer une accessation en 0(n))
    chapter_types_h = Hash[chapter_types.map { |ct| [ct.id, ct] }]

    @chapterstype = q_results.as_json.map { |k| {ct: chapter_types_h[k['id']], text: k['text'], select: !k['text'].blank? }}
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
    @video.stop_at = @video.next_step()

    if @video.save()
      redirect_to send("#{@video.next_step()}_path")
    else
      @video.update(stop_at: @video.current_step)
      return render error_path, status: :unprocessable_entity
    end
  end
end
