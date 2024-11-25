class StaticController < ApplicationController
  def home
  end

  def flush_and_reseed
    VideoDestinataire.destroy_all
    Video.destroy_all
    Collaboration.destroy_all
    redirect_to root_path, notice: 'Reinitialisation effectuée.'
  end

  private

  def authenticate_admin!
    # Votre logiqued'authentification ici, par exemple :
    # redirect_to new_user_session_path unless current_user.admin?
  end

  def about
  end

  def pricing
  end

  def contact

  end

end
