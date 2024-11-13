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
end