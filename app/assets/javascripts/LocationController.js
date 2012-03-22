BusPass.LocationController = function (options) {
    this._routes = [];
    this._active = true;
    $.extend(this,options);

    // Set up Worker.
    this._worker = new Worker("/assets/LocationWebWorker.js");
    var ctrl = this;
    this._worker.addEventListener('message', function(e) {
        var data = e.data;
        switch (data.cmd) {
            case 'getCurrentLocationData':
                ctrl._getCurrentLocationReturn(data);
                break;
            default:
                console.log("LocationController: Unknown command from worker: " + data);
        };
    }, false);

    this._worker.addEventListener( 'error', function (event) {
        console.log("LocationController.worker: " + event.message, event);
    }, false);
};

BusPass.LocationController.prototype = {

    onLocationReceived : function(route, locationData) {
    },

    addRoute : function(route) {
        this._routes.push(route);
        if (route.isJourney()) {
            this._setUpdating(route, true);
            if (this._active) {
                this._runUpdate(this,route);
            }
        }
    },

    removeRoute : function(route) {
        var rs = [];
        for(var r = 0; r < this._routes.length; r++) {
            if (this._routes[r] != route) {
                rs.push(this._routes[r]);
            };
        }
        route.__updating = false;
        this._routes = rs;
    },

    startUpdating : function(route) {
        if (route.isJourney()) {
            route.__updating = true;
            if (this._isActive()) {
                this._runUpdate(this, route);
            }
        }
    },

    startUpdateAll : function () {
        if (this._active) {
            for(var i = 0; i < this._routes.length; i++) {
                this.startUpdating(this._routes[i]);
            }
        }
    },

    setActive : function (state) {
        this._active = state;
    },

    _isActive : function () {
        return this._active;
    },

    _setUpdating : function(route, state) {
        // We install our own attribute on the Route.
        route.__updating = state;
    },

    _runUpdate : function (ctrl, route) {
        if (ctrl._isActive() && route.__updating) {
            // send worker info
            data = {
                cmd : "getCurrentLocationData",
                nameid : route.getNameId(),
                apiMap: this.busAPI.apiMap,
            };
            this._worker.postMessage(data);
            // Continue
            // TODO: is this a closure memory leak?
            setTimeout(function () {
                ctrl._runUpdate(ctrl, route);
            }, route.getLocationRefreshRate() * 1000);
        }
    },

    _getCurrentLocationReturn : function (data) {
        console.log("LocationController._getCurrentLocationReturn:" + $.toJSON(data));
        var status = data.status;
        switch (status) {
            case 'Start' :
                break;
            case 'Success':
                var locationData = data.locationData;
                this._onCurrentLocationReceived(locationData);
                break;
            case 'IOError':
                this._onCurrentLocationError(data.message);
                break;
            default:
                console.log("JourneyBasket: Unknown response from worker - " + data.status);
        }
    },

    _onCurrentLocationReceived : function (locationData) {
        // Find the route
        for (var i = 0; i < this._routes.length; i++) {
            var route = this._routes[i];
            if (locationData.type == route.getType() &&
                locationData.id == route.getId()) {
                    this.onLocationReceived(route, locationData);
                    return;
                }
        }
        console.log("LocationController: cannot find route for " + $.toJSON(locationData));
    },

    /**
     * Method: private _onCurrentLocationError
     *
     * This method is called upon an error return of the current location.
     *
     * Parameters:
     * ioe  <String> Error message.
     */
    _onCurrentLocationError : function(ioe) {
        console.log(ioe.message);
        console.log("LocationController: Error getting current location :" + ioe.message);
    },

    onCreate : function () {
        this._routes = [];
        this._active = true;
    },

    onStart : function () {
        var ctrl = this;
        this._active = true;
        for(var i = 0; i < this._routes.length; i++) {
            var route = this._routes[i];
            if (route.isJourney()) {
                this._setUpdating(route, true);
            }
        }
    },

    onResume : function () {
        var ctrl = this;
        this._active = true;
        for(var i = 0; i < this._routes.length; i++) {
            var route = this._routes[i];
            if (route.isJourney() && route.__updating) {
                this._runUpdate(ctrl, route);
            }
        }
    },

    onPause : function () {
        var ctrl = this;
        this._active = false;
    },

    onStop : function () {
        var ctrl = this;
        this._active = false;
        for(var i = 0; i < this._routes.length; i++) {
            var route = this._routes[i];
            if (route.isJourney()) {
                route.__updating = false;
            }
        }
    },

    onRestart : function () {
        this._routes = [];
        this._active = true;
    },

    onDestroy : function () {
        this._routes = [];
    }
};