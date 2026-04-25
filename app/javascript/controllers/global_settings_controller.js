import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["switch", "slider", "statusText"]
  static values = {
    enabled: Boolean,
    settingKey: String,
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

    // Submit the toggle request
    this.submitToggle()
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

  submitToggle() {
    const formData = new FormData()
    formData.append("key", this.settingKeyValue)
    formData.append("label", this.settingLabelValue)

    // Get CSRF token
    const csrfToken = document.querySelector('meta[name="csrf-token"]')?.content

    fetch("/global_settings/toggle", {
      method: 'POST',
      body: formData,
      headers: {
        'Accept': 'application/json',
        'X-CSRF-Token': csrfToken
      }
    })
    .then(response => response.json())
    .then(data => {
      if (data.success) {
        // Update the enabled state to match server response
        this.enabledValue = data.enabled
        this.updateUI()
        this.showSuccessMessage(data.message)
      } else {
        // If update fails, revert the state
        this.enabledValue = !this.enabledValue
        this.updateUI()
        this.showErrorMessage(data.error || "Failed to update setting. Please try again.")
      }
    })
    .catch(error => {
      // If request fails, revert the state
      this.enabledValue = !this.enabledValue
      this.updateUI()
      console.error("Error updating global setting:", error)
      this.showErrorMessage("An error occurred. Please try again.")
    })
    .finally(() => {
      // Re-enable the switch
      this.switchTarget.disabled = false
    })
  }

  showSuccessMessage(text) {
    // Create and show a temporary success message
    const message = document.createElement('div')
    message.className = 'text-xs text-green-600 mt-2'
    message.textContent = text

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
