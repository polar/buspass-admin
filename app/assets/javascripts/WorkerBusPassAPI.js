/**
 * BusPassAPI.js
 *  needs jquery.hive.pollen.js
 */
BusPassAPI = function(apiMap) {
    this.apiMap = apiMap;
};

BusPassAPI.prototype = {
    apiMap : {},

    fetchRouteJourneyIds : function(routeids, successC, failureC) {
        url = this.apiMap["getRouteJourneyIds"];
        var api = this;
        function resultC(result) {
            // I think this. is the request
            if (this.status == 200) {
                if (successC != null) {
                    successC(result);
                }
            } else {
                if (failureC != null) {
                    failureC(this.responseText);
                }
            }
        };
        var parts = url.split("?");
        if (parts.length > 1) {
            url = parts[0] + ".json" + "?" + parts[1];
        } else {
            url = url + ".json" + "?web=1";
        }
        if (routeids != null && routeids.length > 0) {
            url += "&routes=";
            var ids = [];
            for(var i = 0; i < routeids.length; i++ ) {
                ids.push(routeids[i].id);
            }
            url += ids.join(",");
        }
        $.ajax.get( { url: url, success: resultC, dataType: "json" });
    },


    fetchRouteDefinitionData : function( nameid, successC, failureC ) {
        var api = this;
        function resultC(result) {
            // I think this. is the request
            if (this.status == 200) {
                if (successC != null) {
                    successC(result);
                }
            } else {
                if (failureC != null) {
                    failureC(this.responseText);
                }
            }
        }
        var args = "";
        var url = this.apiMap["getRouteDefinition"];
        var parts = url.split("?");
        if (parts.length > 1) {
            url = parts[0] + "/" + nameid.id + ".json" + "?" + parts[1];
        } else {
            url = url + "/" + nameid.id+  ".json" + "?web=1";
        }
        if (nameid.type != null) {
            args += "&type=" + nameid.type;
        }
        $.ajax.get( { url: url+args, success: resultC, dataType: "json"});
    },

    fetchCurrentLocationData : function( nameid, successC, failureC ) {
        var api = this;
        function resultC(result) {
            // I think this. is the request
            if (this.status == 200) {
                if (successC != null) {
                    successC(result);
                }
            } else {
                if (failureC != null) {
                    failureC(this.responseText);
                }
            }
        }
        var args = "";
        var url = this.apiMap["getJourneyLocation"];
        var parts = url.split("?");
        if (parts.length > 1) {
            url = parts[0] + "/" + nameid.id + ".json" + "?" + parts[1];
        } else {
            url = url + "/" + nameid.id+  ".json" + "?web=1";
        }
        if (nameid.type != null) {
            args += "&type=" + nameid.type;
        }
        $.ajax.get( { url: url+args, success: resultC, dataType: "json"});
    }
};