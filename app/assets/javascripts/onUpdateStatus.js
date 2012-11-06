/**
 * Deployments Controller
 *
 * @requires ActivePlanBasketController
 */

var activePlanView;

var clock_set = false;

function onUpdateStatus(data) {
    console.log("onUpdateStatus");
    if (data == null) {
        $('#start')[0].disabled = false;
        $('#stop')[0].disabled = true;
        return;
    }
    var mult = 1;
    if (data['clock_mult'] !== undefined) {
        mult = data['clock_mult'] + 0;
        if (mult > 1) {
            activePlanView.basket.setPollTime(10000 / mult);
            activePlanView.activePlanController.overrideLocationPollTime(30000 / mult);
        }
    }
    if (data['sim_time'] !== undefined) {
        if (!clock_set && data['status'] != "Stopped") {
            if (data['sim_time'] && data['started_at']) {
                var sim_time = Date.parse(data['sim_time']).getTime();
                var time_start = Date.parse(data['started_at']).getTime();
                var time_diff = (Date.now() - time_start);
                sim_time += time_diff * mult;
                $("#sim_clock").clock({format:"24", timestamp:sim_time, 'mult':mult});
                $("#sim_clock").show();
                clock_set = true;
            }
        }
    }
    if (data['status']) {
        if (data['status'] == "Stopped") {
            $("#sim_clock").clock("destroy");
            $("#sim_clock").hide();
            clock_set = false;
        }
    }
    $("#start").attr("disabled", !data['start']);
    $("#stop").attr("disabled", !data['stop']);
}

