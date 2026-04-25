import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["switch", "slider", "text"]
  static values = { 
    url: String,
    published: Boolean
  }

  connect() {
    this.updateVisualState()
  }

  toggle(event) {
    event.preventDefault()
    
    // Optimistically update the UI
    this.publishedValue = !this.publishedValue
    this.updateVisualState()
    
    // Send AJAX request
    fetch(this.urlValue, {
      method: "PATCH",
      headers: {
        "X-CSRF-Token": document.querySelector("[name='csrf-token']").content,
        "Content-Type": "application/json",
        "Accept": "application/json"
      },
      body: JSON.stringify({})
    })
    .then(response => response.json())
    .then(data => {
      // Update based on server response
      this.publishedValue = data.status === "published"
      this.updateVisualState()
    })
    .catch(error => {
      console.error("Error:", error)
      // Revert on error
      this.publishedValue = !this.publishedValue
      this.updateVisualState()
    })
  }

  updateVisualState() {
    if (this.publishedValue) {
      this.switchTarget.classList.remove("bg-gray-300")
      this.switchTarget.classList.add("bg-green-600")
      this.sliderTarget.classList.remove("translate-x-1")
      this.sliderTarget.classList.add("translate-x-6")
      if (this.hasTextTarget) {
        this.textTarget.textContent = "Published"
        this.textTarget.classList.remove("text-gray-500")
        this.textTarget.classList.add("text-black")
      }
    } else {
      this.switchTarget.classList.remove("bg-green-600")
      this.switchTarget.classList.add("bg-gray-300")
      this.sliderTarget.classList.remove("translate-x-6")
      this.sliderTarget.classList.add("translate-x-1")
      if (this.hasTextTarget) {
        this.textTarget.textContent = "Unpublished"
        this.textTarget.classList.remove("text-black")
        this.textTarget.classList.add("text-gray-500")
      }
    }
  }
}