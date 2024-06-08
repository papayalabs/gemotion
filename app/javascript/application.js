import "@hotwired/turbo-rails";
import "controllers";
import { Swiper, Navigation, Pagination } from "./swiper-bundle.min.js";
import "swiper/swiper-bundle.min.css";

document.addEventListener("turbo:load", function () {
  Swiper.use([Navigation, Pagination]);

  const swiper = new Swiper(".swiper-container", {
    slidesPerView: 1,
    spaceBetween: 10,
    pagination: {
      el: ".swiper-pagination",
      clickable: true,
    },
    navigation: {
      nextEl: ".swiper-button-next",
      prevEl: ".swiper-button-prev",
    },
  });
});
