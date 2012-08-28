/**
 * We add a ClientStide Validation to a remote for our date parsing.
 *
 * @param element
 * @param options
 * @return {*}
 */

clientSideValidations.validators.remote['date'] = function(element, options) {
    if ($.ajax({
        url: '/validators/date.json',
        data: { date: element.val() },
        // async *must* be false
        async: false
    }).status == 404) { return options.message; }
}