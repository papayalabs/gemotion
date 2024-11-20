class ProjectPolicy < ApplicationPolicy
  attr_reader :user, :video

  def initialize(user, video)
    @user = user
    @video = video
  end

  def participants_progress?
    @user.present? && @video.user_id == @user.id
  end

  def creator_update_date?; participants_progress?; end
  def delete_collaboration?; participants_progress?; end
  def modify_deadline?; participants_progress?; end
  def close_project?; participants_progress?; end

  def collaborator_video_details?
    @user.present? && @video.collaborations.exists?(invited_user_id: @user.id)
  end

  def collaborator_manage_chapters?; collaborator_video_details?; end

  def collaborator_chapters_post?; collaborator_video_details?; end

  def edit_collaborator_chapters_post?; collaborator_video_details?; end

  def delete_collaborator_chapter?; collaborator_video_details?; end

  def collaborator_manage_dedicace?; collaborator_video_details?; end
  def collaborator_dedicace_de_fin_post?; collaborator_video_details?; end

  def creator_manage_chapters?; participants_progress?; end
  def creator_manage_dedicace?; participants_progress?; end
  def creator_chapters_post?; participants_progress?; end
  def edit_creator_chapters_post?; participants_progress?; end
  def delete_creator_chapter?; participants_progress?; end
  def creator_dedicace_de_fin_post?; participants_progress?; end
end