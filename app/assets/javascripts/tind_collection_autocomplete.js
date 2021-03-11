// TODO: add some sort of spinner to show we're working

$(function() {
    // TODO: highlight *unmatched* text
    //   cf. https://stackoverflow.com/questions/9887032/how-to-highlight-input-words-in-autocomplete-jquery-ui
    // https://baymard.com/blog/autocomplete-design
    $("#collection_name").autocomplete({
        source: "/tind-download/find_collection"
    })
})
