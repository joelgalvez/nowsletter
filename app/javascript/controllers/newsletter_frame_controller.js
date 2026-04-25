import { Controller } from "@hotwired/stimulus"

// Connects to data-controller="newsletter-frame"
// Loads newsletter HTML into a shadow DOM for style isolation
export default class extends Controller {
  static values = { url: String }

  connect() {
    this.shadow = this.element.attachShadow({ mode: "open" })
    fetch(this.urlValue)
      .then(r => r.text())
      .then(html => {
        this.shadow.innerHTML = html
        this.dispatch("loaded", { detail: { shadow: this.shadow } })
      })
  }
}
