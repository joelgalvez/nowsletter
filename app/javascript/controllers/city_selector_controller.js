import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["select", "countryCodeInput", "cityNameInput", "newCityContainer", "addButton", "feedback", "form"]
  
  connect() {
    // Show/hide the new city input based on initial selection
    this.toggleNewCityInput()
    
    // Find the form and add submit listener
    this.form = this.element.closest('form')
    if (this.form) {
      this.form.addEventListener('submit', this.validateBeforeSubmit.bind(this))
    }
  }
  
  disconnect() {
    // Clean up event listener
    if (this.form) {
      this.form.removeEventListener('submit', this.validateBeforeSubmit.bind(this))
    }
  }
  
  validateBeforeSubmit(event) {
    // Prevent submission if "new" is selected
    if (this.selectTarget.value === "new") {
      event.preventDefault()
      this.showFeedback("Please add the new city or select an existing one before saving", "error")
      this.selectTarget.focus()
      return false
    }
  }
  
  toggleNewCityInput() {
    const selectedValue = this.selectTarget.value
    if (selectedValue === "new") {
      this.newCityContainerTarget.classList.remove("hidden")
    } else {
      this.newCityContainerTarget.classList.add("hidden")
      this.clearFeedback()
    }
  }
  
  async addNewCity() {
    const countryCode = this.countryCodeInputTarget.value.trim()
    const cityName = this.cityNameInputTarget.value.trim()
    
    // Validate inputs
    if (!countryCode) {
      this.showFeedback("Please select a country", "error")
      this.countryCodeInputTarget.focus()
      return
    }
    
    if (!cityName) {
      this.showFeedback("Please enter a city name", "error")
      this.cityNameInputTarget.focus()
      return
    }
    
    // Disable inputs while processing
    this.setLoading(true)
    
    try {
      // Create the city via AJAX
      const response = await fetch('/cities/create_with_country', {
        method: 'POST',
        headers: {
          'Content-Type': 'application/json',
          'X-CSRF-Token': document.querySelector('[name="csrf-token"]').content
        },
        body: JSON.stringify({
          country_code: countryCode,
          city_name: cityName
        })
      })
      
      const data = await response.json()
      
      if (response.ok) {
        // Add the new option to the select
        const newOption = new Option(`${countryCode} - ${cityName}`, data.city_id, true, true)
        
        // Find the right position to insert (alphabetically)
        let inserted = false
        const options = Array.from(this.selectTarget.options)
        for (let i = 1; i < options.length - 1; i++) { // Skip blank and "Add new city" options
          if (options[i].text > newOption.text) {
            this.selectTarget.add(newOption, options[i])
            inserted = true
            break
          }
        }
        
        if (!inserted) {
          // Insert before "Add new city" option
          this.selectTarget.add(newOption, options[options.length - 1])
        }
        
        // Select the new city
        this.selectTarget.value = data.city_id
        
        // Clear and hide the inputs
        this.countryCodeInputTarget.value = ""
        this.cityNameInputTarget.value = ""
        this.newCityContainerTarget.classList.add("hidden")
        
        this.showFeedback(`City "${cityName}" added successfully!`, "success")
        
        // Clear success message after 3 seconds
        setTimeout(() => this.clearFeedback(), 3000)
      } else {
        this.showFeedback(data.error || "Failed to create city", "error")
      }
    } catch (error) {
      this.showFeedback("Network error. Please try again.", "error")
      console.error('Error creating city:', error)
    } finally {
      this.setLoading(false)
    }
  }
  
  showFeedback(message, type) {
    this.feedbackTarget.textContent = message
    this.feedbackTarget.className = type === 'error' 
      ? 'text-sm text-red-600 mt-1' 
      : 'text-sm text-green-600 mt-1'
    this.feedbackTarget.classList.remove("hidden")
  }
  
  clearFeedback() {
    this.feedbackTarget.classList.add("hidden")
    this.feedbackTarget.textContent = ""
  }
  
  setLoading(loading) {
    this.countryCodeInputTarget.disabled = loading
    this.cityNameInputTarget.disabled = loading
    this.addButtonTarget.disabled = loading
    this.selectTarget.disabled = loading
    
    if (loading) {
      this.addButtonTarget.textContent = "Adding..."
    } else {
      this.addButtonTarget.textContent = "Add City"
    }
  }
}