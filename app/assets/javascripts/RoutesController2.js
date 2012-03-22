BusPass.ActivePlanController = function(options) {
    this._routes = [];
    $.extend(this,options);
    this._stateStack = [];
    this._stateStack.push(new BusPass.ActivePlanController.VisualState());

    this._mapViewC = new BusPass.MapViewController({
        scope : this,
        onRouteSelected : this._onMapRouteSelect,
        onRouteUnselected : this._onMapRouteUnselect,
        onRouteHighlighted : this._onMapRouteHighlight,
        onRouteUnhighlighted : this._onMapRouteunhighlight,
    });
    var rctrl = this;
    this._listViewC = new BusPass.ListViewController({
        scope : this,
        // This will only happen if the Map fires a selection.
        onRouteSelected : this._onListRouteSelect,
        onRouteUnselected : this._onListRouteUnselect,
        onRouteHighlighted : this._onListRouteHighlight,
        onRouteUnhighlighted : this._onListRouteUnhighlight,
        onRouteClicked : 
            function (ctrl, route) {
                rctrl._onListRouteClicked(ctrl,route);
            },
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
     * This attribute is the context for the onRouteSelect,
     * onRouteUnselect, onRouteHighlight, and onRouteUnhighlight
     * callbacks.
     */
    scope : null,

    onRouteSelected : function () {},

    onRouteUnselected : function () {},

    onRouteHighlighted : function () {},

    onRouteUnhighlighted : function () {},

    mapView : function (jq) {
        this._mapViewC.mapView(jq);
    },

    listView : function (jq) {
        this._listViewC.listView(jq);
    },

    addRoute : function(route) {
        this._routes.push(route);
        this._listViewC.addRoute(route);
        this._mapViewC.addRoute(route);
        
        this._setVisibility(this._stateStack[0], route);
        this._mapViewC.redraw();
        this._listViewC.redraw();
    },

    removeRoute : function(route) {
        var rs = [];
        for(r in this._routes) {
        if (this._routes[r] != route) {
            rs.push(this._routes[r]);
        };
        }
        this._listViewC.removeRoute(route);
        this._mapViewC.removeRoute(route);
    },
    
    _onMapRouteSelect : function(route) {
        this._listViewC.selectRouteNoTrigger(route);
    },

    _onListRouteSelect : function(route) {
        this._mapViewC.selectRouteNoTrigger(route);
        
        this._routeSelected(route);
        
        this._listViewC.redraw();
        this._mapViewC.redraw();
    },
    
    _onListRouteClicked : function(ctrl, route) {
        this._mapViewC.selectRouteNoTrigger(route);
        
        this._routeSelected(route);
        
        this._listViewC.redraw();
        this._mapViewC.redraw();
    },
        

    _onMapRouteUnselect : function(route) {
        this._listViewC.unselectRouteNoTrigger(route);
    },

    _onListRouteUnselect : function(route) {
        this._mapViewC.unselectRouteNoTrigger(route);
    },

    _onMapRouteHighlight : function(route) {
        this._listViewC.highlightRouteNoTrigger(route);
    },

    _onListRouteHighlight : function(route) {
        this._mapViewC.highlightRouteNoTrigger(route);
    },

    _onMapRouteunhighlight : function(route) {
        this._listViewC.unhighlightRouteNoTrigger(route);
    },

    _onListRouteUnhighlight : function(route) {
        this._mapViewC.unhighlightRouteNoTrigger(route);
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
        console.log("setVisibiity: nearby" + state.nearBy + " active: " + state.onlyActive + " name: " + display.getDisplayName());
        if (state.nearBy && !display.isNearRoute(this.getCurrentLocation(), this.nearbyDistance())) {
            this._listViewC.setVisibiity(false);
            this._mapViewC.setVisibiity(false);
            return true;
        }
        switch (state.state){
            case BusPass.ActivePlanController.VisualState.SHOW_MAP:
                if(state.selectedRoutes == null ||
                    state.selectedRoutes.indexOf(display) != -1 ||
                    state.selectedRouteCodes.indexOf(display.getCode()) != -1) {
                    // We are in general mode, so we only show the Names of Route Definitions,
                    // and Active journeys, but we don't show the Active Journey names.
                    if (display.isRouteDefinition()) {
                        if (state.onlyActive) {
                            this._listViewC.setVisibiity(display.isHasActiveJourneys());
                            this._mapViewC.setVisibiity(display.isHasActiveJourneys());
                        } else {
                            this._listViewC.setVisibiity(true);
                            this._mapViewC.setVisibiity(true);
                        }
                    } else if (display.isActiveJourney()) {
                        // Only show Paths of Active Routes with current locations.
                        this._listViewC.setVisibiity(false); // Don't show the bus name
                        this._mapViewC.setVisibiity(true);
                    }
                    } else {
                        this._listViewC.setVisibiity(false);
                        this._mapViewC.setVisibiity(false);
                    }
                    break;
            case BusPass.ActivePlanController.VisualState.SHOW_ROUTE:
                if (state.selectedRouteCodes.indexOf(display.getCode()) != -1) {
                    if (display.isRouteDefinition()) {
                        if (state.onlyActive) {
                            this._listViewC.setVisibiity(display.isHasActiveJourneys());
                            this._mapViewC.setVisibiity(display.isHasActiveJourneys());
                        } else {
                            this._listViewC.setVisibiity(true);
                            this._mapViewC.setVisibiity(true);
                        }
                    } else if (display.isActiveJourney()) {
                        // Only show Paths of Active Routes with current locations.
                        this._listViewC.setVisibiity(true); // Don't show the bus name
                        this._mapViewC.setVisibiity(true);
                    }
                } else {
                    this._listViewC.setVisibiity(false);
                    this._mapViewC.setPathVisible(false);
                }
                break;
            case BusPass.ActivePlanController.VisualState.SHOW_VEHICLE:
                if (!display.isActiveJourney()) {
                    this._listViewC.setVisibiity(false);
                    this._mapViewC.setVisibiity(false);
                }
                if (state.selectedRoutes.indexOf(display) != -1) {
                    // Assume it's route map is displayed.
                    this._listViewC.setVisibiity(true);
                    this._mapViewC.setVisibiity(true);
                }
                break;
        }
        console.log("setVisibiity: name: " + display.getDisplayName() + "name " + display.isNameVisible() + " path " + display.isPathVisible());
        return true;
    },

    _resetRoutesView : function(routes) {
        console.log("routesView" + "resetRoutesView");
        var routesView = this._listViewC;
        var passengerMapView = this._mapViewC;
        var routes = this._routes;

        //routesView.clearRouteList();
        //for(JourneyDisplay journey : routes) {
        for(var i = 0; i < routes.length; i++) { var journey = routes[i];
            if(journey.isNameVisible()) {
                //MyClickListener lis = new MyClickListener(journey);
                var lis = null // TODO: need to add MyClickListener
                //routesView.addRoute(journey, lis, lis);
                if (journey == passengerMapView.getHighlightJourneyDisplay()) {
                    journey.setNameHighlighted(true);
                    // TODO: Get the highlight unset
                }
                if (journey.getRoute().isRouteDefinition()) {
                    // Check to see if there are any active journeys for it
                    journey.setHasActiveJourneys(false);
                    //for (JourneyDisplay jd : routes) {
                    for(var ji = 0; ji < routes.length; ji++) { var jd = routes[ji];
                        if (jd.getRoute().isActiveJourney() &&
                            //jd.getRoute().getCode().equals(journey.getRoute().getCode())) {
                            jd.getRoute().getCode() == journey.getRoute().getCode()) {
                            journey.setHasActiveJourneys(true);
                        break;
                            }
                    }
                }
            }
        }
        //routesView.invalidate();
    },
    _routeSelected : function(route) {
        var ctrl = this;
        console.log("onLongCLick for " + route.getName() + " " +route.getId() + " State " + ctrl._stateStack[0].state);
            var newState = new BusPass.ActivePlanController.VisualState(); // here because of silly switch statement scoping anomaly
            var currentState = ctrl._stateStack[0];
            switch(currentState.state) {

                case currentState.SHOW_MAP:
                    //assert journeyDisplay.isRouteDefinition();

                    newState.selectedRoutes = []; //new ArrayList<JourneyDisplay>();
                    //for(JourneyDisplay display : journeyBasketController.getJourneyDisplays()) {
                    var displays = ctrl._routes;
                    for(var i = 0; i < displays.length; i++) { var display = displays[i];
                        if (display.getCode() == route.getCode()) {
                            newState.selectedRoutes.push(display);
                        }
                    }
                    newState.state = newState.SHOW_ROUTE;
                    newState.selectedRouteCode = route.getCode();
                    newState.selectedRouteCodes.push(newState.selectedRouteCode);
                    // Push on front
                    ctrl._stateStack.splice(0,0,newState);
                    break;

                case currentState.SHOW_ROUTE:
                    if (route.isRouteDefinition()) {
                        // we may have gotten some new active journeys in the basket.
                        //for(JourneyDisplay display : journeyBasketController.getJourneyDisplays()) {
                        var displays = ctrl._routes;
                        for(var i = 0; i < displays.length; i++) { var display = displays[i];
                            if (display.getCode() == route.getCode()) {
                                if (display.isActiveJourney()) {
                                    currentState.selectedRoutes.push(display);
                                }
                            }
                        }
                    } else {
                        newState.selectedRoutes = []; // new ArrayList<JourneyDisplay>();
                        // find the route definition so we can display its name in the Routes View.
                        //for(JourneyDisplay display : journeyBasketController.getJourneyDisplays()) {
                        var displays = ctrl._routes;
                        for(var i = 0; i < displays.length; i++) { var display = displays[i];
                            if (display.getCode() == route.getCode()) {
                                if (display.isRouteDefinition()) {
                                    newState.selectedRoutes.push(display);
                                }
                            }
                        }
                        newState.selectedRoutes.push(route);
                        newState.state = newState.SHOW_VEHICLE;
                        // push on front
                        ctrl._stateStack.splice(0,0,newState);
//                         passengerMapView.setTrackingJourneyDisplay(route);
//                         passengerMapView.animateToRouteDisplayLocation(route);
//                         passengerMapView.invalidate();
                    }
                    break;

                case currentState.SHOW_VEHICLE:
                    if (route.isRouteDefinition()) {
                        // we may have gotten some new active journeys in the basket.
                        newState.selectedRoutes = []; // new ArrayList<JourneyDisplay>();
                        //for(JourneyDisplay display : journeyBasketController.getJourneyDisplays()) {
                        var displays = ctrl._routes;
                        for(var i in displays) { var display = displays[i];
                            if (display.getCode() == route.getCode()) {
                                if (display.isActiveJourney()) {
                                    newState.selectedRoutes.push(display);
                                }
                            }
                        }
                        newState.selectedRoutes.push(route);
                        newState.state = newState.SHOW_ROUTE;
                        newState.selectedRouteCode = route.getCode();
                        newState.selectedRouteCodes.add(newState.selectedRouteCode);
                        // push on front
                        ctrl._stateStack.splice(0,0,newState);
//                         passengerMapView.getController().animateTo(journeyDisplay.getRoute().getZoomCenter());
//                         passengerMapView.getController().zoomToSpan(journeyDisplay.getRoute().getLatitudeSpanE6(),
//                                                                     journeyDisplay.getRoute().getLongitudeSpanE6());
//                         passengerMapView.unsetTracking();
//                         passengerMapView.unsetHighlight();
                    } else {
//                         passengerMapView.getController().animateTo(journeyDisplay.getRoute().getZoomCenter());
//                         passengerMapView.getController().zoomToSpan(journeyDisplay.getRoute().getLatitudeSpanE6(),
//                                                                     journeyDisplay.getRoute().getLongitudeSpanE6());
                    }
//                     passengerMapView.invalidate();
                    break;
            }
            console.log("MySelectListener: " + "Reseting Routes View ****************");
            ctrl._setVisibility(ctrl._stateStack[0], route);
            //ctrl._resetRoutesView();
            //passengerMapView.invalidate();
            return true;
    },
      
};


BusPass.MySelectListener = function(jd,controller) {
        this.journeyDisplay = jd;
        this.ctrl = controller;
};


BusPass.MySelectListener.prototype = {

    // TODO: Some kind of click.
        routeSelected : function(v) {
            console.log("onLongCLick for " + this.journeyDisplay.getRoute().getId());
            var newState = new BusPass.ActivePlanController.VisualState(); // here because of silly switch statement scoping anomaly
            var currentState = ctrl._stateStack[0];
            switch(currentState.state) {

                case currentState.SHOW_MAP:
                    //assert journeyDisplay.getRoute().isRouteDefinition();

                    newState.selectedRoutes = []; //new ArrayList<JourneyDisplay>();
                    //for(JourneyDisplay display : journeyBasketController.getJourneyDisplays()) {
                    var displays = ctrl._routes;
                    for(var i = 0; i < displays.length; i++) { var display = displays[i];
                        if (display.getRoute().getCode() == this.journeyDisplay.getRoute().getCode()) {
                            newState.selectedRoutes.push(display);
                        }
                    }
                    newState.state = newState.SHOW_ROUTE;
                    newState.selectedRouteCode = this.journeyDisplay.getRoute().getCode();
                    newState.selectedRouteCodes.push(newState.selectedRouteCode);
                    ctrl._stateStack.splice(0,0,newState);
//                     passengerMapView.getController().animateTo(journeyDisplay.getRoute().getZoomCenter());
//                     passengerMapView.getController().zoomToSpan(journeyDisplay.getRoute().getLatitudeSpanE6(),
//                                                                 journeyDisplay.getRoute().getLongitudeSpanE6());
//                     passengerMapView.unsetTracking();
//                     passengerMapView.unsetHighlight();
                    break;

                case currentState.SHOW_ROUTE:
                    if (this.journeyDisplay.getRoute().isRouteDefinition()) {
                        // we may have gotten some new active journeys in the basket.
                        //for(JourneyDisplay display : journeyBasketController.getJourneyDisplays()) {
                        var displays = ctrl._routes;
                        for(var i = 0; i < displays.length; i++) { var display = displays[i];
                            if (display.getRoute().getCode() == this.journeyDisplay.getRoute().getCode()) {
                                if (display.getRoute().isActiveJourney()) {
                                    currentState.selectedRoutes.push(display);
                                }
                            }
                        }
//                         passengerMapView.getController().animateTo(journeyDisplay.getRoute().getZoomCenter());
//                         passengerMapView.getController().zoomToSpan(journeyDisplay.getRoute().getLatitudeSpanE6(),
//                                                                     journeyDisplay.getRoute().getLongitudeSpanE6());
//                         passengerMapView.unsetTracking();
//                         passengerMapView.unsetHighlight();
                    } else {
                        //VisualState newState = new VisualState();
                        newState.selectedRoutes = []; // new ArrayList<JourneyDisplay>();
                        // find the route definition so we can display its name in the Routes View.
                        //for(JourneyDisplay display : journeyBasketController.getJourneyDisplays()) {
                        var displays = ctrl.journeyBasketController.getJourneyDisplays();
                        for(var i = 0; i < displays.length; i++) { var display = displays[i];
                            if (display.getRoute().getCode() == this.journeyDisplay.getRoute().getCode()) {
                                if (display.getRoute().isRouteDefinition()) {
                                    newState.selectedRoutes.push(display);
                                }
                            }
                        }
                        newState.selectedRoutes.push(journeyDisplay);
                        newState.state = newState.SHOW_VEHICLE;
                        // push on front
                        ctrl._stateStack.splice(0,0,newState);
//                         passengerMapView.setTrackingJourneyDisplay(journeyDisplay);
//                         passengerMapView.animateToRouteDisplayLocation(journeyDisplay);
//                         passengerMapView.invalidate();
                    }
                    break;

                case currentState.SHOW_VEHICLE:
                    if (journeyDisplay.getRoute().isRouteDefinition()) {
                        // we may have gotten some new active journeys in the basket.
                        newState.selectedRoutes = []; // new ArrayList<JourneyDisplay>();
                        //for(JourneyDisplay display : journeyBasketController.getJourneyDisplays()) {
                        var displays = ctrl.journeyBasketController.getJourneyDisplays();
                        for(var i in displays) { var display = displays[i];
                            if (display.getRoute().getCode() == journeyDisplay.getRoute().getCode()) {
                                if (display.getRoute().isActiveJourney()) {
                                    newState.selectedRoutes.push(display);
                                }
                            }
                        }
                        newState.selectedRoutes.push(this.journeyDisplay);
                        newState.state = newState.SHOW_ROUTE;
                        newState.selectedRouteCode = this.journeyDisplay.getRoute().getCode();
                        newState.selectedRouteCodes.add(newState.selectedRouteCode);
                        // push on front
                        ctrl._stateStack.splice(0,0,newState);
//                         passengerMapView.getController().animateTo(journeyDisplay.getRoute().getZoomCenter());
//                         passengerMapView.getController().zoomToSpan(journeyDisplay.getRoute().getLatitudeSpanE6(),
//                                                                     journeyDisplay.getRoute().getLongitudeSpanE6());
//                         passengerMapView.unsetTracking();
//                         passengerMapView.unsetHighlight();
                    } else {
//                         passengerMapView.getController().animateTo(journeyDisplay.getRoute().getZoomCenter());
//                         passengerMapView.getController().zoomToSpan(journeyDisplay.getRoute().getLatitudeSpanE6(),
//                                                                     journeyDisplay.getRoute().getLongitudeSpanE6());
                    }
//                     passengerMapView.invalidate();
                    break;
            }
            console.log("MySelectListener: " + "Reseting Routes View ****************");
            ctrl._setVisibility(ctrl._stateStack[0]);
            ctrl._resetRoutesView();
            //passengerMapView.invalidate();
            return true;
        }

};
