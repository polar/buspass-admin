/**
 * ActivePlanController
 *
 * @param options
 * @constructor
 *
 *= require LocationMapViewController
 *= require ListViewController
 *= require LocationController
 */
BusPass.ActivePlanController = function(options) {
    this._routes = [];
    $.extend(this,options);
    this._stateStack = [];
    this._stateStack.push(new BusPass.ActivePlanController.VisualState());

    if (this.disableRouteClick) {
        this._onMapRouteSelect = function () {};
        this._onListRouteClicked = function () {};
    }


    this._mapViewC = new BusPass.LocationMapViewController({
        scope : this,
        center : this.center,
        initialZoom : this.initialZoom,
        onRouteSelected : this._onMapRouteSelect,
        onRouteHighlighted : this._onMapRouteHighlight,
        onRouteUnhighlighted : this._onMapRouteunhighlight
    });
    var rctrl = this;
    this._listViewC = new BusPass.ListViewController({
        scope : this,
        // This will only happen if the Map fires a selection.
        onRouteHighlighted : this._onListRouteHighlight,
        onRouteUnhighlighted : this._onListRouteUnhighlight,
        onRouteClicked : function (ctrl, route) {
            rctrl._onListRouteClicked(ctrl,route);
        }
    });
    this._locationC = new BusPass.LocationController({
        busAPI : this.busAPI,
        onLocationReceived : function(route, locationData) {
            rctrl._onLocationReceived(route, locationData);
        }
    });
};

BusPass.ActivePlanController.VisualState = function() {
};
// Used as a State Object.
BusPass.ActivePlanController.VisualState.prototype = {
    SHOW_MAP : "SHOW_MAP",
    SHOW_ROUTE : "SHOW_ROUTE",
    SHOW_VEHICLE : "SHOW_VEHICLE",
    state : "SHOW_MAP",
    nearBy : false,
    onlyActive : false,
    selectedRoutes : null,
    selectedRouteCode : null,
    selectedRouteCodes : []
};

