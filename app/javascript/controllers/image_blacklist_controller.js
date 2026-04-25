import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["image"]
  static values = { letterId: String }

  async toggle(event) {
    event.preventDefault()
    const image = event.currentTarget
    const url = image.dataset.url
    const isBlacklisted = image.dataset.blacklisted === "true"

    try {
      const csrfToken = document.querySelector('meta[name="csrf-token"]')?.content || ''

      const response = await fetch('/blacklists/toggle', {
        method: 'POST',
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
          'X-CSRF-Token': csrfToken
        },
        body: JSON.stringify({ url: url, letter_id: this.letterIdValue })
      })
      
      if (!response.ok) {
        throw new Error(`HTTP error! status: ${response.status}`)
      }
      
      const data = await response.json()
      
      // Update the UI based on the response
      if (data.blacklisted) {
        // Image is now blacklisted
        image.classList.add('opacity-30', 'grayscale')
        image.dataset.blacklisted = "true"

        // Add blacklisted label if it doesn't exist
        if (!image.parentElement.querySelector('.blacklist-label')) {
          const label = document.createElement('div')
          label.className = 'absolute inset-0 flex items-center justify-center pointer-events-none blacklist-label'
          label.innerHTML = '<span class="bg-red-600 text-white px-2 py-1 rounded text-xs font-bold">BLACKLISTED</span>'
          image.parentElement.appendChild(label)
        }

        // Replace any event cards whose lead images were cleared
        if (data.cleared_event_cards) {
          for (const [id, html] of Object.entries(data.cleared_event_cards)) {
            const card = document.getElementById(`event-${id}`)
            if (card) {
              const tmp = document.createElement('div')
              tmp.innerHTML = html.trim()
              const replacement = tmp.firstElementChild
              if (replacement) card.replaceWith(replacement)
            }
          }
        }
      } else {
        // Image is now unblacklisted
        image.classList.remove('opacity-30', 'grayscale')
        image.dataset.blacklisted = "false"
        
        // Remove blacklisted label if it exists
        const label = image.parentElement.querySelector('.blacklist-label')
        if (label) {
          label.remove()
        }
      }
      
    } catch (error) {
      console.error('Error toggling blacklist:', error)
      alert('Failed to update blacklist status. Please try again.')
    }
  }
}