import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["email", "submitButton", "feedback"]

  showFeedback(event) {
    // Show immediate feedback when form is submitted
    if (this.hasSubmitButtonTarget) {
      const originalText = this.submitButtonTarget.value
      this.submitButtonTarget.value = "Updating..."
      this.submitButtonTarget.disabled = true
      
      // Show checkmark feedback if available
      if (this.hasFeedbackTarget) {
        setTimeout(() => {
          this.feedbackTarget.classList.remove("hidden")
          this.submitButtonTarget.classList.add("hidden")
          
          // Hide feedback after 2 seconds and restore button
          setTimeout(() => {
            this.feedbackTarget.classList.add("hidden")
            this.submitButtonTarget.classList.remove("hidden")
            this.submitButtonTarget.value = originalText
            this.submitButtonTarget.disabled = false
          }, 2000)
        }, 100)
      }
    }
  }
  
  connect() {
    // Check if there's a notice in the URL parameters (from redirect)
    const urlParams = new URLSearchParams(window.location.search)
    const notice = urlParams.get('notice')
    
    if (notice && this.hasFeedbackTarget) {
      this.feedbackTarget.classList.remove("hidden")
      setTimeout(() => {
        this.feedbackTarget.classList.add("hidden")
      }, 3000)
    }
  }
}