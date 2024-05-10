Rails.application.routes.draw do

  # Video
  get 'videos/start', to: "videos#start", as: "start"
  post 'videos/start', to: "videos#start_post", as: "start_post"

  get 'videos/occasion', to: "videos#occasion", as: "occasion"
  post 'videos/occasion', to: "videos#occasion_post", as: "occasion_post"

  get 'videos/destinataire', to: "videos#destinataire", as: "destinataire"
  post 'videos/destinataire', to: "videos#destinataire_post", as: "destinataire_post"

  # Static pages
  get 'about', to: 'static#about', as: "about"
  get 'prices', to: 'static#prices', as: "price"

  # Reveal health status on /up that returns 200 if the app boots with no exceptions, otherwise 500.
  # Can be used by load balancers and uptime monitors to verify that the app is live.
  get "up" => "rails/health#show", as: :rails_health_check

  # Defines the root path route ("/")
  root "static#home"
end
