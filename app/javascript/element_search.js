import FuzzySet from 'fuzzyset'

export function prevAll(element) {
  var result = [];
  while (element = element.previousElementSibling)
    result.push(element);
  return result;
}

export function wrapTextNode(textNode, id) {
  var spanNode = document.createElement('span');
  spanNode.setAttribute('id', id);
  var newTextNode = document.createTextNode(textNode.textContent);
  spanNode.appendChild(newTextNode);
  textNode.parentNode.replaceChild(spanNode, textNode);
  return spanNode;
}

/**
 * Retrieves an array of all text nodes and elements under a given element.
 */
export function allNodesUnder(el) {
  const children = []
  const walker = document.createTreeWalker(el, NodeFilter.SHOW_TEXT | NodeFilter.SHOW_ELEMENT)
  while (walker.nextNode()) {
    children.push(walker.currentNode)
  }
  return children
}

/**
 * Wraps all bare text nodes under rootEl as spans so they can be positioned in the DOM.
 *
 * @param {Element} rootEl - The root element whose text nodes to wrap
 */
export function wrapAllTextNodes(rootEl) {
  let ns = allNodesUnder(rootEl);
  ns.forEach(n => {
    if (n.tagName != 'TITLE' && n.tagName != 'META' && n.tagName != 'STYLE' && n.parentNode.nodeName !== 'SCRIPT' && n.parentNode.nodeName !== 'STYLE') {
      if (n.nodeType == Node.TEXT_NODE) {
        if (n.textContent.trim() != '') {
          wrapTextNode(n, 'text-node-' + Math.random().toString(36).substring(7));
        }
      }
    }
  });
}

/**
 * Wraps all text nodes under rootEl as spans, then performs fuzzy + exact search
 * for the given string. Returns the top Y position of the best match, or false.
 *
 * @param {Element} rootEl - The root element to search within
 * @param {string} string - The search string
 * @param {Object} [options] - Optional parameters
 * @param {number} [options.positionValue] - AI character position for percentage calc
 * @param {number} [options.maxValue] - AI total characters for percentage calc
 * @returns {Array} Array of findings sorted by fuzzy score (best first).
 *   Each finding: { element, positionTop, domPercentage, textInElement, fuzzyValue, ... }
 */
export function searchInElement(rootEl, string, options = {}) {
  // querySelectorAll works in both regular DOM and shadow DOM (unlike XPath)
  let allEls = rootEl.querySelectorAll("*")
  let elements = []
  for (let el of allEls) {
    if (el.tagName == 'SCRIPT' || el.tagName == 'TITLE' || el.tagName == 'META' || el.tagName == 'STYLE') continue
    // Leaf elements only (no child elements)
    if (el.children.length === 0) {
      elements.push(el)
    }
  }

  var phrase = string.toLowerCase();

  let findings = []

  for (let element of elements) {
    var innerText = element.innerText.toLowerCase();

    let fuzzyValue = 0;

    if (innerText.trim() != '') {
      let found = false;

      let regularSearch = innerText.includes(phrase) ? 0 : -1;
      if (regularSearch !== -1) {
        fuzzyValue = -0.01;
        found = true;
      }

      let fuzzyObject = FuzzySet([innerText]);
      let fuzzyResult = fuzzyObject.get(phrase);

      if (fuzzyResult !== null) {
        fuzzyValue = fuzzyResult[0][0];
        if (fuzzyValue && fuzzyValue > 0.01 || regularSearch !== -1) {
          found = true;
        }
      }

      if (found) {
        element.innerHTML += "$$UNIQUE$$$";

        let body = element.closest('#letter-root')?.innerText || rootEl.innerText || rootEl.textContent;
        let bodyTotalLength = body.length;
        let first = body.split('$$UNIQUE$$$')[0];

        element.innerHTML = element.innerHTML.replace('$$UNIQUE$$$', '');

        var elementPositionTop = element.getBoundingClientRect().top;

        let ret = {
          element: element,
          positionTop: elementPositionTop,
          domPercentage: first.length / bodyTotalLength,
          domCharacterPosition: first.length,
          domCharacterTotal: bodyTotalLength,
          aiPercentage: options.positionValue != null ? options.positionValue / options.maxValue : null,
          aiCharacterPosition: options.positionValue ?? null,
          aiCharacterTotal: options.maxValue ?? null,
          textInElement: innerText,
          fuzzyValue: fuzzyValue
        }

        findings.push(ret)
      }
    }
  }

  if (findings.length > 1) {
    findings.sort((a, b) => {
      return b.fuzzyValue - a.fuzzyValue;
    });
  }

  if (options.filterByPosition !== false) {
    findings = findings.filter((f) => { return f.positionTop > 10 });
  }

  return findings;
}
