/**
 * StopPointsController
 *
 *= require ModifyFeature
 *= require StopPointModifyFeatureControl
 *= require routing
 *= require NameFinder
 *= require_self
 */
BusPass.StopPoint = OpenLayers.Class({

    initialize : function(name, lon, lat) {
        this.name = name;
        if (lon instanceof Array) {
            lat = lon[1];
            lon = lon[0];
        }
        this.lonlat = new OpenLayers.LonLat(lon,lat);
        this.Lockable = true;
        this.Unlockable = true;
    },

    /*
     * Display Name
     */
    name : null,

    /*
     * OpenLayers.LonLat
     */
    lonlat : null,

    /*
     * BusPass.Waypoint on the Route.
     */
    Waypoint: null,

    position: 0,

    Lockable : true,

    Unlockable : true,

    lock : function () {
        if (this.Lockable) {
            this.Locked = true;
        }
    },

    unlock : function () {
        if (this.Unlockable) {
            delete this.Locked;
        }
    },

    isLocked : function () {
        return this.Locked;
    },


    setWaypoint : function (wp) {
        this.Waypoint = wp;
        this.Waypoint.StopPoint = this;
        this.Waypoint.markerUrl = function () {
            return this.StopPoint.markerUrl();
        }
    },

    markerUrl : function() {
        switch (this.Waypoint.type) {
            case 'via':
                return '/assets/yours/markers/number' + (this.position+1) + '.png';
            case 'start':
                return '/assets/yours/markers/route-start.png';
            case 'end':
                return '/assets/yours/markers/route-stop.png';
            default:
                return '/assets/yours/markers/marker-yellow.png';
        }
    }

});

BusPass.JourneyPatternLink = OpenLayers.Class({
    startStopPoint : null,
    endStopPoint : null,
    lineString : null
});

BusPass.JourneyPattern = OpenLayers.Class({
    patternLinks : null
});

