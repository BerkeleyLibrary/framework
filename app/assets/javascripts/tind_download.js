const findCollectionUrl = '/tind-download/find_collection';

class TindDownload {
    autocompleteCollection(request, response) {
        $.getJSON(
            findCollectionUrl,
            {collection_name: request.term},
            response
        );
    }

    collectionValue() {
        let collectionNameField = document.querySelector('#collection_name');
        if (collectionNameField) {
            return collectionNameField.value;
        }
    }

    collectionExists() {
        let collectionName = this.collectionValue();
        var exists = false;
        $.ajax({
            type: 'GET',
            url: findCollectionUrl,
            data: {
                collection_name: collectionName,
                authenticity_token: $('input[name="authenticity_token"]').val(),
            },
            success: function (data) {
                exists = data.includes(collectionName);
            },
            async: false // TODO: find a way to avoid this
        });
        return exists;
    }

    validateCollectionName(collectionName, onSuccess, onFailure) {
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
            error: function() {
                onFailure();
            }
        });
    }

    handleSubmit() {
        let collectionName = this.collectionValue();
        flashAlerts.clear()
        this.validateCollectionName(
            collectionName,
            this.doSubmit,
            function() {
                let msg = `The collection "${collectionName}" does not exist.`;
                flashAlerts.addAlert(msg)
            }
        )
    }
    
    doSubmit() {
        // TODO: submit the form
    }
}

const tindDownload = new TindDownload();


// TODO: add some sort of spinner to show we're working
$(function () {
    // TODO: highlight *unmatched* text
    //   cf. https://stackoverflow.com/questions/9887032/how-to-highlight-input-words-in-autocomplete-jquery-ui
    // https://baymard.com/blog/autocomplete-design
    $('#collection_name').autocomplete({
        source: tindDownload.autocompleteCollection
    });
});

function setFallbackHref() {
    let form = downloadForm();
    let fallbackUrl = form.attr('action') + '?' + form.serialize();
    document.getElementById('fallback-download-link').href = fallbackUrl;
}

function downloadForm() {
    return $('#download-form');
}

// Submit the form, after a few odds and ends that are easier to do on the front end
function downloadFile() {
    flashAlerts.clear();

    // Before downloading, change the page to show the 'your download should start soon'
    // message since rails doesn't allow you to download and then render the page:
    toggleBlock('response-div', true);
    toggleBlock('form-div', false);
    toggleBlock('description-text', false);

    // NOW submit the form which should kick off the download:
    downloadForm().submit();
}

