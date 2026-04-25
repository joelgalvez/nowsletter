import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static values = { 
    autoDismiss: { type: Boolean, default: true },
    dismissAfter: { type: Number, default: 5000 }
  }
  
  connect() {
    // Add slide-down animation
    this.element.classList.add('animate-slide-down')
    
    // Auto-dismiss if enabled
    if (this.autoDismissValue) {
      this.autoDismissTimeout = setTimeout(() => {
        this.dismiss()
      }, this.dismissAfterValue)
    }
  }
  
  disconnect() {
    // Clear timeout if component is removed before auto-dismiss
    if (this.autoDismissTimeout) {
      clearTimeout(this.autoDismissTimeout)
    }
  }
  
  dismiss() {
    // Clear auto-dismiss timeout
    if (this.autoDismissTimeout) {
      clearTimeout(this.autoDismissTimeout)
    }
    
    // Fade out animation
    this.element.style.transition = 'opacity 0.3s ease-out'
    this.element.style.opacity = '0'
    
    // Remove element after animation
    setTimeout(() => {
      if (this.element.parentNode) {
        this.element.remove()
      }
    }, 300)
  }
  
  // Manual dismiss action (for close button)
  close(event) {
    event.preventDefault()
    this.dismiss()
  }
}