import { Controller } from "@hotwired/stimulus";

export default class extends Controller {
  static targets = ["video", "radio", "theme"];

  connect() {
    this.currentVideo = null;
    this.updateVideo(); // Initialize with the pre-selected theme
  }

  updateVideo(event) {
    const clickedElement = event?.currentTarget || null; // Ensure event is defined
    if (!clickedElement) return;

    const selectedRadio = clickedElement.querySelector("input[type='radio']");
    if (!selectedRadio) return;

    const selectedValue = selectedRadio.value;

    // Mark the clicked radio button as checked
    selectedRadio.checked = true;

    // Highlight the selected theme
    this.themeTargets.forEach((theme) => {
      theme.classList.toggle("selected", theme.dataset.theme === selectedValue);
    });

    // Find and display the corresponding video
    const matchingVideo = this.videoTargets.find(
      (video) => video.dataset.switchvideoInfo === selectedValue
    );

    if (!matchingVideo) return;

    this.hideAllVideos();
    this.currentVideo = matchingVideo;
    this.showVideo(matchingVideo);
  }

  hideCurrentVideo() {
    if (this.currentVideo) {
      this.currentVideo.classList.add("hidden");
    }
  }

  hideAllVideos() {
    this.videoTargets.forEach((video) => {
      video.classList.add("hidden");
    });
  }

  showVideo(video) {
    video.classList.remove("hidden");
  }
}