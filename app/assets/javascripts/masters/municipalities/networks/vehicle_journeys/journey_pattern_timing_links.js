/*
 *= require OpenLayers-2.12/OpenStreetMap
 *= require ClickLocationControl
 *= require ModifyFeature
 *= require routing
 *= require PathFinderController
 */

function init(center, startPoint, endPoint, defaultRoute, isConsistent) {
    var controller = new BusPass.PathFinderController({
        center : center,
        startPoint : startPoint,
        endPoint : endPoint,
        defaultRoute : defaultRoute,
        onRouteUpdated : function(route) {
            copyToJPTLSForm();
        }
    });
    if (!isConsistent) {
        controller.setAutoroute(false)
    }
    // Initial setup for UPDATE JPTLS.
    copyToJPTLSForm();
}
/**
 * This function just copies the KML in the copy box, which was written
 * just before this call, to the jptls form.
 */
function copyToJPTLSForm() {
    $("#jptls_kml").val(
        $("#copybox_field").val());

}
function select_one(e) {
    $("input[type=checkbox].all").attr("checked", false);
    $("input[type=checkbox].one").attr("checked", true);

}
function select_all(e) {
    $("input[type=checkbox].all").attr("checked", true);
}
function select_same(e) {
    $("input[type=checkbox].all").attr("checked", false);
    $("input[type=checkbox].same").attr("checked", true);
}
function select_note(e) {
    $("input[type=checkbox].all").attr("checked", false);
    $("input[type=checkbox].note").attr("checked", true);
}
function onSubmitForm(e) {
    $("#update_waiting").show();
    return true;
}
$(function () {
    // Enable Twitter bootstrap dropdown menus.
    $('.dropdown-toggle').dropdown();
    $("#menu_select_all").click(select_all);
    $("#menu_select_one").click(select_one);
    $("#menu_select_same").click(select_same);
    $("#menu_select_note").click(select_note);
    $("#update_waiting").hide();
    $("#form_update_jptls").submit(onSubmitForm);
});

