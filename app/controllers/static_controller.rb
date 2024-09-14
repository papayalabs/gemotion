class StaticController < ApplicationController
  def home
  end

  def flush_and_reseed
    DatabaseCleaner.allow_production = true
    DatabaseCleaner.strategy = :truncation
    DatabaseCleaner.clean
    Rails.application.load_tasks
    Rake::Task['db:seed'].invoke
    redirect_to root_path, notice: 'La base de données a été réinitialisée avec succès.'
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
