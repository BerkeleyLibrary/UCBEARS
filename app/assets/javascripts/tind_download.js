//= require shared/flash_alerts
/* global flashAlerts */

const findCollectionUrl = '/tind-download/find_collection'

class TindDownload {
  // TODO: add constructor parameters so we don't keep re-jquerying for elements
  constructor () {
    this._autocompleteResults = new Set()
  }

  autocompleteCollection (request, response) {
    $.getJSON(
      findCollectionUrl,
      { collection_name: request.term },
      response
    )
  }

  updateAutocompleteResults (results) {
    for (const result of results) {
      this._autocompleteResults.add(result)
    }
  }

  handleSubmit (e) {
    e.preventDefault()
    flashAlerts.clear()

    const collectionName = this._collectionValue()
    this._validateCollectionName(
      collectionName,
      this._doSubmit.bind(this),
      function () {
        const msg = 'The collection ' + collectionName + ' does not exist.'
        flashAlerts.error(msg)
      }
    )
  }

  collectionNameChanged () {
    const submitButton = $('#export-btn')
    const collectionValue = this._collectionValue()
    const enabled = Boolean(collectionValue)

    submitButton.prop('disabled', !enabled)
  }

  _collectionValue () {
    const collectionNameField = document.querySelector('#collection_name')
    if (collectionNameField) {
      return collectionNameField.value
    }
  }

  _downloadForm () {
    return $('#download-form')
  }

  _validateCollectionName (collectionName, onSuccess, onFailure) {
    if (this._autocompleteResults.has(collectionName)) {
      return onSuccess()
    }

    $.ajax({
      type: 'GET',
      url: findCollectionUrl,
      data: {
        collection_name: collectionName,
        authenticity_token: $('input[name="authenticity_token"]').val()
      },
      success: function (data) {
        if (data.includes(collectionName)) {
          onSuccess()
        } else {
          onFailure()
        }
      },
      error: function () {
        onFailure()
      }
    })
  }

  _doSubmit () {
    this._hideForm()
    this._showDownloadMessage()
    this._downloadForm().submit()
  }

  _hideForm () {
    this._downloadForm().hide()
  }

  _showDownloadMessage () {
    const fallbackMsg = document.createElement('p')
    fallbackMsg.append('Your download should start momentarily. If it does not begin in a few seconds, ')
    fallbackMsg.append(this._createFallbackLink())
    fallbackMsg.append('.')
    flashAlerts.success(fallbackMsg)

    const returnToForm = document.createElement('p')
    const returnToFormLink = document.createElement('a')
    returnToFormLink.href = window.location.pathname
    returnToFormLink.append('Return to TIND Metadata Download form')
    returnToFormLink.className = 'title-link text-nowrap'
    returnToForm.append(returnToFormLink)

    flashAlerts.raw(returnToForm)
  }

  _createFallbackLink () {
    const fallback = document.createElement('a')
    const form = this._downloadForm()
    fallback.href = form.attr('action') + '?' + form.serialize()
    fallback.download = this._collectionValue() + '.' + $('input[name="export_format"]:checked').val()
    fallback.append('click here to download the file')
    return fallback
  }
}

const tindDownload = new TindDownload()

// TODO: name callback-wrapper functions & move them into tindDownload (see also _doSubmit() )
$(document).ready(function () {
  const $collectionName = $('#collection_name')
  if ($collectionName.length <= 0) {
    return
  }
  $collectionName.on('propertychange change click keyup input paste', function () {
    tindDownload.collectionNameChanged()
  })

  // TODO: highlight *unmatched* text
  //   cf. https://stackoverflow.com/questions/9887032/how-to-highlight-input-words-in-autocomplete-jquery-ui
  //   https://baymard.com/blog/autocomplete-design
  // TODO: add some sort of spinner to show we're working
  $collectionName.autocomplete({
    source: function (req, resp) { tindDownload.autocompleteCollection(req, resp) },
    response: function (event, ui) {
      if (ui.content) {
        const results = ui.content.map(function (v) { return v.value })
        tindDownload.updateAutocompleteResults(results)
      }
    }
  })

  const submitButton = $('#export-btn')
  submitButton.prop('disabled', true)
  submitButton.click(function (e) { tindDownload.handleSubmit(e) })
})
