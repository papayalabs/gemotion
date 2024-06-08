// Configure your import map in config/importmap.rb. Read more: https://github.com/rails/importmap-rails
import "@hotwired/turbo-rails";
import "controllers";

import Swiper from "swiper/bundle";
import "swiper/swiper-bundle.css";

const { environment } = require("@rails/webpacker");
const webpack = require("webpack");

// Ajouter une configuration supplémentaire si nécessaire

module.exports = environment;
