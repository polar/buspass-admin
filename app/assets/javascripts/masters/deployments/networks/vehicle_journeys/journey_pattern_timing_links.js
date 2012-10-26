/*
 *= require OpenLayers-2.12/OpenStreetMap
 *= require ClickLocationControl
 *= require WaypointModifyFeatureControl
 *= require routing
 *= require PathFinderController
 */

function init(center, startPoint, endPoint, defaultRoute, isConsistent, backRoute) {
    var controller = new BusPass.PathFinderController({
        center : center,
        startPoint : startPoint,
        endPoint : endPoint,
        defaultRoute : defaultRoute,
        backRoute : backRoute,
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
    $("#jptls_kml_1").val(
        $("#copybox_field").val());
    $("#jptls_kml_2").val(
        $("#copybox_field").val());

}
function select_one_1(e) {
    $("#form_update_jptls_1 input[type=checkbox].all").attr("checked", false);
    $("#form_update_jptls_1 input[type=checkbox].one").attr("checked", true);
}
function select_all_1(e) {
    $("#form_update_jptls_1 input[type=checkbox].all").attr("checked", true);
}
function select_same_1(e) {
    $("#form_update_jptls_1 input[type=checkbox].all").attr("checked", false);
    $("#form_update_jptls_1 input[type=checkbox].same").attr("checked", true);
}
function select_note_1(e) {
    $("#form_update_jptls_1 input[type=checkbox].all").attr("checked", false);
    $("#form_update_jptls_1 input[type=checkbox].note").attr("checked", true);
}

function select_one_2(e) {
    $("#form_update_jptls_2 input[type=checkbox].all").attr("checked", false);
    $("#form_update_jptls_2 input[type=checkbox].one").attr("checked", true);
}
function select_all_2(e) {
    $("#form_update_jptls_2 input[type=checkbox].all").attr("checked", true);
}
function select_same_2(e) {
    $("#form_update_jptls_2 input[type=checkbox].all").attr("checked", false);
    $("#form_update_jptls_2 input[type=checkbox].same").attr("checked", true);
}
function select_note_2(e) {
    $("#form_update_jptls_2 input[type=checkbox].all").attr("checked", false);
    $("#form_update_jptls_2 input[type=checkbox].note").attr("checked", true);
}

function onSubmitForm1(e) {
    $("#update_waiting_1").show();
    return true;
}

function onSubmitForm2(e) {
    $("#update_waiting_2").show();
    return true;
}

$(function () {
    // Enable Twitter bootstrap dropdown menus.
    $('.dropdown-toggle').dropdown();

    $("#menu1_select_all").click(select_all_1);
    $("#menu1_select_one").click(select_one_1);
    $("#menu1_select_same").click(select_same_1);
    $("#menu1_select_note").click(select_note_1);
    $("#update_waiting_1").hide();

    $("#menu2_select_all").click(select_all_2);
    $("#menu2_select_one").click(select_one_2);
    $("#menu2_select_same").click(select_same_2);
    $("#menu2_select_note").click(select_note_2);
    $("#update_waiting_2").hide();

    $("#form_update_jptls_1").submit(onSubmitForm1);
    $("#form_update_jptls_2").submit(onSubmitForm2);
});

