class VideoPolicy < ApplicationPolicy
  attr_reader :user, :video

  def initialize(user, video)
    @user = user
    @video = video
  end

  def start_post?
    @user.present? && @video.user_id == @user.id
  end

  def occasion?; start_post?; end
  def occasion_post?; start_post?; end
  def destinataire?; start_post?; end
  def destinataire_post?; start_post?; end
  def info_destinataire?; start_post?; end
  def info_destinataire_post?; start_post?; end
  def date_fin?; start_post?; end
  def date_fin_post?; start_post?; end
  def introduction?; start_post?; end
  def introduction_post?; start_post?; end
  def photo_intro?; start_post?; end
  def photo_intro_post?; start_post?; end
  def select_chapters?; start_post?; end
  def select_chapters_post?; start_post?; end
  def music?; start_post?; end
  def music_post?; start_post?; end
  def update_video_music_type?; start_post?; end
  def dedicace?; start_post?; end
  def dedicace_post?; start_post?; end
  def share?; start_post?; end
  def share_post?; start_post?; end
  def skip_share?; start_post?; end
  def content?; start_post?; end
  def content_post?; start_post?; end
  def skip_content?; start_post?; end
  def content_dedicace?; start_post?; end
  def content_dedicace_post?; start_post?; end
  def skip_content_dedicace?; start_post?; end
  def dedicace_de_fin?; start_post?; end
  def dedicace_de_fin_post?; start_post?; end
  def skip_dedicace_de_fin?; start_post?; end
  def confirmation?; start_post?; end
  def confirmation_post?; start_post?; end
  def skip_confirmation?; start_post?; end
  def deadline?; start_post?; end
  def deadline_post?; start_post?; end
  def skip_deadline?; start_post?; end
  def edit_video?; start_post?; end
  def edit_video_post?; start_post?; end
  def payment?; start_post?; end
  def payment_post?; start_post?; end
  def render_final_page?
    @user.present? && @video.user_id == @user.id && @video.paid
  end
  def delete_video_chapter?; start_post?; end
  def purge_chapter_attachment?; start_post?; end
  def concat_status?; start_post?; end
  def go_back?; start_post?; end
  # def join?; start_post?; end
end