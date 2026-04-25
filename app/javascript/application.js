// Configure your import map in config/importmap.rb. Read more: https://github.com/rails/importmap-rails
import "@hotwired/turbo-rails"
import "controllers"

import "trix"
import "@rails/actiontext"
import "letters"




////


window.addEventListener('DOMContentLoaded', e => {
	// console.log(e);
})
window.addEventListener('turbo:load', e => {
	// let hash = window.location.hash;
	// if (hash) {
	// 	let h = decodeURI(hash);
	// 	console.log(h.slice(1));
	// }
})
window.addEventListener("trix-initialize", event => {
	const { toolbarElement } = event.target
	const input = toolbarElement.querySelector("input[name=href]")
	// Change the input type from "url" to "text" to allow local links
	input.type = "text"
})
window.addEventListener("DOMContentLoaded", e => {
	document.querySelectorAll('a[href]').forEach(a => {
		if (location.hostname == new URL(a.href).hostname)
			return;

		a.target = "_blank";
		// a.rel = "noreferrer nofollow noopener";
	});
});

