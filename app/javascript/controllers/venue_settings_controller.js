import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["switch", "slider", "statusText"]
  static values = { 
    enabled: Boolean,
    venueId: Number,
    settingName: String,
    settingLabel: String
  }

  connect() {
    this.updateUI()
  }

  toggle() {
    // Disable the switch during update
    this.switchTarget.disabled = true
    
    // Toggle the enabled state
    this.enabledValue = !this.enabledValue
    
    // Update the UI immediately
    this.updateUI()
    
    // Submit the form to update the venue
    this.submitForm()
  }

  updateUI() {
    if (this.enabledValue) {
      this.switchTarget.classList.remove("bg-gray-300")
      this.switchTarget.classList.add("bg-green-600")
      this.sliderTarget.classList.remove("translate-x-1")
      this.sliderTarget.classList.add("translate-x-6")
    } else {
      this.switchTarget.classList.remove("bg-green-600")
      this.switchTarget.classList.add("bg-gray-300")
      this.sliderTarget.classList.remove("translate-x-6")
      this.sliderTarget.classList.add("translate-x-1")
    }
  }

  submitForm() {
    const formData = new FormData()
    formData.append(`venue[${this.settingNameValue}]`, this.enabledValue)
    formData.append("_method", "patch")
    
    // Get CSRF token
    const csrfToken = document.querySelector('meta[name="csrf-token"]')?.content
    if (csrfToken) {
      formData.append("authenticity_token", csrfToken)
    }
    
    fetch(`/venues/${this.venueIdValue}`, {
      method: 'POST',
      body: formData,
      headers: {
        'Accept': 'application/json',
        'X-CSRF-Token': csrfToken
      }
    })
    .then(response => {
      if (response.ok) {
        // Success - show a temporary success message
        this.showSuccessMessage()
        // Log entry will be created on the server side
        console.log(`Venue setting '${this.settingNameValue}' changed to: ${this.enabledValue}`)
      } else {
        // If update fails, revert the state
        this.enabledValue = !this.enabledValue
        this.updateUI()
        this.showErrorMessage("Failed to update venue settings. Please try again.")
      }
    })
    .catch(error => {
      // If request fails, revert the state
      this.enabledValue = !this.enabledValue
      this.updateUI()
      console.error("Error updating venue:", error)
      this.showErrorMessage("An error occurred. Please try again.")
    })
    .finally(() => {
      // Re-enable the switch
      this.switchTarget.disabled = false
    })
  }
  
  showSuccessMessage() {
    // Create and show a temporary success message
    const message = document.createElement('div')
    message.className = 'text-xs text-green-600 mt-2'
    const labelText = this.settingLabelValue || this.settingNameValue
    message.textContent = `${labelText} setting saved. A log entry has been created.`
    
    if (this.hasStatusTextTarget) {
      // Clear any existing messages
      this.statusTextTarget.innerHTML = ''
      this.statusTextTarget.appendChild(message)
    } else {
      // Insert after the switch container
      this.element.appendChild(message)
    }
    
    // Remove the message after 3 seconds
    setTimeout(() => {
      message.remove()
    }, 3000)
  }
  
  showErrorMessage(text) {
    // Create and show a temporary error message
    const message = document.createElement('div')
    message.className = 'text-xs text-red-600 mt-2'
    message.textContent = text
    
    if (this.hasStatusTextTarget) {
      // Clear any existing messages
      this.statusTextTarget.innerHTML = ''
      this.statusTextTarget.appendChild(message)
    } else {
      // Insert after the switch container
      this.element.appendChild(message)
    }
    
    // Remove the message after 5 seconds
    setTimeout(() => {
      message.remove()
    }, 5000)
  }
}