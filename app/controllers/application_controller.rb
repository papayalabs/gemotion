class ApplicationController < ActionController::Base
  include Pundit::Authorization
  rescue_from Pundit::NotAuthorizedError, with: :user_not_authorized
  before_action :configure_permitted_parameters, if: :devise_controller?

  private

  def user_not_authorized
    flash[:alert] = "You are not authorized to perform this action."
    redirect_to(request.referer || root_path)
  end

  protected

  def configure_permitted_parameters
    devise_parameter_sanitizer.permit(:sign_up, keys: [:first_name, :last_name, :phone])
    devise_parameter_sanitizer.permit(:account_update, keys: [:first_name, :last_name, :phone, :reset_password_token])
  end

  def after_sign_in_path_for(resource)
    video_id = session.delete(:collab_video_id) # Retrieve and clear the session
    begin
      video = Video.find(video_id) if video_id.present?
    rescue ActiveRecord::RecordNotFound
      video = nil  # If not found, set video to nil
    end

    if video.present? && video.token.present?
      video_token = video.token
      join_path(video_token)  # Redirect to join path with token
    else
      super  # Default redirect (can be to root or another path)
    end
  end

  def after_sign_up_path_for(resource)
    after_sign_in_path_for(resource)
  end
end
