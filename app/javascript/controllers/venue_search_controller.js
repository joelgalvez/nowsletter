import { Controller } from "@hotwired/stimulus"

// This controller handles searching for venues and selecting one
export default class extends Controller {
  static targets = ["input", "venueId", "results", "selectedVenue"]
  
  connect() {
    this.hideResults()
    this.previousSearch = ""
    this.selectedVenueId = this.venueIdTarget.value || ""
    this.fetchResults = this.debounce(this.fetchResults.bind(this), 300)
    
    if (this.selectedVenueId) {
      this.fetchVenueName(this.selectedVenueId)
    }
    
    // Add click outside listener to hide results
    document.addEventListener('click', this.handleClickOutside.bind(this))
  }
  
  disconnect() {
    document.removeEventListener('click', this.handleClickOutside.bind(this))
  }
  
  handleClickOutside(event) {
    if (!this.element.contains(event.target)) {
      this.hideResults()
    }
  }
  
  search() {
    const query = this.inputTarget.value.trim()
    
    if (query === this.previousSearch) return
    this.previousSearch = query
    
    if (query.length < 2) {
      this.hideResults()
      return
    }
    
    this.fetchResults(query)
  }
  
  fetchResults(query) {
    fetch(`/venues/search?query=${encodeURIComponent(query)}`, {
      headers: {
        "Accept": "application/json",
        "X-Requested-With": "XMLHttpRequest"
      }
    })
    .then(response => response.json())
    .then(data => {
      this.showResults(data)
    })
    .catch(error => console.error("Error searching venues:", error))
  }
  
  fetchVenueName(venueId) {
    fetch(`/venues/${venueId}`, {
      headers: {
        "Accept": "application/json",
        "X-Requested-With": "XMLHttpRequest"
      }
    })
    .then(response => response.json())
    .then(data => {
      this.selectedVenueTarget.textContent = data.title
      this.selectedVenueTarget.classList.remove('hidden')
      this.inputTarget.value = ""
    })
    .catch(error => console.error("Error fetching venue:", error))
  }
  
  showResults(venues) {
    if (venues.length === 0) {
      this.resultsTarget.innerHTML = '<div class="py-2 px-3 text-sm text-gray-700">No venues found</div>'
    } else {
      this.resultsTarget.innerHTML = venues.map(venue => `
        <div class="py-2 px-3 hover:bg-gray-100 cursor-pointer text-sm" 
             data-venue-id="${venue.id}" 
             data-action="click->venue-search#selectVenue">
          ${this.highlightMatch(venue.title, this.inputTarget.value)}
        </div>
      `).join('')
    }
    
    this.showResultsList()
  }
  
  highlightMatch(text, query) {
    if (!query) return text
    const regex = new RegExp(`(${query})`, 'gi')
    return text.replace(regex, '<span class="bg-yellow-200">$1</span>')
  }
  
  selectVenue(event) {
    const venueId = event.currentTarget.dataset.venueId
    const venueTitle = event.currentTarget.textContent.trim()
    
    // Set the hidden input value
    this.venueIdTarget.value = venueId
    
    // Show the selected venue
    this.selectedVenueTarget.textContent = venueTitle
    this.selectedVenueTarget.classList.remove('hidden')
    
    // Clear the search input
    this.inputTarget.value = ""
    
    // Hide the results
    this.hideResults()
  }
  
  clearVenue() {
    this.venueIdTarget.value = ""
    this.selectedVenueTarget.textContent = ""
    this.selectedVenueTarget.classList.add('hidden')
    this.inputTarget.value = ""
    this.inputTarget.focus()
  }
  
  showResultsList() {
    this.resultsTarget.classList.remove('hidden')
  }
  
  hideResults() {
    this.resultsTarget.classList.add('hidden')
  }
  
  // Utility function to debounce search requests
  debounce(func, wait) {
    let timeout
    return function(...args) {
      clearTimeout(timeout)
      timeout = setTimeout(() => func.apply(this, args), wait)
    }
  }
}