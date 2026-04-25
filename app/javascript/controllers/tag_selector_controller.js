import { Controller } from "@hotwired/stimulus"

// This controller handles the tag selection UI
export default class extends Controller {
  static targets = ["checkbox", "label"]
  
  connect() {
    // Initialize the UI state
    this.updateAllTags()
  }
  
  toggle(event) {
    const checkbox = event.currentTarget
    const label = checkbox.closest('label')
    const span = label.querySelector('span.tag-label')
    
    // Update the visual state
    if (checkbox.checked) {
      label.classList.add('tag-active')
      span.classList.remove('bg-gray-100', 'text-gray-800')
      span.classList.add('bg-indigo-100', 'text-indigo-800')
    } else {
      label.classList.remove('tag-active')
      span.classList.remove('bg-indigo-100', 'text-indigo-800')
      span.classList.add('bg-gray-100', 'text-gray-800')
    }
  }
  
  // Handle clicking on the tag label (not just the checkbox)
  labelClick(event) {
    // Prevent the default label behavior to handle it ourselves
    event.preventDefault()
    
    // Find the checkbox associated with this label
    const label = event.currentTarget
    const checkbox = label.querySelector('input[type="checkbox"]')
    
    // Toggle the checkbox state
    checkbox.checked = !checkbox.checked
    
    // Trigger the toggle function to update the UI
    this.toggle({ currentTarget: checkbox })
  }
  
  // Update all tags based on their checkbox state
  updateAllTags() {
    this.checkboxTargets.forEach(checkbox => {
      const label = checkbox.closest('label')
      const span = label.querySelector('span.tag-label')
      
      if (checkbox.checked) {
        label.classList.add('tag-active')
        span.classList.remove('bg-gray-100', 'text-gray-800')
        span.classList.add('bg-indigo-100', 'text-indigo-800')
      } else {
        label.classList.remove('tag-active')
        span.classList.remove('bg-indigo-100', 'text-indigo-800')
        span.classList.add('bg-gray-100', 'text-gray-800')
      }
    })
  }
}