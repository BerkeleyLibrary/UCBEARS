//= require mirador

/* global miradorInstance */

function currentMiradorWindow () {
  const vstate = miradorInstance.viewer.state
  const windowObjects = vstate.currentConfig.windowObjects
  return windowObjects[0]
}

function showMetadataInOverlay (metadata) {
  const $overlay = $('.overlay')
  if ($overlay.length <= 0) {
    console.log('.overlay not found')
    return
  }
  const overlay = $overlay[0]

  const canvasMetadataId = 'canvas-metadata'
  let canvasMetadata = overlay.querySelector('#' + canvasMetadataId)
  if (!canvasMetadata) {
    canvasMetadata = document.createElement('div')
    canvasMetadata.id = canvasMetadataId
    overlay.append(canvasMetadata)
  } else {
    let child
    while ((child = canvasMetadata.firstChild)) {
      child.remove()
    }
  }

  metadata.forEach(function (elem) {
    const label = document.createElement('div')
    label.className = 'sub-title'
    label.append(elem.label)
    canvasMetadata.append(label)

    const value = document.createElement('div')
    value.className = 'metadata-listing'
    value.append(elem.value)
    canvasMetadata.append(value)
  })
}

function addMetadataHandler (eventEmitter, windowObject) {
  console.log('Adding Mirador transcript handler for window "' + windowObject.id + '"')
  eventEmitter.subscribe('currentCanvasIDUpdated.' + windowObject.id, function (_) {
    const canvasId = windowObject.canvasID
    const canvasObj = windowObject.canvases[canvasId]
    const canvas = canvasObj.canvas
    const metadata = canvas.metadata
    showMetadataInOverlay(metadata)
  })
}

/* exported addMiradorMetadataHandler */
function addMiradorMetadataHandler () {
  if (typeof (miradorInstance) === 'undefined') {
    console.log('miradorInstance not found')
    return
  }
  const eventEmitter = miradorInstance.eventEmitter

  eventEmitter.subscribe('windowAdded', function (_) {
    const windowObject = currentMiradorWindow()
    addMetadataHandler(eventEmitter, windowObject)
  })
}
