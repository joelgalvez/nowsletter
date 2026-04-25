import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["dialog"]

  connect() {
    this.boundKeydown = this.handleKeydown.bind(this)
    document.addEventListener("keydown", this.boundKeydown)

    // Watch the turbo frame for content changes (from turbo_stream updates)
    const frame = this.element.querySelector("turbo-frame")
    if (frame) {
      this.observer = new MutationObserver(() => {
        if (frame.innerHTML.trim().length === 0 && this.dialogTarget.open) {
          this.dialogTarget.close()
        }
      })
      this.observer.observe(frame, { childList: true })
    }
  }

  disconnect() {
    document.removeEventListener("keydown", this.boundKeydown)
    if (this.observer) this.observer.disconnect()
  }

  handleKeydown(event) {
    if (event.key === "Escape" && this.dialogTarget.open) {
      event.preventDefault()
      this.close()
    }
  }

  // Called via turbo:frame-load when a link navigates into the frame
  frameLoaded() {
    const frame = this.element.querySelector("turbo-frame")
    if (frame && frame.innerHTML.trim().length > 0) {
      this.dialogTarget.showModal()
    }
  }

  close() {
    this.dialogTarget.close()
    const frame = this.element.querySelector("turbo-frame")
    if (frame) frame.innerHTML = ""
  }

  closeOnBackdrop(event) {
    if (event.target === this.dialogTarget) {
      this.close()
    }
  }
}
