import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["select", "textarea"]
  static values = { templates: Object }

  connect() {
    this.initialText = this.textareaTarget.value
    this.dirty = false
  }

  markDirty() {
    this.dirty = this.textareaTarget.value !== this.initialText
  }

  change(event) {
    const id = event.target.value
    const newText = this.templatesValue[id] ?? ""

    if (this.dirty) {
      const ok = confirm("You have unsaved changes in the textarea. Replace them with the selected template?")
      if (!ok) {
        // revert dropdown to previous selection
        event.target.value = this.previousSelection
        return
      }
    }

    this.textareaTarget.value = newText
    this.initialText = newText
    this.dirty = false
    this.previousSelection = id
  }

  selectFocus(event) {
    this.previousSelection = event.target.value
  }
}
