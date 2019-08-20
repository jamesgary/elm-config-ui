// From https://github.com/jamesgary/elm-config-ui/blob/master/elm-config-ui-helper.js

// See pointerlock docs at https://developer.mozilla.org/en-US/docs/Web/API/Pointer_Lock_API

let hasFirstMouseMoveEventPassedDueToWebkitBug = false;

let ConfigForm = {
  init: function(app) {
    function updatePosition(e) {
      if (hasFirstMouseMoveEventPassedDueToWebkitBug) {
        app.ports.receiveFromPort.send({
          id: "CONFIG",
          val: {
            id: "MOUSE_MOVE",
            x: e.movementX,
          },
        });
      } else {
        console.log("Ignoring dumb bad movementX:", e.movementX);
        hasFirstMouseMoveEventPassedDueToWebkitBug = true;
      }
    }

    function mouseUp(e) {
      document.exitPointerLock();
      app.ports.receiveFromPort.send({
        id: "CONFIG",
        val: {
          id: "MOUSE_UP",
        },
      });
    }

    document.addEventListener('pointerlockchange', function() {
      if (document.pointerLockElement === node) {
        document.addEventListener("mousemove", updatePosition, false);
        document.addEventListener("mouseup", mouseUp, false);
        hasFirstMouseMoveEventPassedDueToWebkitBug = false;
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
};