BusPass.StopPointsController = OpenLayers.Class({

    id : "map",

    /*
     * The coordinates [lon,lat] of where to center the map.
     */
    center : null,

    /*
     * Initial JourneyPattern.
     */
    Journey : null,

    StopPoints : [],

    /*
     * KML String. This it the route that will get modified.
     */
    defaultRoute : null,

    /*
     * KML String. This holds the entire route underneath the link being modified.
     */
    backRoute : null,

    nameFinder : null,


    notice : function (message, type, fade) {
        if (message == "")  {
            $("#status").html("");
            return;
        }
        switch (type) {
            case 'waiting':
                $("#route_waiting").show();
                message = '<span class="alert alert-info">' + message + '</span>';
                break;
            case 'warning':
                $("#route_waiting").hide();
                message = '<span class="alert alert-warning">' + message + '</span>';
                break;
            case 'error':
                $("#route_waiting").hide();
                message = '<span class="alert alert-error">' + message + '</span>';
                break;
            default:
                $("#route_waiting").hide();
                message = '<span class="alert alert-info">' + message + '</span>';
                setTimeout(function () { $("#status").fadeTo("slow", 0); }, 5000);
        }
        if (fade) {
            setTimeout(function () { $("#status").fadeTo("slow", 0); }, 5000);
        }
        $("#status").html(message);
        $("#status").fadeTo("fast", 1);
    },

    onLocationUpdated : function (stop_point) { },

    initializeMapCenter : function () {
        var ctrl = this;
        if (!this.Map.getCenter()) {
            if (this.center) {
                var pos = new OpenLayers.LonLat(this.center[0], this.center[1]);
                this.Map.setCenter(pos.transform(this.Map.displayProjection, this.Map.projection), 14);
            } else if (navigator.geolocation) {
                // Our geolocation is available, zoom to it if the user allows us to retrieve it
                navigator.geolocation.getCurrentPosition(function(position) {
                    var pos = new OpenLayers.LonLat(position.coords.longitude, position.coords.latitude);
                    ctrl.Map.setCenter(pos.transform(ctrl.Map.displayProjection, ctrl.Map.projection), 14);
                });
            } else {
                var pos = new OpenLayers.LonLat(-76.153558,43.048712);
                this.Map.setCenter(pos.transform(this.Map.displayProjection, this.Map.projection), 14);
            }
        }
    },

    initializeBackStyleMap : function () {
        var styleMap = new OpenLayers.StyleMap({
            "default":new OpenLayers.Style({
                strokeColor: "#2222dd",
                strokeWidth: 3,
                strokeOpacity :.5
            })
        })
        return styleMap;
    },

    initializeRouteStyleMap : function () {
        var styleMap = new OpenLayers.StyleMap({
            "default":new OpenLayers.Style({
                strokeColor: "#00FF00",
                strokeWidth: 3
            }),
            "select":new OpenLayers.Style({
                strokeColor: "#00FFFF",
                strokeWidth: 3,
                cursor:'move'
            })
        })
        return styleMap;
    },

    initializeModifyStyleMap : function () {
        var styleMap = new OpenLayers.StyleMap({
            "default":new OpenLayers.Style({
                strokeColor: "#00FF00",
                strokeWidth: 3
            }),
            "vertex" : new OpenLayers.Style({
                fillColor : "#00aa33",
                strokeWidth: 0,
                fillOpacity : 1,
                pointRadius : 4
            }),
            "vertexGraphic" : new OpenLayers.Style({
                graphicOpacity:0.75,
                externalGraphic:'${image}',
                graphicWidth:20,
                graphicHeight:34,
                graphicXOffset:-10,
                graphicYOffset:-34
            }),
            "select":new OpenLayers.Style({
                strokeColor: "#00FFFF",
                strokeWidth: 3,
                cursor:'move'
            })
        })
        return styleMap;
    },

    initializeMarkerStyleMap : function () {
        var styleMap = new OpenLayers.StyleMap({
            "default":new OpenLayers.Style({
                graphicOpacity:0.75,
                externalGraphic:'${image}',
                graphicWidth:20,
                graphicHeight:34,
                graphicXOffset:-10,
                graphicYOffset:-34
            }),
            "select":new OpenLayers.Style({
                graphicOpacity:1,
                cursor:'pointer'
            })
        })
        return styleMap;
    },

    initializeMap : function () {
        var map = new OpenLayers.Map ("map", {
            controls: [
                new OpenLayers.Control.Navigation(),
                new OpenLayers.Control.PanZoomBar(),
                new OpenLayers.Control.Attribution()
            ],
            layers : [new OpenLayers.Layer.OSM.Mapnik("Mapnik")],
            maxExtent: new OpenLayers.Bounds(-20037508.34,-20037508.34,20037508.34,20037508.34),
            maxResolution: 156543.0399,
            numZoomLevels: 20,
            units: 'm',
            projection: new OpenLayers.Projection("EPSG:900913"),
            displayProjection: new OpenLayers.Projection("EPSG:4326")
        });
        return map;
    },

    Map : null,

    Controls : null,

    BackLayer : null,

    MarkersLayer : null,

    RouteLayer : null,

    /**
     * Constructor: BusPass.PathFinderController
     */
    initialize : function (options) {
        OpenLayers.Util.extend(this, options);
        var ctrl = this;

        this.nameFinder = new BusPass.NameFinder();

        this.Map = this.initializeMap();

        this.BackLayer = new OpenLayers.Layer.Vector("Back", {
            styleMap: this.initializeBackStyleMap()
        });

        this.RouteLayer = new OpenLayers.Layer.Vector("Route", {
            styleMap: this.initializeRouteStyleMap()
        });

        this.MarkersLayer = new OpenLayers.Layer.Vector("Markers", {
            styleMap: this.initializeMarkerStyleMap()
        });

        this.ModifyLayer = new OpenLayers.Layer.Vector("Modify", {
            styleMap: this.initializeModifyStyleMap()
        });

        // Markers go on top, but will be switched if drawing lines, instead of auto-routing.
        this.Map.addLayers([this.BackLayer, this.RouteLayer, this.MarkersLayer]);

        this.Controls = {
            click: new BusPass.ClickLocationControl({
                onLocationClick : function(lonlat) {
                    var sp = ctrl.onMapClick(lonlat);
                    if (sp) {
                        ctrl.updateStopPointLocationUI(sp);
                        ctrl.triggerOnLocationUpdated(sp);
                    }
                }
            }),
            drag: new OpenLayers.Control.DragFeature(this.MarkersLayer, {
                onStart : function(feature, pixel) {
                    var wp = feature.attributes.waypoint;
                    if (wp !== undefined) {
                        if (wp.StopPoint && wp.StopPoint.Locked) {
                            ctrl.notice("Cannot Drag Locked StopPoint", "error");
                            return false;
                        }
                        if (wp.backLink) {
                            wp.backLink.reset();
                            wp.backLink.draw();
                        }
                        if (wp.forwardLink) {
                            wp.forwardLink.reset();
                            wp.forwardLink.draw();
                        }
                    }
                },
                onDrag : function(feature, pixel) {
                    var lonlat = new OpenLayers.LonLat(feature.geometry.x, feature.geometry.y);
                    var wp = feature.attributes.waypoint;
                    if (wp !== undefined) {
                        if (wp.StopPoint && wp.StopPoint.Locked) {
                            return false;
                        }
                        if (wp.backLink) {
                            wp.backLink.draw();
                        }
                        if (wp.forwardLink) {
                            wp.forwardLink.draw();
                        }
                    }
                },
                onComplete: function(feature, pixel) {
                    // The pixel coordinate represents the mouse pointer, which is not the center of the image,
                    // but the location where the user picked the image. Therefore, we use the geometry of the
                    // image, which is the actual image location (respecting any offsets defining its base)
                    var lonlat = new OpenLayers.LonLat(feature.geometry.x, feature.geometry.y);
                    var wp = feature.attributes.waypoint;
                    if (wp !== undefined) {
                        if (wp.StopPoint && wp.StopPoint.Locked) {
                            // It's geometry has been moved. Restore its original position
                            wp.updateLonLat(wp.lonlat);
                            wp.draw();
                            // ctrl.updateStopPointLocationUI(sp);
                            // Gets rid of error message for starting the drag.
                            ctrl.notice("");
                            return false;
                        }
                        wp.updateLonLat(lonlat);
                        wp.draw();
                        if (ctrl.Route.autoroute) {
                            ctrl.notice("Calculating Route", "waiting");
                        }
                        var sp = wp.StopPoint;
                        // StopPoint may be undefined if just a waypoint.
                        if (sp) {
                            ctrl.updateStopPointLocationUI(sp);
                            ctrl.triggerOnLocationUpdated(sp);
                        }
                    }
                }
            }),
            modify : new BusPass.StopPointModifyFeatureControl(this.ModifyLayer, {
                standalone : true,
                vertexRenderIntent : "vertex",
                vertexGraphicRenderIntent : 'vertexGraphic'
            }),
            select: new OpenLayers.Control.SelectFeature(this.MarkersLayer, {
                hover : true,
                onSelect: this.selectFeature,
                scope: this
            })
        };
        // Add control to handle mouse clicks for placing markers
        this.Map.addControl(this.Controls.click);
        this.Controls.click.deactivate();
        // Add control to handle mouse drags for moving markers
        this.Map.addControl(this.Controls.drag);
        this.Controls.drag.activate();
        // Add control to show which marker we point at
        this.Map.addControl(this.Controls.select);
        this.Controls.select.activate();
        this.Map.addControl(this.Controls.modify);

        this.initializeMapCenter();

        $("#add_stoppoint").click(function () {
            ctrl.addStopPoint();
        });

        $("#drawlines").click(function () {
            console.log("Auto Routes Button " + $(this).hasClass("active"));
            ctrl.setDrawLines(!$(this).hasClass("active"));
        });

        $("#route_waiting").hide();

        // Deal with the buttons that flip between names and locations.
        $("#show_names").click(function () {
            ctrl.show_names();
        });
        $("#show_locations").click(function () {
            ctrl.show_locations();
        });
        this.show_names();

        this.RouteApi = new BusPass.Route.Api({
            mapProjection : this.Map.projection,
            apiProjection : this.Map.displayProjection
        });

        this.Route = new BusPass.Route({
            Map : this.Map,
            RouteApi : this.RouteApi,
            Controls : this.Controls,
            RouteLayer : this.RouteLayer,
            MarkersLayer : this.MarkersLayer,
            onRouteUpdated : function (route) {
                ctrl.routeUpdated(route);
            }
        });

        this.Controls.modify.mode = OpenLayers.Control.ModifyFeature.RESHAPE;

        // configure the keyboard handler
        var keyboardOptions = {
            keydown: this.handleKeypress
        };

        this.handlers = {
            keyboard: new OpenLayers.Handler.Keyboard(this, keyboardOptions)
        };
        this.handlers.keyboard.activate();

        this.initializeFromOptions();
        this.updateUI();

        $("#map").height($("#navigation").height());
        this.Map.updateSize();
    },

    selectFeature : function (feature) {
        console.log("Selected Feature:");
        this.SelectedFeature = feature;
    },

    deleteCodes : [46, 68],

    /**
     * Method: handleKeypress
     * Called by the feature handler on keypress.  This is used to delete
     *     Waypoints. If the <deleteCode> property is set, waypoints will
     *     be deleted.
     */
    handleKeypress: function(evt) {
        var code = evt.keyCode;

        // check for delete key
        if(this.SelectedFeature &&
            OpenLayers.Util.indexOf(this.deleteCodes, code) != -1) {
            var waypointMarker = this.Controls.drag.feature;
            if(waypointMarker && !this.Controls.drag.handlers.drag.dragging) {
                var wp = waypointMarker.attributes.waypoint;
                if (wp) {
                    var sp = wp.StopPoint;
                    if (sp) {
                        console.log("Delete: Stopoint " + sp.position + ", Waypoint "+ wp.position);
                        this.removeStopPoint(waypointMarker.attributes.waypoint.StopPoint);
                    } else {
                        console.log("Delete: Waypoint " + wp.position);
                        this.Route.removeWaypoint(waypointMarker.attributes.waypoint);
                    }
                }
            }
        }
    },

    selectStopPoint : function (sp) {
        this.Route.selectWaypoint(sp.Waypoint);
    },


    initializeFromOptions : function () {
        this.addStopPoint();
        this.addStopPoint();
        this.selectStopPoint(this.StopPoints[0]);
        this.Controls.click.activate();
    },

    parseKMLToFeatures : function (xml) {
        var kml = new OpenLayers.Format.KML({
            externalProjection : this.Map.displayProjection,
            internalProjection : this.Map.projection
        });
        var features = kml.read(xml);
        return features;
    },

    updateStopPointLocationUI : function (stop_point) {
        var ctrl = this;

        if (stop_point.Waypoint.lonlat) {
            if (this.Route.autoroute) {
                ctrl.notice("Calculating Route");
                $("#route_waiting").show();
            }
            var lonlat = stop_point.Waypoint.lonlat.clone();
            lonlat.transform(this.Map.projection, this.Map.displayProjection);
            var sp_li = $(stop_point.viewElement);
            sp_li.find("[name='sp_location']").val(lonlat.lon.toFixed(6) + "," + lonlat.lat.toFixed(6));
            if (!stop_point.hasNameSetByUser) {
                this.nameFinder.getNameFromLocation(lonlat, function(json) {
                    if (!stop_point.hasNameSetByUser) {
                       var name = ctrl.findNameReturn(json);
                       sp_li.find("[name='sp_name']").val(name);
                    }
                });
            }
        }
    },

    triggerOnLocationUpdated : function (stop_point) {
        console.log("triggerOnLocationUpdated");
        if (stop_point !== undefined) {
            this.onLocationUpdated(stop_point);
        }
    },

    addStopPoint : function () {
        /*
         * Create a new DOM element to enter waypoint info
         * We always add before the last one.
         */
        var sp = new BusPass.StopPoint("new bus stop",0,0);
        this.StopPoints.splice(this.StopPoints.length,0,sp);
        var wp = this.Route.insertWaypoint("last");
        sp.setWaypoint(wp);

        var sp_li = this.createStopPointDOMElement(sp);

        var ul = $("#stop_points_list");
        ul.append(sp_li);

        // This call resets sp.position.
        this.updateUI();

        this.selectStopPoint(sp);
        this.Controls.click.activate();

        // By inserting new elements we may have moved the map
        $("#map").height($("#navigation").height());
        //this.Map.updateSize();
    },

    removeStopPoint : function (stop_point) {
        /*
         * Remove a waypoint from the UI and the route object
         * We always keep at least two StopPoints
         */
        if (this.StopPoints.length < 3) {
            return;
        }

        // Deselect waypoint
        var selected = this.Route.getWaypoint("selected");

        if (selected !== undefined && selected == stop_point.waypoint) {
            this.Route.selectWaypoint();
        }

        if (stop_point.position == 0) {
            // Remove all Waypoints up until the next.
            var nwps = this.StopPoints[1].Waypoint.position;
            for (var i = 0; i < nwps; i++) {
               this.Route.removeWaypoint("start", false);
            }
        } else if (stop_point.position == this.StopPoints.length-1) {
            var nwps = stop_point.Waypoint.position - this.StopPoints[this.StopPoints.length-2].Waypoint.position;
            for (var i = 0; i < nwps; i++) {
                this.Route.removeWaypoint("end", false);
            }
        }  else {
            this.Route.removeWaypoint(stop_point.Waypoint.position, false);
        }

        // Delete waypoint
        $(stop_point.viewElement).remove();
        stop_point.viewElement = undefined;
        this.StopPoints.splice(stop_point.position,1);
        this.notice("Calculating route", "waiting");
        this.Route.reroute();

        this.updateUI();

        $("#map").height($("#navigation").height());
        // Redraw map
        this.Map.updateSize();
    },

    addWaypoint : function (sp) {
        if (this.Route.isComplete()) {
            var wp = this.Route.newWaypoint({
                markerUrl : function () {
                    return "/assets/yours/markers/yellow.png";
                }
            });
            this.Route.insertWaypoint(sp.Waypoint.position+1, wp);
            if (wp) {
                //this.Route.selectWaypoint(wp.position);
                //this.Controls.click.activate();
            }
        }
    },

    setDrawLines : function (turnon) {
        var turnoff = !turnon;
        var drawlines = this.Controls.modify.active;
        // If we are already drawlines and the Route is in auto route mode,
        if (drawlines && turnoff) {
            // We go to Autoroute.
            this.Route.autoroute = true;
            // Unselect the modified feature.
            var lineString = this.Controls.modify.feature;
            this.Controls.modify.unselectFeature();
            // Create the route from the modified string.
            this.RouteLayer.removeAllFeatures();
            this.Route.applyLineString1(lineString);
            lineString.destroy();
            this.Route.draw();
            this.Controls.modify.deactivate();
            this.Map.removeLayer(this.ModifyLayer);
            this.Map.addLayers([this.RouteLayer, this.MarkersLayer]);
            $("#add_stoppoint").removeAttr("disabled");
            $(".add_waypoint").removeAttr("disabled");
            this.routeUpdated(this.Route);
            $("#drawlines").removeClass("active");
        } else if (!drawlines && turnon) {
            $("#add_stoppoint").attr("disabled", "disabled");
            $(".add_waypoint").attr("disabled", "disabled");

            // Rebuild from the single LineString, results in one Link.
            var lineString = this.Route.createWaypointModifyLineString();
            this.ModifyLayer.removeAllFeatures();
            this.ModifyLayer.addFeatures(lineString);

            this.Map.removeLayer(this.RouteLayer);
            this.Map.removeLayer(this.MarkersLayer);
            this.Map.addLayers([this.ModifyLayer]);
            this.Controls.modify.activate();
            this.Controls.modify.selectFeature(lineString);
            this.routeUpdated(this.Route);
            $("#drawlines").addClass("active");
        }
    },

    /**
     * A waypoint gets clicked on and sends us this update from the ClickControl.
     * @param lonlat
     * @return {*}
     */
    onMapClick : function (lonlat) {
        var wp = this.Route.getWaypoint("selected");
        if (wp !== undefined) {
            console.log("onMapClick(" + lonlat + ") = " + wp);
            this.updateWayPointLonlatAndSelection(wp, lonlat);
            if (wp.StopPoint) {
                this.updateStopPointLocationUI(wp.StopPoint);
            }
        } else {
            console.log("onMapClick without selected waypoint.");
            return null;
        }
    },

    /**
     * Update a waypoint with the lonlat. If it is selected and it's a StopPoint, then move
     * the selection to the next StopPoint.
     * @param wp
     * @param lonlat
     * @return {*}
     */
    updateWayPointLonlatAndSelection : function (wp, lonlat) {
        console.log("updateWayPointLonlat(" + lonlat + ") = " + wp);

        // If the waypoint has a link and the location has changed.
        if ((wp.backLink || wp.forwardLink ) && wp.lonlat === undefined ||
            (wp.lonlat.lon != lonlat.lon || wp.lonlat.lat != lonlat.lat)) {
            this.notice("Calculating route", "waiting");
        }
        wp.updateLonLat(lonlat);
        wp.draw();
        if (wp == this.Route.getWaypoint("selected") && wp.StopPoint) {
            var next_stop_point = this.StopPoints[wp.StopPoint.position+1];
            if (next_stop_point !== undefined) {
                // We ask the route, just in case the Waypoint got deleted.
                var next = this.Route.getWaypoint(next_stop_point.Waypoint.position);
                if (next !== undefined && !next.lonlat) {
                    if (this.Route.selectWaypoint(next.position) === undefined) {
                        this.Controls.click.deactivate();
                    }
                } else {
                    // unselect
                    this.Route.selectWaypoint();
                    this.Controls.click.deactivate();
                }
            } else {
                // unselect
                this.Route.selectWaypoint();
                this.Controls.click.deactivate();
            }
            // This might return undefined.
            return wp.StopPoint;
        } else {
            // unselect
            this.Route.selectWaypoint();
            this.Controls.click.deactivate();
        }

    },

    routeUpdated : function (route) {
        this.updateUI();
    },

    toggleWaypointLock : function (stop_point, lock_button) {
        if (stop_point.Locked) {
            if (stop_point.Unlockable) {
                stop_point.Locked = undefined;
            }
        } else {
            if (stop_point.Lockable) {
                stop_point.Locked = true;
            }
        }
        this.setLockUI(stop_point, lock_button);
    },

    inputUpdateStopPointLocation : function (stop_point, input_field) {
        var ctrl = this;
        if (stop_point.Locked) {
            var lonlat = stop_point.Waypoint.lonlat.clone();
            lonlat.transform(ctrl.Map.projection, ctrl.Map.displayProjection);
            $(input_field).val(lonlat.lon.toFixed(6) + "," + lonlat.lat.toFixed(6));
            ctrl.notice("Cannot change location of locked stop", "error", true);
        } else {
            var val = $(input_field).val();
            var ll = JSON.parse("["+val+"]").slice(0,2);
            if (ll && ll.length == 2 && -180 <= ll[0] && ll[0] <= 180 && -90 <= ll[1] && ll[1] <= 90) {
                var lonlat = new OpenLayers.LonLat(ll[0],ll[1]);
                lonlat.transform( ctrl.Map.displayProjection, ctrl.Map.projection);
                ctrl.updateWayPointLonlatAndSelection(stop_point.Waypoint, lonlat);
                ctrl.updateStopPointLocationUI(stop_point);
                ctrl.triggerOnLocationUpdated(stop_point);
            } else {
                ctrl.updateStopPointLocationUI(stop_point);
                ctrl.notice("Location Badly formatted. Reset", "error", true);
            }
        }
    },

    /**
     *  TODO: CLean this up!
     * @param stop_point
     * @param lock_button
     */
    setLockUI : function (stop_point, lock_button) {
        lock_button = $(lock_button);
        if (stop_point.Locked) {
            lock_button.attr("data-locked", "true");
            lock_button.attr("alt", "Unlock " + stop_point.name + " on the map");
            lock_button.attr("title", "Unlock " + stop_point.name + " on the map");
        } else {
            lock_button.attr("data-locked", "false");
            lock_button.attr("alt", "Lock " + stop_point.name + " on the map");
            lock_button.attr("title", "Lock " + stop_point.name + " on the map");
        }
        if (stop_point.Locked) {
            if (stop_point.Unlockable)  {
                lock_button.removeAttr("disabled");
            } else {
                lock_button.attr("disabled","disabled");
            }
        } else {
            if (stop_point.Lockable) {
                lock_button.removeAttr("disabled");
            } else {
                lock_button.attr("disabled","disabled");
            }
        }
    },

    /*
     * Renumber the UI based on the StopPoint Model.
     */
    updateUI : function () {
        // Enable Add Bus Stop when we have a complete route.
        if (this.Route.isComplete()) {
            $("#add_stoppoint").removeAttr("disabled");
            $("#route_waiting").hide();
            this.notice("");
        } else {
            $("#add_stoppoint").attr("disabled", "disabled");
        }
        for(var index = 0; index < this.StopPoints.length; index++) {

            var sp = this.StopPoints[index];
            sp.position = index;
            var sp_li = $(sp.viewElement);

            if (this.StopPoints.length < 3 || sp.Locked) {
                sp_li.find("[name='via_del_image']").attr("disabled","disabled").css("visibility", "hidden");
            } else {
                sp_li.find("[name='via_del_image']").removeAttr("disabled").css("visibility", "visible");
            }

            // Update HTML list
            sp_li.attr("data-position", sp.position);

            var marker_image = sp_li.find("img.marker");
            marker_image.attr("src", sp.markerUrl());

            var addwp_button = sp_li.find("input.add_waypoint");
            if (index < this.StopPoints.length-1) {
                addwp_button.removeAttr("disabled");
                addwp_button.css("visibility", "visible");
            } else {
                addwp_button.attr("disabled", "disabled");
                addwp_button.css("visibility", "hidden");
            }

        }
        if ($("#show_names").hasClass("active")) {
            this.show_names();
        } else {
            this.show_locations();
        }
    },

    createStopPointDOMElement : function (stop_point) {
        var ctrl = this;

        var sp_li = $(document.createElement("li"));
        stop_point.viewElement = sp_li;
        sp_li[0].StopPoint = stop_point;

        var marker_image = $(document.createElement("img"));
        marker_image.attr("src", stop_point.markerUrl());
        marker_image[0].StopPoint = stop_point;
        marker_image[0].Route = this.Route;
        marker_image.attr("alt", "SP:");
        marker_image.attr("title", "Click to position " + stop_point.name + " on the map");
        marker_image.bind("click", function () {
            var wp = this.Route.getWaypoint("selected");
            if (wp !== undefined && wp.StopPoint == this.StopPoint) {
                // Already selected, deselect.
                this.Route.selectWaypoint();
            } else {
                // Select
                this.Route.selectWaypoint(this.StopPoint.Waypoint.position);
            }
        });
        marker_image.addClass("marker");

        var location = $(document.createElement("input"));
        location[0].StopPoint = stop_point;
        location[0].Controller = this;
        location.attr("type", "text");
        location.attr("name", "sp_location");
        location.addClass("sp_location");
        if (stop_point.Waypoint.lonlat) {
            var lonlat = stop_point.Waypoint.lonlat.clone();
            lonlat.transform(this.Map.projection, this.Map.displayProjection);
            location.val(lonlat.lon.toFixed(6) + "," + lonlat.lat.toFixed(6));
        }
        location.change(function () {
           this.Controller.inputUpdateStopPointLocation(this.StopPoint, this);
        });
        var name = $(document.createElement("input"));
        name[0].StopPoint = stop_point;
        name.attr("type", "text");
        name.attr("name", "sp_name");
        name.addClass("sp_name");
        name.val(stop_point.name);
        name.change(function () {
            this.StopPoint.hasNameSetByUser = true;
        });

        var del_button = $(document.createElement("input"));
        del_button[0].Controller = ctrl;
        del_button[0].StopPoint = stop_point;
        del_button.attr("type", "button");
        del_button.attr("name", "via_del_image");
        del_button.attr("alt", "Remove " + stop_point.name + " from the map");
        del_button.attr("title", "Remove " + stop_point.name + " from the map");
        del_button.bind("click", function () {
            this.Controller.removeStopPoint(this.StopPoint);
        });
        del_button.attr("value", "");
        del_button.attr("disabled", "disabled");
        del_button.css("visibility", "hidden");
        del_button.addClass("via_del_image");

        var addwp_button = $(document.createElement("input"));
        addwp_button[0].Controller = ctrl;
        addwp_button[0].StopPoint = stop_point;
        addwp_button.addClass("add_waypoint");
        addwp_button.attr("type", "button");
        addwp_button.attr("title", "Add waypoint after this stop");
        addwp_button.bind("click", function () {
            this.Controller.addWaypoint(this.StopPoint);
        });
        addwp_button.attr("disabled", "disabled");
        addwp_button.css("visibility", "hidden");

        var lock_button = $(document.createElement("input"));
        lock_button.attr("type", "button");
        lock_button.bind("click", function () {
            ctrl.toggleWaypointLock(stop_point, this);
        });
        lock_button.attr("name", "via_lock_image");
        lock_button.addClass("via_lock_image");

        sp_li.addClass("waypoint");
        sp_li.append(marker_image);
        sp_li.append(' ');
        var div1 = $(document.createElement("span"));
        div1.append(location);
        div1.append(' ');
        div1.append(name);
        sp_li.append(div1);
        sp_li.append(lock_button);
        sp_li.append(' ');
        sp_li.append(del_button);
        sp_li.append(' ');
        sp_li.append(addwp_button);

        this.setLockUI(stop_point, lock_button);

        return sp_li;
    },

    show_names : function () {
        $("#show_names").addClass("active");
        $("#show_locations").removeClass("active");
        $(".sp_name").show();
        $(".sp_location").hide();
    },

    show_locations : function () {
        // I don't know why the Boostrap Radio buttons aren't working.
        $("#show_locations").addClass("active");
        $("#show_names").removeClass("active");
        $(".sp_name").hide();
        $(".sp_location").show();
    },

    findNameReturn : function (json) {
        var ans = json.address;
        if (ans) {
            var part = ans.building;
            if (part != undefined) {
                return part;
            }
            part = ans.road;
            if (part != undefined) {
                return part;
            }
            part = ans.place;
            if (part != undefined) {
                return part;
            }
            return ans.display_name;
        }
    },

    CLASS_NAME : "BusPass.StopPointsController"
});