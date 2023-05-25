import Mirador from 'mirador/dist/es/src/index.js'

window.addEventListener('load', initMiradorInstance)

function initMiradorInstance () {
  const iiifViewer = document.getElementById('iiif_viewer')
  if (!iiifViewer) {
    console.log('iiif_viewer not found')
    return
  }

  window.miradorInstance = createMiradorInstance(iiifViewer.id, iiifViewer.dataset.manifestId)
}

function createMiradorInstance (elementId, manifestId) {
  const config = miradorConfig(elementId, manifestId)
  const miradorInstance = Mirador.viewer(config)
  addConditionalListener(miradorInstance.store, disableOSDScrollToZoom)
  return miradorInstance
}

// See https://github.com/ProjectMirador/mirador/blob/master/src/config/settings.js
// TODO: externalize most of this?
function miradorConfig (elementId, manifestId) {
  return {
    id: elementId,
    windows: [{ manifestId: manifestId }],
    selectedTheme: 'dark',
    themes: {
      dark: {
        // See https://material-ui.com/customization/default-theme/
        // TODO: figure out how to share this with colors.scss
        palette: {
          shades: {
            main: '#46535e' // $color-background-reversed
          }
        },
        typography: {
          // TODO: figure out how to share this with shared.scss / fonts.scss
          fontFamily: 'freight-sans-pro, sans-serif',
          h1: {
            lineHeight: 4 / 3
          },
          h2: {
            lineHeight: 4 / 3
          },
          h3: {
            lineHeight: 4 / 3
          },
          h5: {
            fontSize: '1rem',
            lineHeight: 4 / 3
          },
          subtitle1: {
            lineHeight: 4 / 3,
            letterSpacing: '0em'
          },
          subtitle2: {
            lineHeight: 4 / 3,
            letterSpacing: '0em'
          },
          body1: {
            fontSize: '.8333rem',
            lineHeight: 4 / 3,
            letterSpacing: '0em'
          },
          body2: {
            fontSize: '.75rem',
            lineHeight: 4 / 3,
            letterSpacing: '0em'
          }
        },
        windowTopBarStyle: {
          // border
        }
      }
    },
    translations: {
      en: {
        nextCanvas: 'Next page',
        previousCanvas: 'Previous page',
        openCompanionWindow_info: 'Transcript'
      }
    },
    window: {
      allowFullscreen: true,
      allowMaximize: false,
      defaultView: 'single',
      panels: {
        info: true,
        attribution: false,
        canvas: false,
        annotations: false,
        search: false, // TODO: implement search
        layers: false
      },
      sideBarOpen: true,
      views: [
        { key: 'single' },
        { key: 'book' }
        // TODO: get vertical scroll working, see [mirador#3021](https://github.com/ProjectMirador/mirador/pull/3021)
      ]
    },
    thumbnailNavigation: {
      defaultPosition: 'far-right'
    },
    workspace: {
      draggingEnabled: false,
      allowNewWindows: false,
      showZoomControls: true,
      type: null
    },
    workspaceControlPanel: {
      enabled: false
    }
  }
}

function addConditionalListener (store, conditionalListener) {
  const unsubscriber = {}
  unsubscriber.unsubscribe = store.subscribe(() => {
    const doneListening = conditionalListener()
    if (doneListening) {
      unsubscriber.unsubscribe()
    }
  })
}

// Disable OpenSeadragon default scroll-to-zoom behavior
function disableOSDScrollToZoom () {
  const osdCanvas = document.querySelector('div.openseadragon-canvas')
  if (osdCanvas) {
    const supportsPassive = browserSupportsPassiveEventListeners()
    const listener = (event) => event.stopPropagation()
    if (supportsPassive) {
      osdCanvas.addEventListener('wheel', listener, { passive: false, capture: true })
    } else {
      osdCanvas.addEventListener('wheel', listener, true)
    }
    return true
  }
  return false
}

// Test via a getter in the options object to see if the passive property is accessed
// -- see https://github.com/WICG/EventListenerOptions/blob/gh-pages/explainer.md#feature-detection
function browserSupportsPassiveEventListeners () {
  let supportsPassive = false
  try {
    const opts = Object.defineProperty({}, 'passive', {
      get: () => {
        supportsPassive = true
      }
    })
    window.addEventListener('testPassive', null, opts)
    window.removeEventListener('testPassive', null, opts)
  } catch (e) {
    // passive event listeners not supported
  }
  return supportsPassive
}
