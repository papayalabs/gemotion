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

end