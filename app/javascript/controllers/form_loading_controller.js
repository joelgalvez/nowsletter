import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["overlay", "submit"]

  showLoading() {
    this.overlayTarget.style.display = "flex"

    // Disable submit buttons to prevent double submission
    this.submitTargets.forEach(button => {
      button.disabled = true
      button.classList.add("opacity-50", "cursor-not-allowed")
    })
  }

  hideLoading() {
    this.overlayTarget.style.display = "none"

    // Re-enable submit buttons
    this.submitTargets.forEach(button => {
      button.disabled = false
      button.classList.remove("opacity-50", "cursor-not-allowed")
    })
  }
}
