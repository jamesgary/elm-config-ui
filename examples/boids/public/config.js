class ElmConfigUiSlider extends HTMLElement {
  constructor() {
    return super();
  }

  connectedCallback() {
    let self = this; //document.getElementById("elm-config-ui-pointerlock");

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

window.customElements.define('elm-config-ui-slider', ElmConfigUiSlider);

window.ElmConfigUi = {
  // helper functions

  loadJsonFromLocalStorage: function(key) {
    JSON.parse(localStorage.getItem(key));
  },

  loadJsonFile: function(filepath, callback) {
    fetch(filepath)
      .then(function(resp) { return resp.json() })
      .then(callback);
  },
};

/*
  init: function(app) {

    document.addEventListener('pointerlockchange', function() {
      if (document.pointerLockElement === node) {
        document.addEventListener("mousemove", updatePosition, false);
        document.addEventListener("mouseup", mouseUp, false);
      } else {
        document.removeEventListener("mousemove", updatePosition, false);
        document.removeEventListener("mouseup", mouseUp, false);
      }
    }, false);
  },

  receivePortMsg: function(effect, node) {
    switch (effect) {
      case "LOCK_POINTER":
        node.requestPointerLock();
        break;
      default:
        console.error("Unknown ConfigEffect", effect.val);
    }
  },

*/
