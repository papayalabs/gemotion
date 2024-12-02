pin "application"
pin "@hotwired/turbo-rails", to: "turbo.min.js"
pin "@hotwired/stimulus", to: "stimulus.min.js"
pin "@hotwired/stimulus-loading", to: "stimulus-loading.js"
pin_all_from "app/javascript/controllers", under: "controllers"
pin 'swiper', to: 'https://cdn.jsdelivr.net/npm/swiper@11/swiper-bundle.min.mjs'
pin "wavesurfer.js" # @7.8.9
