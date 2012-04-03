/**
 * Class: RoutesMapController
 */
BusPass.RoutesMapController = OpenLayers.Class({

    /**
     * Attribute: scope
     * This attribute is the context for the onRouteSelect,
     * onRouteUnselect, onRouteHighlight, and onRouteUnhighlight
     * callbacks.
     */
    scope : null,

    /**
     * Attribute: onRouteSelected
     * This function is called when the mouse selects a route
     * on the map through a particular feature.
     */
    onRouteSelected : function (route, feature) {},

    /**
     * Attribute: onRouteUnselected
     * This function is called when the mouse unselects a route
     * on the map.
     */
    onRouteUnselected : function (route) {},

    /**
     * Attribute: onRouteHighlighted
     * This function is called when the mouse highlights a route
     * on the map through a particular feature.
     */
    onRouteHighlighted : function (route, feature) {},

    /**
     * Attribute: onRouteUnhighlighted
     * This function is called when the mouse unhighlights a route
     * on the mape.
     */
    onRouteUnhighlighted : function (route) {},

    /**
     * Attribute: blockScope
     * This is the scope for the callbacks onHighlightedRoutes,
     * onUnhighlightedRoutes, onSelectedRoutes, onUnselectedRoutes,
     * onClickout.
     */
    blockScope : null,

    /**
     * Attribute: onHighlightedRoutes
     * This method is called by the SelectAllFeature control for a
     * whole highlighted selection. It drives the highlightRouteAndTrigger
     * and subsequen onRouteHighlighted callback. Override this to work as a block.
     */
    onHighlightedRoutes : function (routes, features) {
        var i;
        for (i = 0; i < features.length; i++) {
            var feature = features[i];
            var route = feature.__route;
            console.log("map.onHightlightFeature: route " + route.getName());
            this.highlightRouteAndTrigger(route, feature);
        }
    },

    /**
     * Attribute: onHighlightedRoutes
     * This method is called by the SelectAllFeature control for a
     * whole unhighlighted selection. It drives the unhighlightRoute and
     * any subsequent onRouteUnhighlighted callbacks. Override this to work as a block.
     */
    onUnhighlightedRoutes : function (routes, features) {
        var i;
        for (i = 0; i < features.length; i++) {
            var feature = features[i];
            var route = feature.__route;
            console.log("map.onUnhightlightFeature: route " + route.getName());
            this.unhighlightRoute(route);
        }
    },

    /**
     * Attribute: onSelectedRoutes
     * This method is called by the SelectAllFeature control for a
     * whole selected selection. It drives the selectRouteAndTrigger and
     * and subsequent onRouteSelectedted callbacks. Override this to work as a block.
     */
    onSelectedRoutes : function (routes, features) {
        var i;
        for (i = 0; i < features.length; i++) {
            var feature = features[i];
            var route = feature.__route;
            console.log("map.onSelectedFeature: route " + route.getName());
            this.selectRouteAndTrigger(route, feature);
        }
    },

    /**
     * Attribute: onUnselectedRoutes
     * This method is called by the SelectAllFeature control for a
     * whole selected selection. It drives the unhighlightRoute and
     * any subsequent onRouteUnhighlighted callbacks. Override this to work as a block.
     */
    onUnselectedRoutes : function (routes, features) {
        var i;
        for (i = 0; i < features.length; i++) {
            var feature = features[i];
            var route = feature.__route;
            console.log("map.onUnselectedFeature: route " + route.getName());
            this.unselectRoute(route);
        }
    },

    /**
     * APIProperty: onClickout
     * This is called if the selection and highlights clicked out and
     * unselected everything. All callbacks should have been called, so
     * this leaves an opportunity to clean up.
     */
    onClickout : function () { },

    /**
     * Attribute: map
     * The map used by this controller after setup of the mapView.
     */
    map : null,

    /**
     * Attribute: layers
     * The layers used by this controller after setup of the mapView.
     */
    layers : [],

    /**
     * Attribute: styleMap
     * This is the {<OpenLayers.StyleMap>} used to display routes.
     * Unless set in attribute controlOptions, it should have mappings
     * for "default", "select", and "highlight".
     */
    styleMap : new OpenLayers.StyleMap({
        default : new OpenLayers.Style({
            strokeColor: "blue",
            strokeWidth: 5,
            strokeOpacity: 0.5,
            graphicZIndex: 100,
            cursor: "pointer"
        }),

        select : new OpenLayers.Style({
            strokeColor: "lightgreen",
            strokeWidth: 5,
            strokeOpacity: 1.0,
            graphicZIndex: 101,
            cursor: "pointer"
        }),

        highlight : new OpenLayers.Style({
            strokeColor: "#f34444",
            strokeWidth: 5,
            strokeOpacity: 1.0,
            graphicZIndex: 999,
            cursor: "pointer"
        })
    }),

    // NOT USED NOW.
    rules : {
        strokeWidth : new OpenLayers.Rule({
            context : function (feature) { return feature; },
                filter : new OpenLayers.Filter({
                    evaluate: function (feature) {
                        //console.log("strokeWidth: zoom=" + ctrl.map.zoom);
                        return ctrl.map.zoom < 13;
                    }
                }),
                symbolizer: {
                    strokeWidth : 3
                }
        }),
        onTracking : new OpenLayers.Rule({
            context : function (feature) { return feature; },
                filter : new OpenLayers.Filter({
                    evaluate: function (feature) {
                        console.log("isTracking: " + ctrl._routeVectors.selectedFeatures.length + " - " + feature.__route.isTracking());
                        return feature.__route.isPathVisible() &&
                        feature.__route.isTracking();
                    }
                }),
                symbolizer: {
                    strokeColor: "green",
                strokeOpacity : 0.8
                }
        }),
        pathVisible : new OpenLayers.Rule({
            context : function (feature) { return feature; },
                filter : new OpenLayers.Filter({
                    evaluate: function (feature) {
                        console.log("isPathVisible: " + ctrl._routeVectors.selectedFeatures.length + " - " + feature.__route.isPathVisible());
                        return !feature.__route.isPathVisible();
                    }
                }),
                symbolizer: {
                    display: "none"
                }
        }),
        showOneOrAllRule : new OpenLayers.Rule({
            context : function (feature) { return feature; },
                filter : new OpenLayers.Filter({
                    evaluate: function (feature) {
                        console.log("select: " + ctrl._routeVectors.selectedFeatures.length + " - " + feature.__route.isSelected());
                        return ctrl._routeVectors.selectedFeatures.length > 0 &&
                        !feature.__route.isSelected();
                    }
                }),
                symbolizer: {
                    display: "none"
                }
        })
    },

    /**
     * Attribute: controlOptions
     * This attribute contains options that will be passed to the {<BusPass.SelectAllFeature>}.
     * Use this to change the rederIntents, such as "selectStyle", "hightlightStyle".
     */
    controlOptions : {},

    /**
     * Constructor: BusPass.RoutesMapController
     */
    initialize : function (options) {
        console.log("RoutesMapController: initialize" + $.toJSON(options));
        OpenLayers.Util.extend(this, options);
        this._routes = [];
        this._selectedRoutes = [];
        this._highlightedRoutes = [];
        if (this.scope === null) {
            this.scope = this;
        }
        if (this.blockScope === null) {
            this.blockScope = this;
        }
    },

    /**
     * Method: addRoute
     * This method adds a route to the MapView.
     */
    addRoute : function (route) {
        this._routes.push(route);
        var ctrl = this;
        var protocol = new OpenLayers.Protocol.HTTP({
            url: route.getGeoJSONUrl(),
            format: new OpenLayers.Format.GeoJSON({
                ignoreExtraDims: true,
                internalProjection: new OpenLayers.Projection("EPSG:900913"),
                externalProjection: new OpenLayers.Projection("EPSG:4326")
            }),
            callback : function (response) {
                // if response.features is null, there was an error. Maybe remove the route?
                if (response.features != null) {
                    console.log("HTTP Response: has " + response.features);
                    // The server only returns one Feature.
                    var feature = ctrl._setMapFeature(route, response.features[0]);
                    if (route.isJourney()) {
                        ctrl._journeyVectors.addFeatures(feature);
                    } else { // RouteDefinition for now
                        ctrl._routeVectors.addFeatures(feature);
                    }
                    if (route.__highlighted) {
                        ctrl._selectCtrl.highlight(feature);
                    }
                    if (route.isSelected()) {
                        ctrl._selectCtrl.select(feature);
                    }
                } else {
                    console.log("addRoute: Cannot download Route definition features: " + response.priv.status + " " + response.priv.statusText);
                }
            }
        });
        protocol.read();
    },

    /**
     * Method: removeRoute
     * This method removes a route from the MapView
     */
    removeRoute : function (route) {
        this._selectedRoutes = OpenLayers.Util.removeItem(this._selectedRoutes, route);
        this._routes = OpenLayers.Util.removeItem(this._routes, route);
        // Does this call unselect call backs?
        var layer = route.__mapFeature.layer;
        layer.removeFeatures(route.__mapFeature);
        this._removeMapFeatures(route);
    },

    /**
     * Method: clearRoutes
     * This method removes all routes from the MapView
     */
    clearRoutes : function () {
        // We do this from the back of the list because
        // removeRoute is destructive to this._routes.
        var i;
        for (i = this._routes.length - 1; i >= 0; i--) {
            this.removeRoute(this._routes[i]);
        }
    },

    /**
     * Method: selectRoute
     * This method selects the route in. It does not trigger the callback.
     */
    selectRoute : function (route) {
        if (!route.__selected) {
            this._selectedRoutes.push(route);
            route.__selected = true;
            console.log("map.selectRoute: selecting " + route.getName() + ":" + route.getId());
            this._selectCtrl.select(route.__mapFeature);
        }
    },

    /**
     * Method: selectRoute
     * This method selects the route in. This calls the onRouteSelected callback.
     */
    selectRouteAndTrigger : function (route, feature) {
        if (!route.__selected) {
            this._selectedRoutes.push(route);
            route.__selected = true;
            console.log("map.selectRoute: selecting " + route.getName() + ":" + route.getId());
            // Route.__mapFeature has already been selected.
            this.onRouteSelected.call(this.scope, route, feature);
            route.__selectedTriggered = true;
        }
    },

    /**
     * Method: unselectRoute
     * This method only unselects the route in this View.
     * It triggers a callback only if it triggered one on selection.
     */
    unselectRoute : function (route) {
        if (route.__selected) {
            this._selectedRoutes = OpenLayers.Util.removeItem(this._selectedRoutes, route);
            route.setSelected(false);
            console.log("map.unselectRouteNoTrigger: unselecting " + route.getName() + ":" + route.getId());
            this._selectCtrl.unselect(route.__mapFeature);
            route.__selected = false;
            if (route.__selectedTriggered) {
                this.onRouteUnselected.call(this.scope, route);
                route.__selectedTriggered = false;
            }
        }
    },

    /**
     * Method: unselectAllRoutesr
     * This method unselects the selected routes in this View.
     */
    unselectAllRoutes : function () {
        console.log("map.unselectAllRoutes: unselecting");
        var i;
        for (i = this._selectedRoutes.length - 1; i >= 0; --i) {
            var route = this._selectedRoutes[i];
            this.unselectRoute(route);
        }
    },

    /**
     * Method: highlightRoute
     * This method only highlights the routes in this View.
     */
    highlightRoute : function (route) {
        console.log("map.highlightRouteNoTrigger " + route.getName() + " - " + route.isSelected());
        this._highlightedRoutes.push(route);
        route.__highlighted = true;
        if (route.__mapFeature) {
            this._selectCtrl.highlight(route.__mapFeature);
        }
    },

    /**
     * Method: highlightRouteAndTrigger
     * This method only highlights the routes in this View.
     */
    highlightRouteAndTrigger : function (route, feature) {
        console.log("map.highlightRouteNoTrigger " + route.getName() + " - " + route.isSelected());
        this._highlightedRoutes.push(route);
        route.__highlighted = true;
        // Route.__mapFeature has already been highlighted.
        route.__highlightedTriggered = true;
        this.onRouteHighlighted.call(this.scope, route, feature);
    },

    /**
     * Method: unhighlightRouteNoTrigger
     * This method only unhighlights the routes in this View.
     * It triggers a callback only if it triggered one on highlight.
     */
    unhighlightRoute : function (route) {
        console.log("map.unhighlightRouteNoTrigger " + route.getName() + " - " + route.isSelected());
        OpenLayers.Util.removeItem(this._highlightedRoutes, route);
        route.__highlighted = false;
        if (route.__mapFeature) {
            this._selectCtrl.unhighlight(route.__mapFeature);
        }
        if (route.__highlightedTriggered) {
            route.__highlightedTriggered = false;
            this.onRouteUnhighlighted.call(this.scope, route);
        }
    },

    /**
     * Method: unhighlightAllRoutesNoTrigger
     * This method only unselects the routes in this View.
     * It doesn't trigger callbacks.
     */
    unhighlightAllRoutes : function () {
        var i;
        for (i = this._highlightedRoutes.length - 1; i >= 0; --i) {
            var route = this._highlightedRoutes[i];
            this._highlightedRoutes.splice(i, 1);
            this.unhighlightRoute(route);
        }
    },

    mapView : function (jquery) {
        this.map = new OpenLayers.Map($(jquery)[0].id);
        this.map.projection = "EPSG:900913"; // Need by OSM
        this.map.displayProjection = new OpenLayers.Projection("EPSG:4326");
        var mapnik = new OpenLayers.Layer.OSM("OpenStreetMap (Mapnik)");
        this.map.addLayers([mapnik]);
        this.map.addControl(new OpenLayers.Control.LayerSwitcher());
        this.map.addControl(new OpenLayers.Control.MousePosition());
        this.map.setCenter(new OpenLayers.LonLat(-76.146669, 43.050952).transform(
            new OpenLayers.Projection("EPSG:4326"), // transform from WGS 1984
            new OpenLayers.Projection("EPSG:900913") // to Spherical Mercator Projection
            ), 13 // Zoom level
            );

        this._routeVectors = this._constructRoutesLayer();
        this._journeyVectors = this._constructJourneysLayer();
        this.layers = [this._routeVectors, this._journeyVectors];
        this.map.addLayers(this.layers);
        this._setupSelectControls(this.layers, this.controlOptions);
        this.map.resetLayersZIndex();
    },

    setVisibility : function (route, state) {
        // We set an attribute on the route so that the drawing intent
        // filter Rule will pick it up.
        route.setPathVisible(state);
    },


    setTracking : function (route, state) {
        // We set an attribute on the route so that the drawing intent
        // filter Rule will pick it up.
        route.setTracking(state);
    },

    moveAndCenterTo : function (route) {
        if (route.__mapFeature != null) {
            var bounds = route.__mapFeature.geometry.getBounds();
            bounds = bounds.scale(1.2); // Scale out a bit.
            //var centroid = route.__mapFeatures[0].geometry.getCentroid();
            this.map.zoomToExtent(bounds, true);
        }
    },

    /**
     * Method: redraw
     * This method triggers a redraw of the vector layer. It returns
     * a boolean if the layer was redrawn, which is an OpenLayers return
     * for Layer.redraw().
     */
    redraw : function () {
        this._routeVectors.redraw();
    },

    /**
     * Method: setMapFeatures
     * This function sets the features on the Route and associates
     * the route with each feature.
     *
     * Parameters
     * route   - <BusPass.Route> -
     * features - [<OpenLayers.Feature.Vector>]
     *
     * Returns - <OpenLayers.Feature.Vector>
     */
    _setMapFeature : function (route, feature) {
        route.__mapFeature = feature;
        feature.__route = route;
        return route.__mapFeature;
    },

    _removeMapFeatures : function (route) {
        route.__mapFeature.__route = null;
        delete route.__mapFeature.__route;
        route.__mapFeature = null;
        delete route.__mapFeature;
        delete route.__highlighted;
        delete route.__highlightedTriggered;
        delete route.__selected;
        delete route.__selectedTriggered;
    },

    _constructRoutesLayer : function () {
        var ctrl = this;

        var layer = new OpenLayers.Layer.Vector("Routes", {
            // We want to bring hightlights up to the top. We need zIndexing
            // which works by a graphicZIndex style option.
            rendererOptions: {
                zIndexing : true
            },
            styleMap : this.styleMap
        });
        return layer;
    },

    _constructJourneysLayer : function () {
        var ctrl = this;

        var layer = new OpenLayers.Layer.Vector("Journeys", {
            // We want to bring hightlights up to the top. We need zIndexing
            // which works by a graphicZIndex style option.
            rendererOptions: {
                zIndexing : true
            },
            styleMap : this.styleMap
        });
        return layer;
    },

    _setupSelectControls : function (layers, controlOptions) {
        var ctrl = this;

        function onHighlightedFeatures(features) {
            var routes = $.map(features, function (f) { return f.__route; });
            ctrl.onHighlightedRoutes.call(ctrl.blockScope, routes, features);
        }

        function onUnhighlightedFeatures(features) {
            var routes = $.map(features, function (f) { return f.__route; });
            ctrl.onUnhighlightedRoutes.call(ctrl.blockScope, routes, features);
        }

        function onSelectedFeatures(features) {
            var routes = $.map(features, function (f) { return f.__route; });
            ctrl.onSelectedRoutes.call(ctrl.blockScope, routes, features);
        }

        function onUnselectedFeatures(features) {
            var routes = $.map(features, function (f) { return f.__route; });
            ctrl.onUnselectedRoutes.call(ctrl.blockScope, routes, features);
        }

        function onClickout() {
            // This will have hit the onUnselectedRoute for every one selected?
            // Which will have cleared its select on the routesView.
            ctrl.onClickout.call(ctrl.blockScope);
            ctrl.redraw();
        }

        if (ctrl._selectCtrl != null) {
            ctrl._selectCtrl.deactivate();
            ctrl.map.removeControl(ctrl._selectCtrl);
            ctrl._selectCtrl.destroy();
        }

        OpenLayers.Util.applyDefaults(controlOptions, {
            scope: ctrl,
            multiple: false,
            onSelected: onSelectedFeatures,
            onUnselected: onUnselectedFeatures,
            onHighlighted: onHighlightedFeatures,
            onUnhighlighted: onUnhighlightedFeatures,
            onClickout : onClickout,
            clickout: true
        });

        ctrl._selectCtrl = new BusPass.SelectAllFeature(layers, controlOptions);
        ctrl.map.addControl(ctrl._selectCtrl);
        ctrl._selectCtrl.activate();
    },

    CLASS_NAME: "BusPass.RoutesMapController"
});
