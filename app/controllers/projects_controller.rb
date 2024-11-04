class ProjectsController < ApplicationController
  before_action :authenticate_user!

  def as_creator_projects
    @creator_projects = Video.where(user_id: current_user.id)
  end

  def as_collaborator_projects
    @collaborator_projects = Collaboration.where(invited_user: current_user).includes(:video).map(&:video)
  end

  def participants_progress
    @video = Video.find(params[:video_id])
    @participants = Collaboration.where(video_id: @video.id).includes(:invited_user)

    # Optionally, you can also filter out the inviting user if needed
    # @participants.reject! { |collab| collab.inviting_user == @video.user }
  end

  def creator_update_date
    if @video.update(end_date: params[:end_date])
      redirect_to project_path(@video), notice: "La date limite a été mise à jour avec succès."
    else
      flash.now[:alert] = "Une erreur est survenue. Veuillez réessayer."
      render :show
    end
  end
end
