let findCollectionUrl = "/tind-download/find_collection";
let findCollectionParams = ['collection_name', 'authenticity_token']

// TODO: add some sort of spinner to show we're working
$(function () {
    // TODO: highlight *unmatched* text
    //   cf. https://stackoverflow.com/questions/9887032/how-to-highlight-input-words-in-autocomplete-jquery-ui
    // https://baymard.com/blog/autocomplete-design
    $("#collection_name").autocomplete({
        source: findCollectionUrl
    })
})

// Used to enable/disable the submit button - no collection name, no submit!
function checkCollectionValue() {
    let collectionNameField = document.querySelector('#collection_name')
    if (collectionNameField && collectionNameField.value) {
        enableElement('export-btn')
    }
    disableElement('export-btn')
}

function collectionExists(collectionName) {
    let authenticityToken = $('input[name="authenticity_token"]').val()
    let queryParams = [
        { name: 'authenticity_token', value: authenticityToken },
        { name: 'term', value: collectionName }
    ]
    let queryUrl = findCollectionUrl + '?' + $.param(queryParams);

    // TODO: get this closure working
    var exists = false
    $.getJSON(queryUrl, function(data) {
        exists = data.includes(collectionName)
    })
    return exists;
}

function setFallbackHref() {
    let form = downloadForm();
    let fallbackUrl = form.attr('action') + '?' + form.serialize();
    document.getElementById('fallback-download-link').href = fallbackUrl;
}

function downloadForm() {
    return $('#download-form');
}

$(document).ready(function() {
    $.validator.addMethod('collectionExists', function(val, element) {
        return collectionExists(val)
    }, function(params, element) {
        return 'The collection "' + element.value + '" does not exist.';
    })

    downloadForm().validate({
        rules: {
            collection_name: {
                required: true,
                collectionExists: true
            }
        }
    })
})

// Submit the form, after a few odds and ends that are easier to do on the front end
function downloadFile() {
    // Clear out any flash alerts that user may have gotten before submitting the file:
    let alerts = document.querySelector('.alerts')
    if (alerts) {
        alerts.remove()
    }

    // Before downloading, change the page to show the 'your download should start soon'
    // message since rails doesn't allow you to download and then render the page:
    toggleBlock('response-div', true);
    toggleBlock('form-div', false);
    toggleBlock('description-text', false);

    // NOW submit the form which should kick off the download:
    downloadForm().submit();
}
