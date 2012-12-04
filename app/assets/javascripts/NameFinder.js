/**
 * NameFinder
 *  Returns results in parsed JSON.
 *
 * @type {*}
 */

BusPass.NameFinder = OpenLayers.Class({
    nominatimUrl : "/transport.php?url=http://nominatim.openstreetmap.org",

    initialize : function (options) {
        options = OpenLayers.Util.extend({}, options);
        OpenLayers.Util.extend(this, options);
    },

    getNameFromLocation : function (lonlat, callback) {
        var url = this.nominatimUrl + "/reverse/?format=json";
        var parameters = "&lon=" + lonlat.lon + "&lat=" + lonlat.lat;

        $.get(url + parameters, {},
            function(json) {
                console.log("Received : " + json);
                var result = JSON.parse(json);
                callback(result);
            },
            "text");
        console.log("getNameFromLocation: sent " + parameters);
    },

    getLocationFromName : function (name, callback) {
        var url = this.nominatimUrl + "/search/?format=json";
        var parameters = "%q=" + Url.encode(name);

        $.get(url + parameters, {},
            function(json) {
                var result = JSON.parse(json);
                callback(result);
            },
            "text");
    },

    CLASS_NAME : "BusPass.NameFinder"
});