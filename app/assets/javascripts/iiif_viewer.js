// TODO: don't load this in application.js
//= require mirador

/* global miradorInstance */

/* exported miradorTest */

function miradorTest () {
  if (typeof (miradorInstance) === 'undefined') {
    return
  }

  const vstate = miradorInstance.viewer.state
  const windowObjects = vstate.currentConfig.windowObjects
  const windowObject = windowObjects[0]
  const windowID = windowObject.id

  miradorInstance.eventEmitter.subscribe('currentCanvasIDUpdated.' + windowID, function (_) {
    // const $overlay = $('.overlay');
    // if ($overlay.length <= 0) {
    //   return
    // }
    // const overlay = $overlay[0]

    const canvasId = windowObject.canvasID
    const canvasObj = windowObject.canvases[canvasId]
    const canvas = canvasObj.canvas
    const metadata = canvas.metadata
    metadata.forEach(elem => console.log(elem.label + ': ' + elem.value))
  })
}
