// TODO: add some sort of spinner to show we're working

$(function () {
    // TODO: highlight *unmatched* text
    //   cf. https://stackoverflow.com/questions/9887032/how-to-highlight-input-words-in-autocomplete-jquery-ui
    // https://baymard.com/blog/autocomplete-design
    $("#collection_name").autocomplete({
        source: "/tind-download/find_collection"
    })
})

// Used to enable/disable the submit button - no collection name, no submit!
function checkCollectionValue() {
    let col_name = document.getElementById('collection_name').value || null;

    if (col_name) {
        toggleDisable('export-btn', false);
    } else {
        toggleDisable('export-btn', true);
    }
}

// Submit the form, after a few odds and ends that are easier to do on the front end
function downloadFile() {

    // Clear out any flash alerts that user may have gotten before submitting the file:
    let flash_alert = document.getElementsByClassName('alert')[0] || null;

    if (flash_alert) {
        document.getElementsByClassName('alert')[0].style.display = "none";
    }

    // Before downloading, change the page to show the 'your download should start soon'
    // message since rails doesn't allow you to download and then render the page:
    toggleBlock('response-div', true);
    toggleBlock('form-div', false);
    toggleBlock('description-text', false);

    // NOW submit the form which should kick off the download:
    document.forms["down-form"].submit();
}
