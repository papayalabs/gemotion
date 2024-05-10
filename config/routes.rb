Rails.application.routes.draw do
  get 'static/home'
  get 'static/about'
  get 'static/prices'


  # Static pages
  get 'about', to: 'static#about', as: "about"
  get 'prices', to: 'static#prices', as: "price"

  # Reveal health status on /up that returns 200 if the app boots with no exceptions, otherwise 500.
  # Can be used by load balancers and uptime monitors to verify that the app is live.
  get "up" => "rails/health#show", as: :rails_health_check

  # Defines the root path route ("/")
  root "static#home"
end
