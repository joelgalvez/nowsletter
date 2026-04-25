import { Controller } from "@hotwired/stimulus"

// Connects to data-controller="show-menu"
export default class extends Controller {

	static targets = ["content"];

	connect() {
		this.hide()
	}

	show() {
		this.contentTarget.classList.remove("hidden");
	}

	hide() {
		this.contentTarget.classList.add("hidden");
	}
}
