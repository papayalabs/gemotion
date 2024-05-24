import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  copy(e) {
    navigator.clipboard.writeText(e.params.value)
  }
}