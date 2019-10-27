window.ElmConfigUi = {
  init: function({filepath, localStorageKey, callback}) {
    this.localStorageKey = localStorageKey;

    fetch(filepath)
      .then(function(resp) { return resp.json() })
      .then(function(fileJson) {
        callback({
          file: fileJson,
          localStorage: JSON.parse(localStorage.getItem(localStorageKey)),
        });
      });

    window.customElements.define('elm-config-ui-slider', ElmConfigUiSlider);
    window.customElements.define('elm-config-ui-json', ElmConfigUiJson);
  },
};

class ElmConfigUiSlider extends HTMLElement {
  constructor() {
    return super();
  }

  connectedCallback() {
    let self = this;

    function updatePosition(e) {
      self.dispatchEvent(new CustomEvent('pl', {
        detail: { x: e.movementX },
      }));
    }

    function mouseUp(e) {
      document.exitPointerLock();
      self.dispatchEvent(new CustomEvent('plMouseUp', e));
    }

    self.addEventListener('mousedown', function() {
      self.requestPointerLock();
    });

    document.addEventListener('pointerlockchange', function() {
      if (document.pointerLockElement === self) {
        document.addEventListener("mousemove", updatePosition, false);
        document.addEventListener("mouseup", mouseUp, false);
      } else {
        document.removeEventListener("mousemove", updatePosition, false);
        document.removeEventListener("mouseup", mouseUp, false);
      }
    }, false);
  }
}

class ElmConfigUiJson extends HTMLElement {
  constructor() {
    return super();
  }

  connectedCallback() {
    let self = this;
  }

  static get observedAttributes() {
    return ['data-encoded-config'];
  }

  attributeChangedCallback(name, oldValue, newValue) {
    console.log("localStorageKey", window.ElmConfigUi.localStorageKey);
    localStorage.setItem(window.ElmConfigUi.localStorageKey, newValue);
  }
}
