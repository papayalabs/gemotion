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
    authorize @video, :participants_progress?, policy_class: ProjectPolicy
    @participants = Collaboration.where(video_id: @video.id).includes(:invited_user)
    @final_video_url = url_for(@video.final_video)

    # Optionally, you can also filter out the inviting user if needed
    # @participants.reject! { |collab| collab.inviting_user == @video.user }
  end

  def creator_update_date
    if @video.update(end_date: params[:end_date])
      authorize @video, :creator_update_date?, policy_class: ProjectPolicy
      redirect_to project_path(@video), notice: "La date limite a été mise à jour avec succès."
    else
      flash.now[:alert] = "Une erreur est survenue. Veuillez réessayer."
      render :show
    end
  end

  def delete_collaboration
    collaboration = Collaboration.find(params[:id]) # Use the appropriate ID from the params
    video = Video.find(collaboration.video_id)
    authorize video, :delete_collaboration?, policy_class: ProjectPolicy
    if collaboration.inviting_user == current_user || collaboration.invited_user == current_user
      collaboration.destroy
      redirect_to participants_progress_path(video_id: video.id), notice: 'Collaboration deleted successfully.'
    else
      redirect_to participants_progress_path(video_id: video.id), alert: 'You are not authorized to delete this collaboration.'
    end
  end
end
