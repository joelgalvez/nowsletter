import { Controller } from "@hotwired/stimulus"
import { searchInElement, wrapAllTextNodes } from "element_search"

// Connects to data-controller="scroll-position"
// Tracks scroll percentage of the newsletter (left) and events (right) panels
export default class extends Controller {
  static targets = ["newsletter", "events"]

  connect() {
    this.onNewsletterScroll = this.updateNewsletter.bind(this)
    this.onEventsScroll = this.updateEvents.bind(this)
    this.lines = []
    this.arrows = []
    this.findings = []
    this.shadow = null

    this.onResize = this.handleResize.bind(this)

    this.newsletterTarget.addEventListener("scroll", this.onNewsletterScroll)
    this.eventsTarget.addEventListener("scroll", this.onEventsScroll)
    window.addEventListener("resize", this.onResize)
  }

  handleResize() {
    if (!this.isSideBySide()) {
      this.clearLines()
    } else {
      this.updateLinePositions()
    }
  }

  newsletterLoaded(e) {
    this.shadow = e.detail.shadow
    wrapAllTextNodes(this.shadow)
  }

  percentage(el) {
    if (el.scrollHeight <= el.clientHeight) return 0
    return el.scrollTop / (el.scrollHeight - el.clientHeight)
  }

  // Returns the event card element that is most "in view" —
  // the one whose top edge is closest to (but below) a point
  // slightly below the top of the events container.
  currentEventInView() {
    let container = this.eventsTarget
    let cards = container.querySelectorAll("[id^='event-']")
    if (!cards.length) return null

    let containerRect = container.getBoundingClientRect()
    let best = null
    let bestArea = 0

    for (let card of cards) {
      let rect = card.getBoundingClientRect()
      let visibleHeight = Math.max(0, Math.min(rect.bottom, containerRect.bottom) - Math.max(rect.top, containerRect.top))
      if (visibleHeight > bestArea) {
        best = card
        bestArea = visibleHeight
      }
    }

    return best || cards[0]
  }

  getEventTitle(card) {
    let titleEl = card.querySelector(".text-base")
    return titleEl ? titleEl.textContent.trim() : null
  }

  clearLines() {
    this.lines.forEach(line => line.remove())
    this.lines = []
    this.arrows.forEach(a => a.remove())
    this.arrows = []
    if (this.dot) { this.dot.remove(); this.dot = null }
  }

  isSideBySide() {
    return window.matchMedia("(min-width: 768px)").matches
  }

  createLines(eventCard, findings) {
    this.clearLines()
    if (!this.isSideBySide()) return
    this.findings = findings
    this.currentCard = eventCard

    for (let i = 0; i < findings.length; i++) {
      let finding = findings[i]
      let line = document.createElement("div")
      let opacity = Math.max(0.3, Math.min(1, Math.abs(finding.fuzzyValue)))
      line.style.cssText = "position:fixed;height:4px;background:red;z-index:50;transform-origin:0 50%;cursor:pointer;opacity:" + opacity + ";background-size:100% 1px;background-repeat:no-repeat;background-position:center;background-image:linear-gradient(red,red);background-color:transparent;"
      line.addEventListener("mouseenter", () => { line.style.backgroundSize = "100% 4px" })
      line.addEventListener("mouseleave", () => { line.style.backgroundSize = "100% 1px" })
      line.addEventListener("click", () => {
        let el = findings[i].element
        if (el) {
          el.scrollIntoView({ behavior: "smooth", block: "center" })
        }
      })
      document.body.appendChild(line)
      this.lines.push(line)

      let arrow = document.createElement("div")
      arrow.style.cssText = "position:fixed;width:0;height:0;border-left:12px solid red;border-top:8px solid transparent;border-bottom:8px solid transparent;pointer-events:none;z-index:51;opacity:" + opacity + ";"
      document.body.appendChild(arrow)
      this.arrows.push(arrow)
    }

    this.dot = document.createElement("div")
    this.dot.style.cssText = "position:fixed;width:10px;height:10px;background:red;border-radius:50%;pointer-events:none;z-index:51;"
    document.body.appendChild(this.dot)

    this.updateLinePositions()
  }

  updateLinePositions() {
    if (!this.currentCard || !this.findings.length) return

    let cardRect = this.currentCard.getBoundingClientRect()
    let rightX = cardRect.left
    let rightY = cardRect.top + cardRect.height / 2
    let endX = rightX + 40

    if (this.dot) {
      this.dot.style.left = (endX - 5) + "px"
      this.dot.style.top = (rightY - 5) + "px"
    }

    for (let i = 0; i < this.findings.length; i++) {
      let finding = this.findings[i]
      let line = this.lines[i]
      if (!line || !finding.element) continue

      let elRect = finding.element.getBoundingClientRect()
      let containerRect = this.newsletterTarget.getBoundingClientRect()

      let leftX = containerRect.right - 40
      let leftY = elRect.top + elRect.height / 2

      // Clamp leftY to the newsletter container bounds
      leftY = Math.max(containerRect.top, Math.min(containerRect.bottom, leftY))

      // Draw line from right (event card) to left (newsletter match)
      // transform-origin is 0 0 (left end of the div), so we position at the right end
      // and draw leftward
      let dx = leftX - endX
      let dy = leftY - rightY
      let length = Math.sqrt(dx * dx + dy * dy)
      let angle = Math.atan2(dy, dx)

      // Fan: offset angle slightly so overlapping lines spread leftward
      let angleOffset = (i - (this.findings.length - 1) / 2) * 0.02
      angle += angleOffset

      line.style.transformOrigin = "0 50%"
      line.style.width = length + "px"
      line.style.left = endX + "px"
      line.style.top = (rightY - 2) + "px"
      line.style.transform = "rotate(" + angle + "rad)"

      // Position arrow at the left (tip) end of the line
      let arrow = this.arrows[i]
      if (arrow) {
        let tipX = endX + Math.cos(angle) * length
        let tipY = rightY + Math.sin(angle) * length
        arrow.style.left = tipX + "px"
        arrow.style.top = (tipY - 8) + "px"
        arrow.style.transform = "rotate(" + angle + "rad)"
        arrow.style.transformOrigin = "0px 8px"
      }
    }
  }

  updateNewsletter() {
    this.updateLinePositions()
  }

  updateEvents() {
    let current = this.currentEventInView()
    if (current && current !== this.lastEvent) {
      this.lastEvent = current
      let title = this.getEventTitle(current)
      if (title && this.shadow) {
        let findings = searchInElement(this.shadow, title, { filterByPosition: false })
        // Filter out elements outside the newsletter content (e.g. zero-size, off-screen metadata)
        let containerRect = this.newsletterTarget.getBoundingClientRect()
        findings = findings.filter(f => {
          let r = f.element.getBoundingClientRect()
          return r.width > 0 && r.height > 0 && r.left >= containerRect.left && r.right <= containerRect.right + 10
        })
        this.createLines(current, findings)
      } else {
        this.clearLines()
      }
    } else {
      this.updateLinePositions()
    }
  }

  disconnect() {
    this.clearLines()
    this.newsletterTarget.removeEventListener("scroll", this.onNewsletterScroll)
    this.eventsTarget.removeEventListener("scroll", this.onEventsScroll)
    window.removeEventListener("resize", this.onResize)
  }
}
