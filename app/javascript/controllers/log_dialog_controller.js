import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["dialog", "title", "text", "venue", "event", "letter", "timestamp", "role", "severity"]
  
  open(event) {
    const logElement = event.currentTarget

    // Set dialog content from data attributes
    this.titleTarget.textContent = logElement.dataset.logTitle || ""
    // Convert \n to <br> for line breaks
    const logText = logElement.dataset.logText || "No additional details"
    this.textTarget.innerHTML = logText.replace(/\n/g, '<br>')
    if (this.hasVenueTarget) {
      this.venueTarget.textContent = logElement.dataset.logVenue || "N/A"
    }
    this.eventTarget.textContent = logElement.dataset.logEvent || "N/A"
    this.letterTarget.textContent = logElement.dataset.logLetter || "N/A"
    this.timestampTarget.textContent = logElement.dataset.logTimestamp || ""
    this.roleTarget.textContent = logElement.dataset.logRole || ""
    
    // Set severity with color
    const severity = logElement.dataset.logSeverity || "normal"
    this.severityTarget.textContent = severity.charAt(0).toUpperCase() + severity.slice(1)
    
    // Apply severity color class
    this.severityTarget.className = "font-medium "
    if (severity === "critical") {
      this.severityTarget.className += "text-red-600"
    } else if (severity === "high") {
      this.severityTarget.className += "text-yellow-600"
    } else {
      this.severityTarget.className += "text-gray-600"
    }
    
    // Show dialog with flex
    this.dialogTarget.classList.remove("hidden")
    this.dialogTarget.classList.add("flex")
  }
  
  close() {
    this.dialogTarget.classList.add("hidden")
    this.dialogTarget.classList.remove("flex")
  }
  
  // Close when clicking outside the dialog
  closeOnBackdrop(event) {
    if (event.target === this.dialogTarget) {
      this.close()
    }
  }
}