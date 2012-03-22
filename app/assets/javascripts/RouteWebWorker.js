/**
 * This a HTML5 WebWorker.
 */
self.importScripts("/assets/jquery.hive.pollen.js");
self.importScripts("/assets/WorkerBusPassAPI.js");

self.loadJourneyIds = function(data) {
    var busAPI = new BusPassAPI(data.apiMap);
    data.status = "Start";
    self.postMessage(data);
    busAPI.fetchRouteJourneyIds(data.routeids, function (journeyids) {
            data.status = "Success";
            data.journeyids = journeyids;
            self.postMessage(data);
        }, function (message) {
            data.status = "IOError";
            data.message = message;
            self.postMessage(data);
        });
};

self.fetchRoute = function(data) {
    var busAPI = new BusPassAPI(data.apiMap);
    data.status = "Start";
    self.postMessage(data);
    busAPI.fetchRouteDefinitionData(data.journeyid, function(route) {
            data.status = "Success";
            data.route = route;
            self.postMessage(data);
        }, function (message) {
            data.status = "IOError";
            data.message = message;
            self.postMessage(data);
        });
}

self.addEventListener('message', function(e) {
    var data = e.data;
    switch (data.cmd) {
        case 'loadJourneyIds':
            self.loadJourneyIds(data);
            break;
        case 'fetchRoute':
            self.fetchRoute(data);
            break;
        default:
            self.postMessage('Unknown command: ' + data.msg);
    };
}, false);