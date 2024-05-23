class VideosController < ApplicationController
  before_action :select_video, except: %i[ start start_post go_back ]
  
  def start
    #TODO: with last user
    @video = Video.last
    unless @video.nil?
      redirect_to send("#{@video.next_step()}_path"), notice: "Reprenez votre vidéo en cours."
    end
    # TODO: delete current video if user confirmation
  end

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
    @chapterstype = ChapterType.all
  end

  def select_chapters_post

  end

  private

  def select_video
    # TODO: change when user login to current_user.videos.last
    @video = Video.last
    # On check si une vidéo existe
    if @video.nil?
      redirect_to start_path, alert: "Aucune vidéo trouvé."
    # Si une vidéo existe, on doit être sur la bonne étape
    elsif ![@video.next_step.downcase(), "#{@video.next_step.downcase()}_post"].include?(params[:action].downcase())
      redirect_to send("#{@video.next_step()}_path"), alert: "Vous devez finaliser cette étape avant de passer à la prochaine."
    end
  end
end
