//
//= require jquery
//= require jquery_ujs
//= require jshashtable-2.1
//= require bootstrap
//= require jquery.layout-latest
//= require jquery.jscrollpane.min
//= require jquery.mousewheel
//= require jquery-ui
//= require sitemapstyler
//= require rails.validations
//= require flash
//= require chronic_date_validator
//= require v0.34/html2canvas
//= require_self

function pullScreenShot(elements) {
    var html2obj = html2canvas(elements);

    var queue = html2obj.parse();
    var canvas = html2obj.render(queue);
    var img = canvas.toDataURL();

    return img;
}

$(function () {
    // We need to use a separate div for the page because of html2canvas getting
    // a psuedo-screenshot without the modal dialog. Therefore, we need to to
    // resize with the browser.
    $("#ui-layout-container").height($(document).height());
    $(window).resize(function() {
        $("#ui-layout-container").height($(document).height());
    });
    $("#ui-layout-container").layout({ applyDefaultStyles: true });

    // This is the feedback modal form submit. We get a screen shot of the "ui-layout-container"
    // It modifies the form control with the data of the screen shot.
    $("#form_feedback_submit").click(function () {
        $("#FeedbackModal").modal("hide");
        if ($("#feedback_include_screenshot").is(":checked")) {
            var img = pullScreenShot($("#ui-layout-container"));
        }
        $("#feedback_screenshot_data").attr("value", img);
        // submit will happen from here.
    });
});


/*
 * Intercom integration. This relies on filled in forms in the layouts.
 */
$(function () {
    var i = function () {
        i.c(arguments)
    };
    i.q = [];
    i.c = function (args) {
        i.q.push(args)
    };
    window.Intercom = i;
    function async_load() {
        var s = document.createElement('script');
        s.type = 'text/javascript';
        s.async = true;
        s.src = 'https://api.intercom.io/api/js/library.js';
        var x = document.getElementsByTagName('script')[0];
        x.parentNode.insertBefore(s, x);
    }

    if (window.attachEvent) {
        window.attachEvent('onload', async_load);
    } else {
        window.addEventListener('load', async_load, false);
    }
});
