import { Controller } from "@hotwired/stimulus"

// This controller handles the tag search autocomplete functionality
export default class extends Controller {
  static targets = ["input", "results", "tagContainer", "selectedTags", "template"]
  
  connect() {
    this.hideResults()
    this.previousSearch = ""
    this.fetchResults = this.debounce(this.fetchResults.bind(this), 300)
    
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
    fetch(`/tags/search?query=${encodeURIComponent(query)}`, {
      headers: {
        "Accept": "application/json",
        "X-Requested-With": "XMLHttpRequest"
      }
    })
    .then(response => response.json())
    .then(data => {
      this.showResults(data)
    })
    .catch(error => console.error("Error searching tags:", error))
  }
  
  showResults(tags) {
    if (tags.length === 0) {
      this.resultsTarget.innerHTML = '<div class="py-2 px-3 text-sm text-gray-700">No tags found</div>'
    } else {
      this.resultsTarget.innerHTML = tags.map(tag => `
        <div class="py-2 px-3 hover:bg-gray-100 cursor-pointer text-sm" 
             data-tag-id="${tag.id}" 
             data-tag-title="${tag.title}"
             data-action="click->tag-search#selectTag">
          ${this.highlightMatch(tag.title, this.inputTarget.value)}
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
  
  selectTag(event) {
    const tagId = event.currentTarget.dataset.tagId
    const tagTitle = event.currentTarget.dataset.tagTitle
    
    // Check if tag is already selected by looking for a checkbox with this value
    const existingCheckbox = this.element.querySelector(`input[type="checkbox"][value="${tagId}"]:checked`)
    if (existingCheckbox) {
      // Tag already selected, do nothing
      this.inputTarget.value = ""
      this.hideResults()
      return
    }
    
    // Clone the template and populate it
    const template = this.templateTarget.content.cloneNode(true)
    const checkbox = template.querySelector('input[type="checkbox"]')
    const tagLabel = template.querySelector('.tag-label')
    
    checkbox.value = tagId
    checkbox.id = `venue_tag_ids_${tagId}`
    checkbox.checked = true
    tagLabel.textContent = tagTitle
    
    // Add the new tag to the container
    this.tagContainerTarget.appendChild(template)
    
    // Clear the search input and hide results
    this.inputTarget.value = ""
    this.hideResults()
  }
  
  removeTag(event) {
    event.preventDefault()
    const tagElement = event.currentTarget.closest('.tag-item')
    tagElement.remove()
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