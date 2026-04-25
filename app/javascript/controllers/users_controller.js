import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["selectAll", "checkbox"]

  connect() {
    this.updateSelectAllCheckbox()
  }

  toggleAll() {
    const checked = this.selectAllTarget.checked
    this.checkboxTargets.forEach(checkbox => {
      checkbox.checked = checked
    })
  }

  checkboxChanged() {
    this.updateSelectAllCheckbox()
  }

  updateSelectAllCheckbox() {
    const allChecked = this.checkboxTargets.every(checkbox => checkbox.checked)
    this.selectAllTarget.checked = allChecked
  }
}