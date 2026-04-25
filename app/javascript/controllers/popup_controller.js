import { Controller } from "@hotwired/stimulus"
import { searchInElement, wrapAllTextNodes } from "element_search"

// Connects to data-controller="popup"
export default class extends Controller {

  static values = {
    position: Number,
    max: Number,
    search: String
  }


  percentage = null;
  timer = null;

  initialize() {
    this.percentage = this.positionValue / this.maxValue;
  }

  search(string) {
    let searchRoot = this.shadowRoot || document.getElementById('letter-root');
    let findings = searchInElement(searchRoot, string, {
      positionValue: this.positionValue,
      maxValue: this.maxValue
    });
    if (findings.length > 0) {
      return findings[0].positionTop
    }
    return false;
  }

  doSearch(pointerElement, searchString) {

    let ypos = this.search(searchString);

    if (ypos !== false) {
      let y = (ypos + this.element.scrollTop);
      let half = window.innerHeight / 2;
      pointerElement.style.top = y + 'px';
      this.element.scrollTo({
        top: (y - half),
        behavior: "smooth"
      });
    }

  }

  scaleToFit(shadowHost) {
    let parent = shadowHost.parentElement;
    let style = getComputedStyle(parent);
    let availableWidth = parent.clientWidth - parseFloat(style.paddingLeft) - parseFloat(style.paddingRight);
    let contentWidth = shadowHost.scrollWidth;
    if (contentWidth > availableWidth) {
      let scale = availableWidth / contentWidth;
      shadowHost.style.transformOrigin = 'top left';
      shadowHost.style.transform = `scale(${scale})`;
      shadowHost.style.width = `${100 / scale}%`;
    } else {
      shadowHost.style.transform = '';
      shadowHost.style.width = '';
    }
  }

  closePopup(el) {
    el.parentElement.removeAttribute("src") // it might be nice to also remove the modal SRC
    el.remove()
    history.back();
  }

  connect() {

    let el = this.element;
    el.addEventListener('click', e => {
      if (e.target == el) {
        this.closePopup(el);
      }
    })

    let close = el.querySelector('.close');
    close.addEventListener('click', e => {
      this.closePopup(el)
    })

    let letterRoot = document.getElementById('letter-root');

    // Render letter body inside shadow DOM for CSS isolation
    let shadowHost = document.getElementById('letter-shadow-host');
    let template = document.getElementById('letter-template');
    let shadow = shadowHost.attachShadow({ mode: 'open' });
    shadow.appendChild(template.content.cloneNode(true));
    this.shadowRoot = shadow;

    wrapAllTextNodes(shadow);
    this.scaleToFit(shadowHost);

    let pointer = document.createElement('div');
    pointer.innerHTML = '<div class="inner absolute left-0 w-full" style="pointer-events:none;"><div class="absolute h-[1px] top-[15px] bg-red-600/60" style="left:-100vw;right:-100vw;"></div><div class="px-2 py-1 rounded-md bg-red-600 shadow-lg text-white text-base absolute">→</div></div>';
    let inner = pointer.querySelector('.inner');
    letterRoot.appendChild(inner);


    // let ypos = this.search(this.searchValue);

    this.doSearch(inner, this.searchValue);

    let images = shadow.querySelectorAll('img');
    images.forEach(i => {
      i.onload = () => {
        this.scaleToFit(shadowHost);
        this.doSearch(inner, this.searchValue);
      }
    });

    // if all are cached, onload isnt triggered
    Promise.all(Array.from(images).filter(img => !img.complete).map(img => new Promise(resolve => { img.onload = img.onerror = resolve; }))).then(() => {
      this.scaleToFit(shadowHost);
      this.doSearch(inner, this.searchValue);
    });

  }



  disconnect() {
    if (this.timer) {
      clearInterval(this.timer);
    }
  }
}
