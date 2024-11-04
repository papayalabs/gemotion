class ApplicationController < ActionController::Base
  before_action :configure_permitted_parameters, if: :devise_controller?

  protected

  def configure_permitted_parameters
    devise_parameter_sanitizer.permit(:sign_up, keys: [:first_name, :last_name, :phone])
    devise_parameter_sanitizer.permit(:account_update, keys: [:first_name, :last_name, :phone, :reset_password_token])
  end

  def after_sign_in_path_for(resource)
    video_id = session.delete(:collab_video_id) # Retrieve and clear the session
    video_token = Video.find(video_id).token if video_id.present?
    video_id ? join_path(video_token) : super # Redirect to join path if video_id exists
  end

  def after_sign_up_path_for(resource)
    after_sign_in_path_for(resource)
  end
end
