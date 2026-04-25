import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["selectedTags", "searchInput", "suggestions", "loading", "noResults", "results", "hiddenContainer"]
  static values = { 
    tags: Array,
    searchUrl: String 
  }
  
  connect() {
    // Ensure all tags are lowercase
    this.selectedTags = (this.tagsValue || []).map(tag => ({
      ...tag,
      title: tag.title.toLowerCase()
    }))
    this.searchTimeout = null
    this.updateDisplay()
    
    // Add global click listener for closing suggestions
    this.handleOutsideClick = this.onClickOutside.bind(this)
    document.addEventListener('click', this.handleOutsideClick)
  }
  
  disconnect() {
    // Clean up global listener
    document.removeEventListener('click', this.handleOutsideClick)
  }

  updateDisplay() {
    // Update visible tags
    this.selectedTagsTarget.innerHTML = this.selectedTags.map(tag => `
      <span class="inline-flex items-center px-3 py-1 rounded-full text-sm font-medium bg-blue-100 text-blue-800" data-tag-id="${tag.id}">
        ${this.escapeHtml(tag.title)}
        <button type="button" data-action="click->event-tag-selector#remove" data-tag-id="${tag.id}" class="ml-2 inline-flex items-center justify-center w-4 h-4 text-blue-400 hover:text-blue-600">
          <svg class="w-3 h-3" fill="currentColor" viewBox="0 0 20 20">
            <path fill-rule="evenodd" d="M4.293 4.293a1 1 0 011.414 0L10 8.586l4.293-4.293a1 1 0 111.414 1.414L11.414 10l4.293 4.293a1 1 0 01-1.414 1.414L10 11.414l-4.293 4.293a1 1 0 01-1.414-1.414L8.586 10 4.293 5.707a1 1 0 010-1.414z" clip-rule="evenodd"></path>
          </svg>
        </button>
      </span>
    `).join('')
    
    // Update hidden form fields
    this.hiddenContainerTarget.innerHTML = ''
    if (this.selectedTags.length === 0) {
      // Add empty field to ensure empty array is sent
      this.hiddenContainerTarget.innerHTML = '<input type="hidden" name="event[tag_ids][]" value="" />'
    } else {
      // Separate existing tags (positive IDs) from new tags (negative IDs)
      const existingTags = this.selectedTags.filter(tag => tag.id > 0)
      const newTags = this.selectedTags.filter(tag => tag.id < 0)
      
      // Add hidden fields for existing tag IDs
      existingTags.forEach(tag => {
        const input = document.createElement('input')
        input.type = 'hidden'
        input.name = 'event[tag_ids][]'
        input.value = tag.id
        this.hiddenContainerTarget.appendChild(input)
      })
      
      // Add hidden fields for new tag titles
      newTags.forEach(tag => {
        const input = document.createElement('input')
        input.type = 'hidden'
        input.name = 'event[new_tag_titles][]'
        input.value = tag.title
        this.hiddenContainerTarget.appendChild(input)
      })
      
      // If no existing tags, add empty field to ensure array is sent
      if (existingTags.length === 0) {
        const input = document.createElement('input')
        input.type = 'hidden'
        input.name = 'event[tag_ids][]'
        input.value = ''
        this.hiddenContainerTarget.appendChild(input)
      }
    }
  }

  remove(event) {
    event.preventDefault()
    const tagId = parseInt(event.currentTarget.dataset.tagId)
    this.selectedTags = this.selectedTags.filter(t => t.id !== tagId)
    this.updateDisplay()
  }

  search(event) {
    // Force lowercase input
    const input = event.target
    const cursorPosition = input.selectionStart
    const lowerValue = input.value.toLowerCase()
    
    if (input.value !== lowerValue) {
      input.value = lowerValue
      // Restore cursor position after changing value
      input.setSelectionRange(cursorPosition, cursorPosition)
    }
    
    const query = lowerValue.trim()
    
    clearTimeout(this.searchTimeout)
    
    if (query.length === 0) {
      this.hideSuggestions()
      return
    }
    
    if (query.length < 2) {
      return
    }
    
    this.searchTimeout = setTimeout(() => {
      this.performSearch(query)
    }, 300)
  }

  async performSearch(query) {
    this.showLoading()
    
    try {
      const csrfToken = document.querySelector('meta[name="csrf-token"]')?.content || ''
      
      const response = await fetch(`${this.searchUrlValue}?q=${encodeURIComponent(query)}`, {
        headers: {
          'Accept': 'application/json',
          'X-CSRF-Token': csrfToken
        }
      })
      
      if (!response.ok) {
        console.error('Tag search failed:', response.status, response.statusText)
        throw new Error(`HTTP error! status: ${response.status}`)
      }
      
      const tags = await response.json()
      this.displayResults(tags)
    } catch (error) {
      console.error('Error searching tags:', error)
      this.showNoResults()
    }
  }

  displayResults(tags) {
    this.hideLoading()
    
    const query = this.searchInputTarget.value.trim()
    const selectedTagIds = this.selectedTags.map(t => Number(t.id))
    const availableTags = tags.filter(tag => !selectedTagIds.includes(Number(tag.id)))
    
    // Check if the query matches any existing tag (case-insensitive)
    const queryLower = query.toLowerCase()
    const exactMatch = availableTags.find(tag => 
      tag.title.toLowerCase() === queryLower
    )
    
    // Check if this query is already selected
    const alreadySelected = this.selectedTags.find(t => 
      t.title.toLowerCase() === queryLower
    )
    
    let resultsHTML = availableTags.map(tag => `
      <div class="px-3 py-2 hover:bg-gray-100 cursor-pointer" data-action="click->event-tag-selector#addTag" data-tag-id="${tag.id}" data-tag-title="${this.escapeHtml(tag.title)}">
        ${this.escapeHtml(tag.title)}
      </div>
    `).join('')
    
    // Add option to create new tag if no exact match and not already selected
    if (query.length > 0 && !exactMatch && !alreadySelected) {
      resultsHTML += `
        <div class="px-3 py-2 hover:bg-gray-100 cursor-pointer border-t border-gray-200" data-action="click->event-tag-selector#createNewTag" data-tag-title="${this.escapeHtml(query)}">
          <span class="text-gray-600">Create new tag:</span> <span class="font-medium">${this.escapeHtml(query)}</span>
        </div>
      `
    }
    
    if (resultsHTML) {
      this.resultsTarget.innerHTML = resultsHTML
      this.showResults()
    } else if (availableTags.length === 0 && tags.length === 0) {
      this.showNoResults()
    } else {
      // All tags are already selected
      this.resultsTarget.innerHTML = '<div class="px-3 py-2 text-gray-500">All matching tags are already selected</div>'
      this.showResults()
    }
  }

  addTag(event) {
    const tagId = parseInt(event.currentTarget.dataset.tagId)
    const tagTitle = event.currentTarget.dataset.tagTitle.toLowerCase() // Force lowercase
    
    const existingTag = this.selectedTags.find(t => t.id === tagId)
    if (!existingTag) {
      this.selectedTags.push({ id: tagId, title: tagTitle })
      this.updateDisplay()
    }
    
    this.searchInputTarget.value = ''
    this.hideSuggestions()
  }

  createNewTag(event) {
    const tagTitle = event.currentTarget.dataset.tagTitle.toLowerCase() // Force lowercase
    
    // Check if this tag already exists in selected tags
    const existingTag = this.selectedTags.find(t => 
      t.title.toLowerCase() === tagTitle.toLowerCase()
    )
    
    if (!existingTag) {
      // Create a new tag with a temporary negative ID
      const newTag = {
        id: -Date.now(), // Use negative timestamp as temporary ID
        title: tagTitle
      }
      this.selectedTags.push(newTag)
      this.updateDisplay()
    }
    
    this.searchInputTarget.value = ''
    this.hideSuggestions()
  }

  onSearchKeydown(event) {
    if (event.key === 'Escape') {
      this.searchInputTarget.value = ''
      this.hideSuggestions()
    } else if (event.key === 'Enter') {
      event.preventDefault()
      const query = this.searchInputTarget.value.trim().toLowerCase() // Force lowercase
      
      if (query.length > 0) {
        // Check if this tag already exists in selected tags
        const existingTag = this.selectedTags.find(t => 
          t.title.toLowerCase() === query.toLowerCase()
        )
        
        if (!existingTag) {
          // Create a new tag with a temporary negative ID
          const newTag = {
            id: -Date.now(), // Use negative timestamp as temporary ID
            title: query
          }
          this.selectedTags.push(newTag)
          this.updateDisplay()
        }
        
        this.searchInputTarget.value = ''
        this.hideSuggestions()
      }
    }
  }

  onClickOutside(event) {
    if (!this.element.contains(event.target)) {
      this.hideSuggestions()
    }
  }

  showLoading() {
    this.loadingTarget.classList.remove('hidden')
    this.noResultsTarget.classList.add('hidden')
    this.resultsTarget.innerHTML = ''
    this.suggestionsTarget.classList.remove('hidden')
  }

  hideLoading() {
    this.loadingTarget.classList.add('hidden')
  }

  showNoResults() {
    this.noResultsTarget.classList.remove('hidden')
    this.resultsTarget.innerHTML = ''
  }

  showResults() {
    this.noResultsTarget.classList.add('hidden')
  }

  hideSuggestions() {
    this.suggestionsTarget.classList.add('hidden')
  }

  escapeHtml(str) {
    if (!str) return ''
    const div = document.createElement('div')
    div.textContent = str
    return div.innerHTML
  }
}