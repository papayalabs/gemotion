class VideoPolicy < ApplicationPolicy
  attr_reader :user, :video

  def initialize(user, video)
    @user = user
    @video = video
  end

  def start_post?
    @user.present? && @video.user_id == @user.id
  end

  def occasion? = start_post?
  def occasion_post? = start_post?
  def destinataire? = start_post?
  def destinataire_post? = start_post?
  def info_destinataire? = start_post?
  def info_destinataire_post? = start_post?
  def destinataire_details? = start_post?
  def destinataire_details_post? = start_post?
  def delete_destinataire? = start_post?
  def update_destinataire? = start_post?
  def date_fin? = start_post?
  def date_fin_post? = start_post?
  def introduction? = start_post?
  def introduction_post? = start_post?
  def photo_intro? = start_post?
  def photo_intro_post? = start_post?
  def drop_preview? = start_post?
  def select_chapters? = start_post?
  def select_chapters_post? = start_post?
  def music? = start_post?
  def music_post? = start_post?
  def drop_custom_music? = start_post?
  def update_video_music_type? = start_post?
  def dedicace? = start_post?
  def dedicace_post? = start_post?
  def share? = start_post?
  def share_post? = start_post?
  def skip_share? = start_post?
  def content? = start_post?
  def content_post? = start_post?
  def skip_content? = start_post?
  def content_dedicace? = start_post?
  def content_dedicace_post? = start_post?
  def skip_content_dedicace? = start_post?
  def dedicace_de_fin? = start_post?
  def dedicace_de_fin_post? = start_post?
  def skip_dedicace_de_fin? = start_post?
  def confirmation? = start_post?
  def confirmation_post? = start_post?
  def skip_confirmation? = start_post?
  def deadline? = start_post?
  def deadline_post? = start_post?
  def skip_deadline? = start_post?
  def edit_video? = start_post?
  def edit_video_post? = start_post?
  def payment? = start_post?
  def payment_post? = start_post?

  def render_final_page?
    @user.present? && @video.user_id == @user.id && @video.paid
  end

  def delete_video_chapter? = start_post?
  def purge_chapter_attachment? = start_post?
  def concat_status? = start_post?
  def go_back? = start_post?
  def join? = start_post?
  def process_video_slot? = start_post?
  def update_video_slot? = start_post?
  def video_processing_status? = start_post?
  def get_video_slot_status? = start_post?
end
