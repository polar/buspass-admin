

BusPass.LocationMapViewController = OpenLayers.Class(BusPass.RoutesMapController, {
    /**
     * Attribute:
     * This attribute contains the 'default' and 'temporary' styles
     * for drawing the icons on the map.
     */
    locationStyleMap : new OpenLayers.StyleMap({
        'default': new OpenLayers.Style( {
            graphicOpacity : 1,
            pointRadius : 12,
            graphicZIndex: 1000,
            externalGraphic : "/assets/busarrow.png",
        }),
        'highlight': new OpenLayers.Style({
            graphicOpacity : 0.9,
            pointRadius : 12,
            graphicZIndex: 1000,
            externalGraphic : "/assets/busarrow_highlight.png",
        }),
        'select': new OpenLayers.Style({
            graphicOpacity : 0.7,
            pointRadius : 12,
            graphicZIndex: 1000,
            externalGraphic : "/assets/busarrow.png",
        }),
    }),


    /**
     * Constructor: BusPass.LocationMapViewController
     */
    initialize : function (options) {
        console.log("LocationMapViewController: initialize" + $.toJSON(options));

        BusPass.RoutesMapController.prototype.initialize.apply(this, [options]);
    },

    selectRoute : function (route) {
        BusPass.RoutesMapController.prototype.selectRoute.apply(this,[route]);
        if (route.__marker) {
            this._selectCtrl.multiple = true;
            this._selectCtrl.select(route.__marker);
            this._selectCtrl.multiple = false;
        }
    },

    selectRouteAndTrigger : function (route, feature) {
        BusPass.RoutesMapController.prototype.selectRouteAndTrigger.apply(this, [route, feature]);
        if (route.__marker) {
            if (feature == route.__marker) {
            // as opposed to its actual route line
            // So, for an experiment here, if we want to select a journey
            // we make sure we set enough data here to only display
            // the one route selected by its marker.
            }
            this._selectCtrl.multiple = true;
            this._selectCtrl.select(route.__marker);
            this._selectCtrl.multiple = false;
            // We don't trigger a selectEvent for the marker, the route has already been
            // selected.
        }
    },

    unselectRoute : function (route) {
        if (route.__marker) {
            this._selectCtrl.unselect(route.__marker);
        }
        BusPass.RoutesMapController.prototype.unselectRoute.apply(this, [route]);
    },

    removeRoute : function (route) {
        console.log("LocationMapViewController.removeRoute: will it call the correct _removeMapFeatures? " + route.name);
        BusPass.RoutesMapController.prototype.removeRoute.apply(this, [route]);
    },

    highlightRoute : function (route) {
        BusPass.RoutesMapController.prototype.highlightRoute.apply(this, [route]);
        if (route.__marker) {
            this._selectCtrl.highlight(route.__marker);
        }
    },

    highlightRouteAndTrigger : function (route, feature) {
        console.log("LocationMapViewController.highlightRouteAndTrigger:" + route.getDisplayName());
        BusPass.RoutesMapController.prototype.highlightRouteAndTrigger.apply(this, [route, feature]);
        if (route.__marker) {
            this._selectCtrl.highlight(route.__marker);
        }
    },

    unhighlightRoute : function (route) {
        BusPass.RoutesMapController.prototype.unhighlightRoute.apply(this, [route]);
        if (route.__marker) {
            this._selectCtrl.unhighlight(route.__marker);
        }
    },

    // Override
    mapView : function (jquery) {
        BusPass.RoutesMapController.prototype.mapView.apply(this,[jquery]);

        // These are attributes we put on the Location Feature.
        OpenLayers.Util.extend(this.locationStyleMap.styles['default'].defaultStyle, {
            rotation : '${rotation}',
            graphicTitle : '${title}'
        });
        // We have to reset the style with setDefaultStyle so it
        // will pick up the attribute replacement symbols.
        this.locationStyleMap.styles['default'].setDefaultStyle(
            this.locationStyleMap.styles['default'].defaultStyle);

        this._locationMarkers = this._constructLocationLayer();
        this.map.addLayers([this._locationMarkers]);
        console.log("added vector and locations layer");
        // The activation of these controls brings them to the top
        // and they stay there (to catch MouseEvents).
        // We need to move them back.
        //this._highlightCtrl.handlers.feature.moveLayerBack();
       // this._selectCtrl.handlers.feature.moveLayerBack();
        // This replaces the first set of controls.
        // For some reason if we don't do this, the location markers
        // end up on the bottom.
        var layers = [this._routeVectors, this._journeyVectors, this._locationMarkers];
        this._setupSelectControls(layers, this.controlOptions);

        var ctrl = this;

        function onSelected(features) {
            var i, len;
            for (i = 0, len = features.length; i < len; i++) {
                var feature = features[i];
                var route = feature.__route;
                var marker = route.__marker;
                // Marker is selected.
                BusPass.RoutesMapController.prototype.selectRouteAndTrigger.apply(this, [route]);
            }
            ctrl.redraw();
        }

        function onUnselected(features) {
            var i, len;
            for (i = 0, len = features.length; i < len; i++) {
                var feature = features[i];
                var route = feature.__route;
                var marker = route.__marker;
                // Marker is already Unselected.
                BusPass.RoutesMapController.prototype.unselectRoute.apply(this, [route]);
            }
            ctrl.redraw();
        }

        function onHighlighted(features) {
            var i, len;
            for (i = 0, len = features.length; i < len; i++) {
                var feature = features[i];
                var route = feature.__route;
                var marker = route.__marker;
                // Marker is already Unselected.
                BusPass.RoutesMapController.prototype.highlightRouteAndTrigger.apply(this, [route]);
            }
            ctrl.redraw();
        }

        function onUnhighlighted(features) {
            var i, len;
            for (i = 0, len = features.length; i < len; i++) {
                var feature = features[i];
                var route = feature.__route;
                var marker = route.__marker;
                // Marker is already unhighlighted
                BusPass.RoutesMapController.prototype.unhighlightRoute.apply(this, [route]);
            }
            ctrl.redraw();
        }

        function onClickout() {
            ctrl.redraw();
        }

        ctrl._locationHighlightCtrl = new BusPass.SelectAllFeature(layers, {
            onHighlighted: onHighlighted,
            onUnhighlighted: onUnhighlighted,
            onSelected: onSelected,
            onUnselected: onUnselected
        });
//         ctrl.map.addControl(ctrl._locationHighlightCtrl);
//         ctrl._locationHighlightCtrl.activate();
    },

    // Override
    _removeMapFeatures : function (route) {
        console.log("LocationMapViewController.r_removeMapFeatures: " + route.name);
        if (route.__marker) {
            this._locationMarkers.removeFeatures(marker);
            route.__marker.__route = null;
            delete route.__marker;
        }
        BusPass.RoutesMapController.prototype._removeMapFeatures.apply(this, [route]);
    },

    /**
     * Method: setLocation
     *
     * This method sets the location for the route. It performs
     * the display of the bus arrow icon and does so by
     * creating Vector Features and placing them on the markers
     * layer.
     *
     * Paramteers
     * route   <Route>  The route to set the location on.
     *                  It should be of type "journey".
     * loc     [lon,lat] It can be null, in which case the
     *                   marker will be removed.
     * direction <Radians> Bearing from North.
     */
    setLocation : function (route, loc, direction) {
        if (route.__marker != null) {
            // These may invoke callbacks if the markers were hit with the mouse.
            if (route.__highlighted) {
                this._selectCtrl.unhighlight(route.__marker);
                if (!route.__highlighted) {
                    this.highlightRoute(route);
                }
            }
            if (route.__selected) {
                this._selectCtrl.unselect(route.__marker);
                if (!route.__selected) {
                    this.selectRoute(route);
                }
            }
            this._locationMarkers.removeFeatures(route.__marker);
            route.__marker = null;
        }
        if (loc != null) {
            var lonlat = new OpenLayers.LonLat(loc[0], loc[1]).transform(
                new OpenLayers.Projection("EPSG:4326"), // transform from WGS 1984
                new OpenLayers.Projection("EPSG:900913") // to Spherical Mercator Projection
            );
            // Feature will have 'default' style.
            var geometry = new OpenLayers.Geometry.Point(lonlat.lon, lonlat.lat);
            // In the direction (bearing) is opposite of how we must rotate
            // And the rotation must be in degrees.
            var rotation = -(direction / Math.PI) * 180;
            var attributes = {
                'direction' : direction,
                'rotation' : rotation,
                'route' : route,
                'lonlat' : lonlat,
                'title' :  "" + route.getCode() + " " + route.getDisplayName()
            };
            var marker = new OpenLayers.Feature.Vector(geometry, attributes);
            marker.__route = route; // For SelectControl
            marker.__lonlat = lonlat;
            route.__marker = marker;

            this._locationMarkers.addFeatures(marker);
            if (route.__highlighted) {
                this._selectCtrl.highlight(route.__marker);
            }
            if (route.__selected) {
                // Want to not clear the current selection just to add the marker.
                this._selectCtrl.multiple = true;
                this._selectCtrl.select(route.__marker);
                this._selectCtrl.multiple = false;
            }
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
        this._locationMarkers.redraw();
    },

    _constructLocationLayer : function () {
        var layer = new OpenLayers.Layer.Vector("Locations", {
            rendererOptions: {
                zIndexing : true
            },
            styleMap : this.locationStyleMap
        });
        return layer;
    },

    CLASS_NAME: "BusPass.LocationMapViewController"
});
