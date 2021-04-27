const findCollectionUrl = '/tind-download/find_collection';

class TindDownload {
    // TODO: add constructor so we don't keep re-jquerying for elements

    _autocompleteResults = new Set();

    autocompleteCollection(request, response) {
        $.getJSON(
            findCollectionUrl,
            {collection_name: request.term},
            response,
        );
    }

    updateAutocompleteResults(results) {
        for (let result of results) {
            this._autocompleteResults.add(result);
        }
    }

    handleSubmit(e) {
        e.preventDefault();
        flashAlerts.clear();

        let collectionName = this._collectionValue();
        this._validateCollectionName(
            collectionName,
            this._doSubmit.bind(this),
            function () {
                let msg = `The collection "${collectionName}" does not exist.`;
                flashAlerts.error(msg);
            }
        );
    }

    collectionNameChanged() {
        let submitButton = $('#export-btn');
        let collectionValue = this._collectionValue();
        let enabled = Boolean(collectionValue);

        submitButton.prop('disabled', !enabled);
    }

    _collectionValue() {
        let collectionNameField = document.querySelector('#collection_name');
        if (collectionNameField) {
            return collectionNameField.value;
        }
    }

    _downloadForm() {
        return $('#download-form');
    }

    _validateCollectionName(collectionName, onSuccess, onFailure) {
        if (this._autocompleteResults.has(collectionName)) {
            return onSuccess();
        }

        $.ajax({
            type: 'GET',
            url: findCollectionUrl,
            data: {
                collection_name: collectionName,
                authenticity_token: $('input[name="authenticity_token"]').val(),
            },
            success: function (data) {
                if (data.includes(collectionName)) {
                    onSuccess();
                } else {
                    onFailure();
                }
            },
            error: function () {
                onFailure();
            }
        });
    }

    _doSubmit() {
        this._hideForm();
        this._showDownloadMessage();
        this._downloadForm().submit();
    }

    _hideForm() {
        this._downloadForm().hide()
    }

    _showDownloadMessage() {
        let fallbackMsg = document.createElement('p');
        fallbackMsg.append('Your download should start momentarily. If it does not begin in a few seconds, ');
        fallbackMsg.append(this._createFallbackLink());
        fallbackMsg.append('.');
        flashAlerts.success(fallbackMsg)

        let returnToForm = document.createElement('p');
        let returnToFormLink = document.createElement('a');
        returnToFormLink.href = window.location.pathname
        returnToFormLink.append('Return to TIND Metadata Download form')
        returnToFormLink.className = 'title-link text-nowrap'
        returnToForm.append(returnToFormLink)

        flashAlerts.raw(returnToForm);
    }

    _createFallbackLink() {
        let fallback = document.createElement('a');
        let form = this._downloadForm();
        fallback.href = form.attr('action') + '?' + form.serialize();
        fallback.download = this._collectionValue() + '.' + $('input[name="export_format"]:checked').val()
        fallback.append('click here to download the file');
        return fallback;
    }
}

const tindDownload = new TindDownload();

// TODO: name callback-wrapper functions & move them into tindDownload (see also _doSubmit() )
$(document).ready(function () {
    let collectionNameField = $('#collection_name');
    collectionNameField.on('propertychange change click keyup input paste', function() {
        tindDownload.collectionNameChanged();
    });

    // TODO: highlight *unmatched* text
    //   cf. https://stackoverflow.com/questions/9887032/how-to-highlight-input-words-in-autocomplete-jquery-ui
    //   https://baymard.com/blog/autocomplete-design
    // TODO: add some sort of spinner to show we're working
    collectionNameField.autocomplete({
        source: function(req, resp) { tindDownload.autocompleteCollection(req, resp) },
        response: function (event, ui) {
            if (ui.content) {
                let results = ui.content.map(v => v.value);
                tindDownload.updateAutocompleteResults(results);
            }
        }
    });

    let submitButton = $('#export-btn');
    submitButton.prop('disabled', true);
    submitButton.click(function(e) { tindDownload.handleSubmit(e) });
});
