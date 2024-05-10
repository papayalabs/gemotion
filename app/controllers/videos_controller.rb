class VideosController < ApplicationController
  before_action :select_video, except: %i[ start start_post ]
  
  def start
    #TODO: with last user
    @video = Video.last
    unless @video.nil?
      redirect_to send("#{@video.next_step()}_path"), notice: "Reprenez votre vidéo en cours."
    end
    # TODO: delete current video if user confirmation
  end

  def start_post
    # Creation d'une nouvelle vidéo
    @video = Video.new
    # Le type de la vidéo depuis le radio button du formulaire
    @video.video_type = params[:video_type].downcase
    # On est à la première étape de la vidéo
    @video.stop_at = @video.way.first

    # Validate and create the video
    if @video.validate_start() && @video.save()
      redirect_to send("#{@video.next_step()}_path")
    else
      render 'videos/start', status: :unprocessable_entity
    end
  end

  def occasion_post
   @video.occasion = params[:occasion]
   @video.stop_at = @video.next_step()

   if @video.validate_occasion() && @video.save()
      redirect_to send("#{@video.next_step()}_path")
   else
      render 'videos/occasion', status: :unprocessable_entity
   end
  end

  def destinataire_post
    # TODO: destinataire en cours

    @video.stop_at = @video.next_step()

   if @video.validate_destinataire() && @video.save()
      redirect_to send("#{@video.next_step()}_path")
   else
      render 'videos/destinataire', status: :unprocessable_entity
   end
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
