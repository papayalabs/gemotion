class ProjectsController < ApplicationController
  before_action :authenticate_user!
  before_action :find_video, only: %i[participants_progress collaborator_video_details modify_deadline close_project
                                      collaborator_manage_chapters collaborator_manage_dedicace creator_manage_chapters
                                      creator_manage_dedicace collaborator_dedicace_de_fin_post]
  before_action :find_destinataire, only: %i[collaborator_video_details collaborator_manage_dedicace]
  def as_creator_projects
    @creator_projects = current_user.videos.left_joins(:video_previews)
                                            .where.not(project_status: [:finished, :closed])
                                            .where("video_previews.order = 1 OR video_previews.order IS NULL")
                                            .select("videos.*, COALESCE(video_previews.id, NULL) AS video_preview_id, COALESCE(video_previews.preview_id, NULL) AS preview_id")
  end

  def as_collaborator_projects
    @collaborator_projects = Video.joins(:collaborations)
                                  .left_joins(:video_previews)
                                  .where(collaborations: { invited_user: current_user })
                                  .where.not(project_status: [:finished, :closed])
                                  .where(video_previews: { order: 1 })
                                  .select("videos.*, video_previews.id AS video_preview_id, video_previews.preview_id AS preview_id")
  end

  def participants_progress
    authorize @video, :participants_progress?, policy_class: ProjectPolicy
    @participants = Collaboration.where(video_id: @video.id).includes(:invited_user)
    @final_video_url = @video&.final_video&.attached? ? url_for(@video.final_video) : nil

    # Optionally, you can also filter out the inviting user if needed
    # @participants.reject! { |collab| collab.inviting_user == @video.user }
  end

  def collaborator_video_details
    authorize @video, :collaborator_video_details?, policy_class: ProjectPolicy
    collaboration = Collaboration.find_by(video: @video, invited_user: current_user)
    @collaborator_dedicace = CollaboratorDedicace.find_by(video: @video, collaboration: collaboration)
    @collaborator_chapters = CollaboratorChapter.where(video: @video, collaboration: collaboration)
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

  def modify_deadline
    authorize @video, :modify_deadline?, policy_class: ProjectPolicy
    if @video.update(end_date: params[:end_date])
      redirect_to participants_progress_path(video_id: @video.id), notice: "La date limite a été mise à jour avec succès."
    else
      flash.now[:alert] = "Une erreur est survenue. Veuillez réessayer."
      render :show
    end
  end

  def close_project
    authorize @video, :close_project?, policy_class: ProjectPolicy
    if @video.update!(project_status: :closed)
      redirect_to as_creator_projects_path, notice: "Vous avez clôturé votre projet. Mais nous serons toujours ravis de vous revoir !"
    else
      flash.now[:alert] = "Une erreur est survenue. Veuillez réessayer."
      render :show
    end
  end

  def collaborator_manage_chapters
    authorize @video, :collaborator_manage_chapters?, policy_class: ProjectPolicy

  end

  def collaborator_chapters_post

  end

  def collaborator_manage_dedicace
    authorize @video, :collaborator_manage_dedicace?, policy_class: ProjectPolicy
    @dedicaces = Dedicace.all
    collaboration = Collaboration.find_by(video_id: @video.id, invited_user: current_user)
    @collaborator_dedicace = CollaboratorDedicace.find_by(video_id: @video.id, collaboration: collaboration)
  end

  def collaborator_dedicace_de_fin_post
    authorize @video, :collaborator_manage_dedicace?, policy_class: ProjectPolicy

    collaboration = Collaboration.find_by(video_id: params[:video_id], invited_user: current_user)
    unless collaboration
      flash[:alert] = "Collaboration not found"
      return redirect_to collaborator_manage_dedicace_path(@video.id)
    end

    collaborator_dedicace = CollaboratorDedicace.find_or_initialize_by(
      video_id: @video.id,
      collaboration: collaboration
    )
    collaborator_dedicace.dedicace_id = params[:collaborator_dedicace]

    if params[:creator_end_dedication_video].present?
      collaborator_dedicace.creator_end_dedication_video.attach(params[:creator_end_dedication_video])
    elsif params[:creator_end_dedication_video_uploaded].present?
      collaborator_dedicace.creator_end_dedication_video.attach(params[:creator_end_dedication_video_uploaded])
    end

    if collaborator_dedicace.save
      VideoProcessingJob.perform_later(collaborator_dedicace.id, "CollaboratorDedicace")
      flash[:notice] = "Collaborator Dedicace successfully created!"
    else
      flash[:alert] = "Failed to create Collaborator Dedicace: #{collaborator_dedicace.errors.full_messages.to_sentence}"
    end

    redirect_to collaborator_manage_dedicace_path(@video.id)
  end

  def creator_manage_chapters
    authorize @video, :creator_manage_chapters?, policy_class: ProjectPolicy

  end

  def creator_manage_dedicace
    authorize @video, :creator_manage_dedicace?, policy_class: ProjectPolicy

  end


  private
  def find_video
    @video = Video.find(params[:video_id].present? ? params[:video_id] : params[:id])
  end

  def find_destinataire
    @destinataire = @video.video_destinataire
  end
end
