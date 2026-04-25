import { Controller } from "@hotwired/stimulus"

// Connects to data-controller="message"
export default class extends Controller {

  static values = {
    canClose: Number,
    expanded: Boolean,
    id: String
  }

  close() {
    if (this.canCloseValue == 1) {
      window.localStorage.setItem(this.idValue, 1);
      this.hide();
    }
  }

  show() {
    this.element.style.display = "block";
  }

  hide() {
    if (this.canCloseValue == 1) {
      this.element.style.display = "none";
    }
  }

  expand() {
    // this.element.classList.toggle('h-auto')
    this.element.querySelector('.expandable').classList.remove('h-[650px]');
    this.element.querySelector('.expand-text').classList.add('hidden');
    this.element.display = "none";
  }

  connect() {
    this.expanded = false;
    if (this.canCloseValue == 1 && window.localStorage.getItem(this.idValue) == 1) {
      this.hide();
    } else {
      this.show();
    }
  }
}
