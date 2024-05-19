import { Controller } from "@hotwired/stimulus";

export default class extends Controller {
  static targets = ["video", "select"];

  initialize() {
    this.video = null;
  }

  connect() {
    this.video_switcher();
  }

  video_switcher() {
    const current_selection = this.selectTarget.value;
    const video = this.videoTargets.find(
      (el) => el.getAttribute("data-switchvideo-info") === current_selection
    );
    if (!video) return;
    this.disable_video();
    this.video = video;
    video.classList.remove("hidden");
  }

  disable_video() {
    if (!this.video) return;
    this.video.classList.add("hidden");
  }
}
