import "@hotwired/turbo-rails";
import "controllers";

// Import Swiper and modules
import Swiper, { Navigation, Pagination } from "swiper";

document.addEventListener("turbo:load", function () {
  const swiper = new Swiper(".swiper-container", {
    modules: [Navigation, Pagination],
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