BusPass.ActivePlanController.prototype = {
    /**
     * Attribute: scope
     * This attribute is the context for the callbacks.
     */
    scope : null,

    onStateChanged : function (oldstate,newstate,direction) {},

    mapView : function (jq) {
        this._mapViewC.mapView(jq);
    },

    listView : function (jq) {
        this._listViewC.listView(jq);
    },

    controlView : function (jq) {
        this._controlViewC.controlView(jq);
    },

    backButton : function (jq) {
        var ctrl = this;
        jq.click(function () {
            ctrl.back();
        });
    },

    overrideLocationPollTime : function (pollTime) {
        this._locationC.pollTime = pollTime;
    },

    addRoute : function(route) {
        this._routes.push(route);
        this._listViewC.addRoute(route);
        this._mapViewC.addRoute(route);
        this._locationC.addRoute(route);
        this._updateActiveJourneys();

        this._setVisibility(this._stateStack[0], route);
        this._mapViewC.redraw();
        this._listViewC.redraw();
    },

    removeRoute : function(route) {
        var rs = [];
        for(var r = 0; r < this._routes.length; r++) {
            if (this._routes[r] != route) {
                rs.push(this._routes[r]);
            };
        }
        this._routes = rs;
        this._updateActiveJourneys();
        this._listViewC.removeRoute(route);
        this._mapViewC.removeRoute(route);
        this._locationC.removeRoute(route);
    },

    removeAllRoutes : function () {
        var rs = [];
        for (var r = 0; r < this._routes.length; r++) {
            rs.push(this._routes[r]);
        }
        this._routes = [];
        for (var r = 0; r < rs.length; r++) {
            this._listViewC.removeRoute(rs[r]);
            this._mapViewC.removeRoute(rs[r]);
            this._locationC.removeRoute(rs[r]);
        }
        this._updateActiveJourneys();
    },

    reset : function () {
        this._stateStack = [];
        this._stateStack.push(new BusPass.ActivePlanController.VisualState())
    },

    // For testing rightnow
    back : function () {
        console.log("back button pressesd");
        oldState = this._stateStack[0];
        if (this._stateStack.length > 1) {
            // pop
            this._stateStack.splice(0,1);
            for(var i = 0; i < this._routes.length; i++) {
                var route = this._routes[i];
                this._setVisibility(this._stateStack[0], route);
            }
            this._mapViewC.redraw();
            this.onStateChanged(oldState, this._stateStack[0], "BACKWARD");
        }
    },

    getOnlyActive : function() {
        return this._stateStack[0].onlyActive;
    },

    setOnlyActive : function (state) {
        oldState = this._stateStack[0];
        if (oldState.onlyActive != state) {
            var newState = new BusPass.ActivePlanController.VisualState();
            newState.state = oldState.state;
            newState.onlyActive = state;
            newState.selectedRouteCode = oldState.selectedRouteCode;
            newState.selecteRouteCodes = oldState.selectedRouteCodes;
            if (oldState.selectedRoutes != null) {
                newState.selectedRoutes = [];
                for(var j = 0; j < oldState.selectedRoutes.length; j++) {
                    // TODO: Maybe Only Active Routes?
                    newState.selectedRoutes.push(oldState.selectedRoutes[j]);
                }
            }

            this._stateStack.splice(0,0,newState);
            for(var i = 0; i < this._routes.length; i++) {
                var route = this._routes[i];
                this._setVisibility(newState, route);
            }
            this._mapViewC.redraw();
            this.onStateChanged(oldState, newState, "FORWARD");
        }
    },

    _onLocationReceived : function (route, locationData) {
        this._mapViewC.setLocation(route, locationData.lonlat, locationData.direction);
    },

    _onMapRouteSelect : function(route) {
        var state = this._stateStack[0];
        var newState = new BusPass.ActivePlanController.VisualState();

        switch (state.state) {
            case state.SHOW_MAP:
                // In the Android App, we select all routes under the mouse.
                // I'm not sure I can do that with the map features yet.
                // So, for now, selection only gets one route. So, we go
                // to SHOW_ROUTE.
                newState.state = newState.SHOW_ROUTE;
                newState.selectedRouteCode = route.getCode();
                newState.selectedRouteCodes = [route.getCode()];
                newState.selectedRoutes = null;

                this._mapViewC.unselectRoute(route);
                this._listViewC.unselectRouteNoTrigger(route);
                for(var i = 0; i < this._routes.length; i++) {
                    var route = this._routes[i];
                    this._setVisibility(newState, route);
                }
                this._stateStack.splice(0,0,newState);
                this.onStateChanged(state,newState, "FORWARD");
                break;
            case state.SHOW_ROUTE:
                if (route.isActiveJourney()) {
                    newState.state = newState.SHOW_VEHICLE;
                    newState.selectedRouteCode = route.getCode();
                    newState.selectedRouteCodes = [route.getCode()];
                    newState.selectedRoutes = [route];

                    this._mapViewC.unselectRoute(route);
                    this._listViewC.unselectRouteNoTrigger(route);
                    for(var i = 0; i < this._routes.length; i++) {
                        var route = this._routes[i];
                        this._setVisibility(newState, route);
                    }
                    this._stateStack.splice(0,0,newState);
                    this.onStateChanged(state,newState, "FORWARD");
                }
                break;
            case state.SHOW_VEHICLE:
                this._mapViewC.unselectRoute(route);
                this._listViewC.unselectRouteNoTrigger(route);
                break;
        }
    },

    _onListRouteClicked : function(ctrl, route) {
        var state = this._stateStack[0];
        var newState = new BusPass.ActivePlanController.VisualState();

        switch (state.state) {
            case state.SHOW_MAP:
                newState.state = newState.SHOW_ROUTE;
                newState.selectedRouteCode = route.getCode();
                newState.selectedRouteCodes = [route.getCode()];
                newState.selectedRoutes = [route];

                this._mapViewC.unselectRoute(route);
                this._listViewC.unselectRouteNoTrigger(route);
                for(var i = 0; i < this._routes.length; i++) {
                    var route = this._routes[i];
                    this._setVisibility(newState, route);
                }
                this._stateStack.splice(0,0,newState);
                this._mapViewC.redraw();
                this.onStateChanged(state,newState, "FORWARD");
                break;
            case state.SHOW_ROUTE:
                // If we click on a Route Definition we do nothing.
                if (route.isActiveJourney()) {
                    newState.state = newState.SHOW_VEHICLE;
                    newState.selectedRouteCode = route.getCode();
                    newState.selectedRouteCodes = [route.getCode()];
                    newState.selectedRoutes = [route];
                    for(var i = 0; i < this._routes.length; i++) {
                        var r = this._routes[i];
                        // Add the vehicles route definition.
                        if (route.getCode() == r.getCode() && r.isRouteDefinition()) {
                            newState.selectedRoutes.push(r);
                        }
                        this._setVisibility(newState, r);
                    }
                    this._stateStack.splice(0,0,newState);
                    this._mapViewC.moveAndCenterTo(route);
                    this._mapViewC.redraw();
                    this.onStateChanged(state,newState, "FORWARD");
                }
                break;
            case state.SHOW_VEHICLE:
                if (route.isActiveJourney()) {
                    this._mapViewC.moveToLocation(route);
                }
                //this._mapViewC.redraw();
                //this._listViewC.redraw();
                break;
        }
    },

    _onMapRouteHighlight : function(route) {
        this._listViewC.highlightRouteNoTrigger(route);
    },

    _onListRouteHighlight : function(route) {
        this._mapViewC.highlightRoute(route);
    },

    _onMapRouteunhighlight : function(route) {
        this._listViewC.unhighlightRouteNoTrigger(route);
    },

    _onListRouteUnhighlight : function(route) {
        this._mapViewC.unhighlightRoute(route);
    },

    getCurrentLocation : function() {
        return this._currentLocation;
    },

    getNearbyDistance : function () {
        return this._nearbyDistance;
    },

    // Of VisualState objects
    _stateStack : [],

    // This sets the visibility of the route according to the given state.
    _setVisibility : function(state, display) {
        console.log("setVisibility: state " + state.state + " nearby " + state.nearBy + " active: " + state.onlyActive + " code " + state.selectedRouteCode + " name: " + display.getDisplayName());
        if (state.nearBy && !display.isNearRoute(this.getCurrentLocation(), this.nearbyDistance())) {
            this._listViewC.setVisibility(display, false);
            this._mapViewC.setVisibility(display, false);
            this._mapViewC.setTracking(display,false);
            return true;
        }
        switch (state.state){
            case state.SHOW_MAP:
                this._mapViewC.setTracking(display,false);
                if(state.selectedRoutes == null ||
                    state.selectedRoutes.indexOf(display) != -1 ||
                    state.selectedRouteCodes.indexOf(display.getCode()) != -1) {
                    // We are in general mode, so we only show the Names of Route Definitions,
                    // and Active journeys, but we don't show the Active Journey names.
                    if (display.isRouteDefinition()) {
                        if (state.onlyActive) {
                            this._listViewC.setHighlightability(display, display.hasActiveJourneys());
                            this._listViewC.setVisibility(display, display.hasActiveJourneys());
                            this._mapViewC.setVisibility(display, display.hasActiveJourneys());
                        } else {
                            this._listViewC.setHighlightability(display, true);
                            this._listViewC.setVisibility(display, true);
                            this._mapViewC.setVisibility(display, true);
                        }
                    } else {
                        // Only show Paths of Active Routes with current locations.
                        this._listViewC.setVisibility(display, false); // Don't show the bus name
                        this._mapViewC.setVisibility(display, display.isActiveJourney());
                    }
                } else {
                    this._listViewC.setVisibility(display, false);
                    this._mapViewC.setVisibility(display, false);
                }
                break;
            case state.SHOW_ROUTE:
                this._mapViewC.setTracking(display,false);
                if (state.selectedRouteCodes.indexOf(display.getCode()) != -1) {
                    if (display.isRouteDefinition()) {
                        if (state.onlyActive) {
                            this._listViewC.setHighlightability(display, false);
                            this._listViewC.setVisibility(display, display.hasActiveJourneys());
                            this._mapViewC.setVisibility(display, display.hasActiveJourneys());
                        } else {
                            this._listViewC.setHighlightability(display, false);
                            this._listViewC.setVisibility(display, true);
                            this._mapViewC.setVisibility(display, true);
                        }
                    } else {
                        // Only show Paths of Active Routes with current locations.
                        this._listViewC.setHighlightability(display, true);
                        this._listViewC.setVisibility(display, true);
                        this._mapViewC.setVisibility(display, true);
                    }
                } else {
                    this._listViewC.setVisibility(display, false);
                    this._mapViewC.setVisibility(display, false);
                }
                break;
            case state.SHOW_VEHICLE:
                if (display.isRouteDefinition()) {
                    this._listViewC.setVisibility(display, false);
                    this._mapViewC.setVisibility(display, false);
                }
                if (state.selectedRoutes.indexOf(display) != -1) {
                    // Assume it's route map is displayed.
                    this._listViewC.setHighlightability(display, true);
                    this._listViewC.setVisibility(display, true);
                    if (display.isJourney()) {
                        this._mapViewC.setVisibility(display, true);
                        this._mapViewC.setTracking(display,true);
                    }
                } else {
                    this._listViewC.setVisibility(display, false);
                    this._mapViewC.setVisibility(display, false);
                }
                break;
        }
        console.log("     setVisibility --> name: " + display.isNameVisible() + " path " + display.isPathVisible());
        return true;
    },

    /**
     * Method: private _updateActiveJourneys
     * This method is used to update the active journeys attribute
     * on routes, due to some active journeys being added or removed.
     */
    _updateActiveJourneys : function() {
        console.log("routesView" + "resetRoutesView");
        var routes = this._routes;

        for(var i = 0; i < routes.length; i++) {
            var journey = routes[i];
            if (journey.isRouteDefinition()) {
                journey.setHasActiveJourneys(false);
                this._listViewC.setHasActiveJourneys(journey, false);
                for(var ji = 0; ji < routes.length; ji++) {
                    var jd = routes[ji];
                    if (jd.isActiveJourney() && jd.getCode() == journey.getCode()) {
                        journey.setHasActiveJourneys(true);
                        this._listViewC.setHasActiveJourneys(journey, true);
                        break;
                    }
                }
            }
        }
    },

    onCreate : function() {
        this._locationC.onCreate();
    },

    onStart : function () {
        this._locationC.onStart();
    },

    onResume : function () {
        this._locationC.onResume();
    },

    onPause : function () {
        this._locationC.onPause();
    },

    onStop : function() {
        this._locationC.onStop();
    },

    onRestart : function() {
        this._locationC.onRestart();
    }

};
