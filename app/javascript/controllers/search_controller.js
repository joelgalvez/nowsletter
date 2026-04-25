import { Controller } from "@hotwired/stimulus"

// This controller handles real-time search functionality
export default class extends Controller {
  static targets = ["input"]
  
  connect() {
    // Optional: Set up a debounce for better performance
    this.timeout = null
  }
  
  submit() {
    // Clear any existing timeout
    clearTimeout(this.timeout)
    
    // Set a new timeout to debounce the search
    this.timeout = setTimeout(() => {
      // Submit the form after a short delay
      this.element.requestSubmit()
    }, 300) // 300ms debounce
  }
}