import { Controller } from "@hotwired/stimulus"

// Connects to data-controller="dialog"
export default class extends Controller {
  static targets = ["modal"]
  connect() {
  }

  open() {
    // this.modalTarget.show();
    this.modalTarget.showModal();
    document.body.classList.add("overflow-hidden")
  }

  close() {
      this.modalTarget.close();
      document.body.classList.remove("overflow-hidden")
  }

  clickOutside(event) {
    if (event.target === this.modalTarget) {
      this.modalTarget.close();
      document.body.classList.remove("overflow-hidden")
    }
  }
}