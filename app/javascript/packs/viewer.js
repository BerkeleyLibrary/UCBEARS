import Mirador from 'mirador/dist/es/src/index.js'

window.addEventListener('load', () => {
  const iiifViewer = document.getElementById('iiif_viewer')
  if (!iiifViewer) {
    console.log('iiif_viewer not found')
    return
  }

  const manifestId = iiifViewer.dataset.manifestId

  // See https://github.com/ProjectMirador/mirador/blob/master/src/config/settings.js
  const config = {
    id: iiifViewer.id,
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
    window: {
      allowFullscreen: true,
      allowMaximize: false,
      defaultView: 'single',
      panels: {
        attribution: false,
        info: true,
        search: true // TODO: implement search
      },
      sideBarOpen: true,
      views: [
        { key: 'single' },
        { key: 'book' },
        { key: 'scroll' }
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

  const viewer = Mirador.viewer(config)
  window.miradorInstance = viewer

  // Test via a getter in the options object to see if the passive property is accessed
  // -- see https://github.com/WICG/EventListenerOptions/blob/gh-pages/explainer.md#feature-detection
  let supportsPassive = false
  try {
    const opts = Object.defineProperty({}, 'passive', {
      get: function () {
        supportsPassive = true
      }
    })
    window.addEventListener('testPassive', null, opts)
    window.removeEventListener('testPassive', null, opts)
  } catch (e) {
    // passive event listeners not supported
  }

  const unsubscriber = {}
  unsubscriber.unsubscribe = viewer.store.subscribe(() => {
    const osdCanvas = document.querySelector('div.openseadragon-canvas')

    if (osdCanvas) {
      osdCanvas.addEventListener('wheel', (event) => {
        event.stopPropagation()
      }, supportsPassive ? { passive: false } : { capture: true })

      unsubscriber.unsubscribe()
    }
  })
})
