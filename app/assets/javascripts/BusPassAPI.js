/**
 * BusPassAPI.js
 */
BusPassAPI = function(options) {
    $.extend(this, options);
};

BusPassAPI.prototype = {
    loginUrl: "/webmap/api.json?majorVersion=1&minorVersion=0",

    apiMap : {},

    _loggedIn : false,

    isLoggedIn : function() {
        return this._loggedIn;
    },

    name : "BuspassAPI",
    _onAPIResponse : function(http, cb) {
        var callback = function (event) {
            alert( event + "\n" + http.readyState + "." + http.status + "//" + http.responseText);
            if (http.readyState == 4) {
                if (http.status == 200) {
                    var apiXML = http.responseXML;
                    this._loadAPIMap(apiXML);
                    this._loggedIn = true;
                    cb(this,true);
                } else {
                    cb(this,false);
                };
            };
        };
        return callback.bind(this);
    },

    _loadAPIMap : function(api) {
        this.apiMap = $.extend(this.apiMap, api);
    },

    login : function(finished) {
        api = this;
        loginCallback = function(result, status, response) {
            console.log("API.login: " + status + " " + $.toJSON(response));
            if (status == "success") {
                if (response.status == 200) {
                    api._loadAPIMap(result);
                    api._loggedIn = true;
                    if (finished != null) {
                        finished(api);
                    }
                } else {
                    if (finished != null) {
                        finished(null);
                    }
                }
            } else {
                if (finished != null) {
                    finished(null);
                }
            }
        }
        $.get(this.loginUrl, loginCallback, "json");
    },


    fetchRouteJourneyIds : function(successC, failureC) {
        url = this.apiMap["getRouteJourneyIds"];
        var api = this;
        function resultC(result, status, response) {
            if (status == "success") {
                if (successC != null) {
                    successC(result);
                }
            } else {
                if (failureC != null) {
                    failureC(response);
                }
            }
        }
        var url = this.apiMap["getRouteJourneyIds"];
        var parts = url.split("?");
        if (parts.length > 1) {
            url = parts[0] + ".json" + "?" + parts[1];
        }
        $.get(url, resultC, "json");
    },

    fetchRouteDefinition : function( nameid, successC, failureC ) {
        var api = this;
        api.fetchRouteDefinitionData( nameid, function(data) {
            var route = new Route(data);
            if (successC != null) {
                successC(route);
            }
        }, function(message) {
            if (failureC != null) {
                failureC(message);
            }
        });
    },

    fetchCurrentLocation : function( nameid, successC, failureC ) {
        var api = this;

        // The result Continuation
        function resultC(result, status, response) {
            console.log("HTTP Route Def: " + $.toJSON(response));
            if (status == "success") {
                if (successC != null) {
                    successC(result);
                }
            } else {
                if (failureC != null) {
                    failureC(response);
                }
            }
        }

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
        $.get(url+args, resultC, "json");
    },

    fetchRouteDefinitionData : function( nameid, successC, failureC ) {
        var api = this;

        // The result Continuation
        function resultC(result, status, response) {
            console.log("HTTP Route Def: " + $.toJSON(response));
            if (status == "success") {
                if (successC != null) {
                    successC(result);
                }
            } else {
                if (failureC != null) {
                    failureC(response);
                }
            }
        }

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
        $.get(url+args, resultC, "json");
    },

};