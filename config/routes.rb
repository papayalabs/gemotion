Rails.application.routes.draw do

  post 'flush_and_reseed', to: 'static#flush_and_reseed'
  # resources :contacts, only: [:new, :create]

  resources :contacts, only: [:new, :create]

  # Video
  get 'videos/back', to: "videos#go_back", as: "step_back"

  get 'videos/start', to: "videos#start", as: "start"
  post 'videos/start', to: "videos#start_post", as: "start_post"

  get 'videos/occasion', to: "videos#occasion", as: "occasion"
  post 'videos/occasion', to: "videos#occasion_post", as: "occasion_post"

  get 'videos/destinataire', to: "videos#destinataire", as: "destinataire"
  post 'videos/destinataire', to: "videos#destinataire_post", as: "destinataire_post"

  get 'videos/info_destinataire', to: "videos#info_destinataire", as: "info_destinataire"
  post 'videos/info_destinataire', to: "videos#info_destinataire_post", as: "info_destinataire_post"

  get 'videos/date_fin', to: "videos#date_fin", as: "date_fin"
  post 'videos/date_fin', to: "videos#date_fin_post", as: "date_fin_post"

  get 'videos/introduction', to: "videos#introduction", as: "introduction"
  post 'videos/introduction', to: "videos#introduction_post", as: "introduction_post"

  get 'videos/photo_intro', to: "videos#photo_intro", as: "photo_intro"
  post 'videos/photo_intro', to: "videos#photo_intro_post", as: "photo_intro_post"

  get 'videos/select_chapters', to: "videos#select_chapters", as: "select_chapters"
  post 'videos/select_chapters', to: "videos#select_chapters_post", as: "select_chapters_post"

  get 'videos/music', to: "videos#music", as: "music"
  post 'videos/music', to: "videos#music_post", as: "music_post"

  get 'videos/dedicace', to: "videos#dedicace", as: "dedicace"
  post 'videos/dedicace', to: "videos#dedicace_post", as: "dedicace_post"

  get 'videos/share', to: "videos#share", as: "share"
  post 'videos/share', to: "videos#share_post", as: "share_post"
  get 'videos/skip_share', to: "videos#skip_share", as: "skip_share"

  get 'videos/content', to: "videos#content", as: "content"
  post 'videos/content/:id', to: "videos#content_post", as: "content_post"
  get 'videos/skip_content', to: "videos#skip_content", as: "skip_content"

  get 'videos/content_dedicace', to: "videos#content_dedicace", as: "content_dedicace"
  post 'videos/content_dedicace', to: "videos#content_dedicace_post", as: "content_dedicace_post"
  get 'videos/skip_content_dedicace', to: "videos#skip_content_dedicace", as: "skip_content_dedicace"

  get 'join/videos/:id', to: 'videos#join', as: 'join'

  # Static pages
  get 'about', to: 'static#about', as: "about"
  get 'pricing', to: 'static#pricing', as: "pricing"

  # Reveal health status on /up that returns 200 if the app boots with no exceptions, otherwise 500.
  # Can be used by load balancers and uptime monitors to verify that the app is live.
  get "up" => "rails/health#show", as: :rails_health_check

  # Defines the root path route ("/")
  root "static#home"
end
