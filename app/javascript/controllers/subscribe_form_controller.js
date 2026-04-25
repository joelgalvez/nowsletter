import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["container", "backdrop", "arrow", "content"]
  static values = { folded: Boolean }

  connect() {
    // Restore folded state from localStorage (default is unfolded/open)
    const savedState = localStorage.getItem('subscribeFormFolded')
    this.foldedValue = savedState === 'true'

    // Disable transitions for initial state
    this.containerTarget.style.transition = "none"
    this.backdropTarget.style.transition = "none"
    this.contentTarget.style.transition = "none"

    // Apply the saved state
    if (!this.foldedValue) {
      this.applyUnfoldedState()
    }
    // Otherwise keep the default folded state from HTML (already applied)

    // Make visible and re-enable transitions
    this.element.style.visibility = "visible"
    setTimeout(() => {
      this.containerTarget.style.transition = ""
      this.backdropTarget.style.transition = ""
      this.contentTarget.style.transition = ""
    }, 0)

    // Disable transitions during window resize
    this.resizeTimeout = null
    this.handleResize = () => {
      this.containerTarget.style.transition = "none"
      this.backdropTarget.style.transition = "none"
      this.contentTarget.style.transition = "none"

      clearTimeout(this.resizeTimeout)
      this.resizeTimeout = setTimeout(() => {
        this.containerTarget.style.transition = ""
        this.backdropTarget.style.transition = ""
        this.contentTarget.style.transition = ""
      }, 100)
    }

    window.addEventListener('resize', this.handleResize)
  }

  disconnect() {
    window.removeEventListener('resize', this.handleResize)
  }

  applyFoldedState() {
    this.containerTarget.style.height = "3rem"
    this.containerTarget.style.top = "calc(100vh - 3rem)"
    this.backdropTarget.style.opacity = "0"
    this.backdropTarget.style.pointerEvents = "none"
    this.arrowTarget.querySelector("svg").style.transform = "rotate(180deg)"
    this.contentTarget.style.paddingTop = "0"
  }

  applyUnfoldedState() {
    this.containerTarget.style.height = "50%"
    this.containerTarget.style.top = "50%"
    this.backdropTarget.style.opacity = "1"
    this.backdropTarget.style.pointerEvents = "auto"
    this.arrowTarget.querySelector("svg").style.transform = "rotate(0deg)"
    this.contentTarget.style.paddingTop = "2rem"
  }

  handleContainerClick(event) {
    // Only unfold if currently folded and not clicking the arrow button
    if (this.foldedValue && !this.arrowTarget.contains(event.target)) {
      this.unfold()
    }
  }

  toggle() {
    if (this.foldedValue) {
      this.unfold()
    } else {
      this.fold()
    }
  }

  fold() {
    this.foldedValue = true
    localStorage.setItem('subscribeFormFolded', 'true')
    this.applyFoldedState()
    this.containerTarget.style.cursor = "pointer"
  }

  unfold() {
    this.foldedValue = false
    localStorage.setItem('subscribeFormFolded', 'false')
    this.applyUnfoldedState()
    this.containerTarget.style.cursor = "auto"
  }
}
