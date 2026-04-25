import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["content", "expandButton", "collapseButton", "gradient"]
  static values = { expanded: Boolean }
  
  connect() {
    this.expandedValue = false
    // Check if content overflows (more than 2 lines)
    if (this.contentTarget.scrollHeight <= this.contentTarget.clientHeight) {
      // Content fits, hide expand button and gradient
      this.expandButtonTarget.classList.add("hidden")
      this.gradientTarget.classList.add("hidden")
    }
  }
  
  expand() {
    this.expandedValue = true
    this.contentTarget.classList.remove("max-h-[3rem]", "overflow-hidden")
    this.contentTarget.classList.add("max-h-[65vh]", "overflow-y-auto")
    this.expandButtonTarget.classList.add("hidden")
    this.collapseButtonTarget.classList.remove("hidden")
    this.gradientTarget.classList.add("hidden")
  }
  
  collapse() {
    this.expandedValue = false
    this.contentTarget.classList.add("max-h-[3rem]", "overflow-hidden")
    this.contentTarget.classList.remove("max-h-[65vh]", "overflow-y-auto")
    this.expandButtonTarget.classList.remove("hidden")
    this.collapseButtonTarget.classList.add("hidden")
    this.gradientTarget.classList.remove("hidden")
  }
}