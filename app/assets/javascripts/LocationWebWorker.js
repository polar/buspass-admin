/**
 * This a HTML5 WebWorker.
 */
self.importScripts("/assets/jquery.hive.pollen.js");
self.importScripts("/assets/WorkerBusPassAPI.js");

self.getCurrentLocationData = function(data) {
    var busAPI = new BusPassAPI(data.apiMap);
    busAPI.fetchCurrentLocationData(data.nameid, function (locationData) {
            data.status = "Success";
            data.locationData = locationData;
            self.postMessage(data);
        }, function (message) {
            data.status = "IOError";
            data.message = message;
            self.postMessage(data);
        });
};

self.addEventListener('message', function(e) {
    var data = e.data;
    switch (data.cmd) {
        case 'getCurrentLocationData':
            self.getCurrentLocationData(data);
            break;
        default:
            self.postMessage('Unknown command: ' + data.message);
    };
}, false);