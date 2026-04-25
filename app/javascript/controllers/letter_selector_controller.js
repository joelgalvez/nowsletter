import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["select"]
  
  connect() {
    // Add Turbo support if needed
  }
  
  navigate(event) {
    const letterId = event.target.value
    if (letterId) {
      // Use Turbo to navigate without full page reload
      window.Turbo.visit(`/dashboard/${letterId}`)
    }
  }
}