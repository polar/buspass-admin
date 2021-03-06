/**
 * PathFinderController
 *
 * @type {*}
 *
 *= require ModifyFeature
 *= require Route
 *= require_self
 */
BusPass.PathFinderController = OpenLayers.Class({

    id : "map",

    /**
     * Key Codes used to delete Waypoints from the map. Delete, Backspace
     */
    deleteCodes:[46, 68],

    /*
     * The coordinates [lon,lat] of where to center the map.
     */
    center : null,

    /*
     * The coordinates [lon,lat] of the starting point.
     */
    startPoint : null,

    /*
     * The coordinates [lon,lat] of the end point.
     */
    endPoint : null,

    /*
     * KML String. This it the route that will get modified.
     */
    defaultRoute : null,

    /*
     * KML String. This holds the entire route underneath the link being modified.
     */
    backRoute : null,

    onLocationUpdated : function(coordinates) {},
    onRouteUpdated : function(route) {},

    initializeFromOptions : function () {
        this.initializeFromWaypoints();
    },

    revert : function () {
        var active = this.Controls.modify.active;
        if (active) {
            this.setAutoroute(true);
        }
        $("#route_via").html("");
        this.Route.clear();
        this.initializeFromOptions();
        $("#autoroute").removeClass("active");
    },

    notice : function (message, type) {
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
        $("#status").html(message);
        $("#status").fadeTo("fast", 1);
    },

    initializeMapCenter : function () {
        if (!this.Map.getCenter()) {
            if (this.center) {
                var pos = new OpenLayers.LonLat(this.center[0], this.center[1]);
                this.Map.setCenter(pos.transform(this.Map.displayProjection, this.Map.projection), 14);
            } else {
                var pos = new OpenLayers.LonLat(-74,34);
                this.Map.setCenter(pos.transform(this.Map.displayProjection, this.Map.projection), 4);
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
            "vertex" : new OpenLayers.Style({
                fillColor : "#00aa33",
                strokeWidth: 0,
                fillOpacity : 1,
                pointRadius : 4
            }),
            "select":new OpenLayers.Style({
                strokeColor: "#00FFFF",
                strokeWidth: 3
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
                graphicOpacity:1
            })
        })
        return styleMap;
    },

    initializeModifyStyleMap:function () {
        var styleMap = new OpenLayers.StyleMap({
            "default":new OpenLayers.Style({
                strokeColor:"#00FF00",
                strokeWidth:3
            }),
            "vertex":new OpenLayers.Style({
                fillColor:"#00aa33",
                strokeWidth:0,
                fillOpacity:1,
                pointRadius:4
            }),
            "vertexGraphic":new OpenLayers.Style({
                graphicOpacity:0.75,
                externalGraphic:'${image}',
                graphicWidth:20,
                graphicHeight:34,
                graphicXOffset:-10,
                graphicYOffset:-34
            }),
            "select":new OpenLayers.Style({
                strokeColor:"#00FFFF",
                strokeWidth:3,
                cursor:'move'
            })
        })
        return styleMap;
    },

    initializeMap : function () {
        var map = new OpenLayers.Map ("map", {
            controls: [
                new OpenLayers.Control.Navigation(),
                new OpenLayers.Control.PanZoomBar()
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
            styleMap:this.initializeModifyStyleMap()
        });


        // Markers go on top, but will be switched if drawing lines, instead of auto-routing.
        this.Map.addLayers([this.BackLayer, this.RouteLayer, this.MarkersLayer]);

        this.Controls = {
            click: new BusPass.ClickLocationControl({
                onLocationClick : function(lonlat) {
                    var wp = ctrl.onMapClick(lonlat);
                    ctrl.triggerOnLocationUpdated(wp);
                    ctrl.Controls.click.deactivate();
                }
            }),
            drag: new OpenLayers.Control.DragFeature(this.MarkersLayer, {
                onStart : function(feature, pixel) {
                    var wp = feature.attributes.waypoint;
                    if (wp !== undefined) {
                        if (wp.Locked) {
                            ctrl.notice("Cannot Drag Locked Waypoint", "error");
                            return false;
                        }
                        this.StartDrag = true;
                    }
                },
                onDrag:function (feature, pixel) {
                    var lonlat = new OpenLayers.LonLat(feature.geometry.x, feature.geometry.y);
                    var wp = feature.attributes.waypoint;
                    if (wp !== undefined) {
                        if (wp.Locked) {
                            return false;
                        }
                        if (this.StartDrag) {
                            this.StartDrag = false;
                            if (wp.backLink) {
                                wp.backLink.reset();
                                wp.backLink.draw();
                            }
                            if (wp.forwardLink) {
                                wp.forwardLink.reset();
                                wp.forwardLink.draw();
                            }
                            ctrl.notice("Calculating route", "waiting");
                        }
                        // On drag we keep drawing the attached links so that it appears
                        // the user is dragging the lines as well.
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
                        if (!wp.Locked) {
                            wp.updateLonLat(lonlat);
                        } else {
                            // It's geometry has been moved. Restore its original position
                            wp.resetGeometry();
                            wp.draw();
                            // Gets rid of error message for starting the drag.
                            ctrl.notice("");
                        }
                        wp.draw();
                        ctrl.triggerOnLocationUpdated(wp);
                    }
                }
            }),
            modify:new BusPass.WaypointModifyFeatureControl(this.ModifyLayer, {
                standalone:true,
                vertexRenderIntent:"vertex",
                vertexGraphicRenderIntent:'vertexGraphic'
            }),
            select:new OpenLayers.Control.SelectFeature(this.MarkersLayer, {
                hover:true,
                onSelect:this.selectFeature,
                scope:this
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

        this.RouteLayer.events.on({
            beforefeaturemodified : function (event) {
                console.log("Feature Being Modifed");
                console.log("There are vertices: " + ctrl.Controls.modify.vertices.length);
            },
            featuremodified : function (event) {
                console.log("Feature Modifed");
                console.log("There are vertices: " + ctrl.Controls.modify.vertices.length);
                ctrl.routeModified(ctrl.Route);
            },
            afterfeaturemodified : function (event) {
                console.log("After Feature Modifed");
                console.log("There are vertices: " + ctrl.Controls.modify.vertices.length);
            },
            vertexmodified : function (event) {
                console.log("Vertex Modifed");
                console.log("There are vertices: " + ctrl.Controls.modify.vertices.length);
            }
        });

        $("#add_waypoint").click(function() {
            console.log("Add Waypoint Button");
            ctrl.addWaypoint(ctrl.Route);
        });

        $("#revert").click(function() {
            console.log("Revert Button");
            ctrl.revert();
        });

        $("#autoroute").click(function () {
            console.log("Auto Routes Button " + $(this).hasClass("active"));
            ctrl.setDrawLines(!$(this).hasClass("active"));
        });

        $("#route_waiting").hide();

        $("#button_reroute").click(function() {
            ctrl.reroute();
        });

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

        this.Controls.modify.Route = this.Route;
        this.Controls.modify.mode = OpenLayers.Control.ModifyFeature.RESHAPE;
        this.Controls.modify.createVertices = true;

        // configure the keyboard handler so that we can get Waypoint deletes when
        // mouse is over waypoint and user hits a delete key.
        var keyboardOptions = {
            keydown:this.handleKeypress
        };

        this.handlers = {
            keyboard:new OpenLayers.Handler.Keyboard(this, keyboardOptions)
        };
        this.handlers.keyboard.activate();

        this.initializeFromOptions();
        $("#map").height($("#navigation").height());
        this.Map.updateSize();
    },

    /**
     * This function is the onSelect callback function for the Select Control. We keep the selected
     * feature cached. This is necessary to handle the delete key presses.
     * @param feature
     */
    selectFeature:function (feature) {
        console.log("Selected Feature:");
        this.SelectedFeature = feature;
    },

    parseKMLToFeatures : function (xml) {
        var kml = new OpenLayers.Format.KML({
            externalProjection : this.Map.displayProjection,
            internalProjection : this.Map.projection
        });
        var features = kml.read(xml);
        return features;
    },

    initializeFromDefaultRoute : function () {
        var parser = new DOMParser();

        if (this.backRoute) {
            var kml = parser.parseFromString(this.backRoute, "text/xml");
            var features = this.parseKMLToFeatures(kml);
            this.BackLayer.addFeatures(features);
        }

        var xml = parser.parseFromString(this.defaultRoute,"text/xml");

        this.Route.initializeWithKML(xml);
        var start = this.Route.getWaypoint("start");
        var finish = this.Route.getWaypoint("end");
        start.Locked = true;
        finish.Locked = true;
        var wps_li = this.createWaypointDOMElement(this.Route, start);
        var wpf_li = this.createWaypointDOMElement(this.Route, finish);

        var ul = $("#route_via");
        ul.append(wps_li);
        ul.append(wpf_li);
        this.triggerOnLocationUpdated(start);
        this.triggerOnLocationUpdated(finish);
        this.routeModified(this.Route);
        this.Route.draw();
    },

    initializeFromWaypoints : function () {
        if (this.startPoint) {
            var pos = new OpenLayers.LonLat(this.startPoint[0], this.startPoint[1]);
            var transformedLonLat = pos.transform(this.Map.displayProjection, this.Map.projection);
            var wp = this.Route.newWaypoint({ lonlat : transformedLonLat});
            this.Route.insertWaypoint(0,wp);
        }
        if (this.endPoint) {
            var pos = new OpenLayers.LonLat(this.endPoint[0], this.endPoint[1]);
            var transformedLonLat = pos.transform(this.Map.displayProjection, this.Map.projection);
            var wp = this.Route.newWaypoint({ lonlat : transformedLonLat});
            this.Route.insertWaypoint(1,wp);
        }
        if (this.defaultRoute) {
            this.initializeFromDefaultRoute();
        } else {
            this.lockEndpoints();
            this.initializeRouteUI();
            this.Route.reroute();
        }
        // We don't select any waypoints because we only do when they are added.
        this.Route.selectWaypoint();
    },


    /**
     * Method: handleKeypress
     * Called by the feature handler on keypress.  This is used to delete
     *     Waypoints. If the <deleteCode> property is set, waypoints will
     *     be deleted.
     */
    handleKeypress:function (evt) {
        var code = evt.keyCode;

        // check for delete key
        if (this.SelectedFeature &&
            OpenLayers.Util.indexOf(this.deleteCodes, code) != -1) {
            var waypointMarker = this.Controls.drag.feature;
            if (waypointMarker && !this.Controls.drag.handlers.drag.dragging) {
                var wp = waypointMarker.attributes.waypoint;
                if (wp && !wp.Locked) {
                    console.log("Delete: Waypoint " + wp.position);
                    this.Route.removeWaypoint(waypointMarker.attributes.waypoint, true);
                }
            }
        }
    },

    reroute : function() {
        if (this.Route.getWaypoint("selected")) {
            this.notice("Please set location for waypoint", "warning");
        } else if (this.Route.isComplete()) {
            this.notice("Recalculating route", "waiting");
            this.Route.reroute();
        } else {
            this.notice("Need route to be complete first");
        }
    },

    lockEndpoints : function () {
        this.lockWaypoint("start");
        this.lockWaypoint("end");
    },

    lockWaypoint : function (id) {
        var wp;
        if (id.CLASS_NAME && id.CLASS_NAME == "BusPass.Route.Waypoint") {
            wp = id;
        } else {
            wp = this.Route.getWaypoint(id);
        }
        if (wp) {
            wp.Locked = true;
        }
        return wp;
    },

    /**
     * We only show two waypoints in the UI.
     */
    initializeRouteUI : function () {
        $("#route_via").html("");
        var start = this.Route.getWaypoint("start");
        var end = this.Route.getWaypoint("end");
        this.addWaypointUI(start);
        this.addWaypointUI(end);
    },

    setDrawLines:function (turnon) {
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
            $("#add_waypoint").removeAttr("disabled");
            $("#revert").removeAttr("disabled");
            $("#button_reroute").removeAttr("disabled");
            this.routeUpdated(this.Route);
            $("#autoroute").removeClass("active");
        } else if (!drawlines && turnon) {
            $("#add_waypoint").attr("disabled", "disabled");
            $("#revert").attr("disabled", "disabled");
            $("#button_reroute").attr("disabled", "disabled");

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
            $("#autoroute").addClass("active");
        }
    },

    setAutoroute : function (autoroute) {
        var drawlines = this.Controls.modify.active;
        this.Route.autoroute = autoroute;
        if (drawlines && this.Route.autoroute) {
            var lineString = this.Controls.modify.feature;
            this.Controls.modify.unselectFeature();
            this.RouteLayer.removeFeatures(lineString);
            this.Route.applyLineString(lineString);
            lineString.destroy();
            this.Route.draw();
            this.Controls.modify.deactivate();
            this.Map.removeLayer(this.RouteLayer);
            this.Map.removeLayer(this.MarkersLayer);
            this.Map.addLayers([this.RouteLayer, this.MarkersLayer]);
            $("#add_waypoint").removeAttr("disabled");
            $("#button_reroute").removeAttr("disabled");
            this.routeUpdated(this.Route);
            $("#autoroute").removeClass("active");
        } else if (!drawlines && !this.Route.autoroute) {
            $("#add_waypoint").attr("disabled", "disabled");
            $("#button_reroute").attr("disabled", "disabled");

            // Rebuild from the single LineString, results in one Link.
            this.removeUnlockedWaypoints(this.Route);
            this.Route.eraseLinks();
            var lineString = this.Route.createLineString();
            this.RouteLayer.addFeatures(lineString);
            this.initializeRouteUI();

            this.Map.removeLayer(this.RouteLayer);
            this.Map.removeLayer(this.MarkersLayer);
            this.Map.addLayers([this.MarkersLayer, this.RouteLayer]);
            this.Controls.modify.activate();
            this.Controls.modify.selectFeature(lineString);
            this.routeUpdated(this.Route);
            $("#autoroute").addClass("active");
        }

    },

    removeUnlockedWaypoints : function (route) {
        var waypoints = route.Waypoints.slice(0);
        for(var i = 0; i < waypoints.length; i++) {
            var wp = waypoints[i];
            if (!wp.Locked) {
                route.removeWaypoint(wp, false);
            }
        }
    },

    routeUpdated : function (route) {
        var errors = route.getRoutingErrors();
        if (errors.length > 0) {
            this.notice("Could not get route. Please move a point.", "warning");
        } else {
            if (route.isComplete()) {
                this.notice("Route is Complete!");
                this.routeModified(route);
                this.onRouteUpdated(route);
            }
        }
    },

    onLocationUpdated : function(waypoint, coordinates) {
        console.log("onLocationUpdated("+coordinates+")");
        var wp_li = waypoint.viewElement;
        $(wp_li).find("input.wp_location").val(coordinates[0].toFixed(6)+","+coordinates[1].toFixed(6));
    },

    onMapClick : function (lonlat) {
        var wp = this.Route.getWaypoint("selected");
        console.log("onMapClick(" + lonlat + ") = " + wp);

        // If the waypoint has a link and the location has changed.
        if ((wp.backLink || wp.forwardLink ) && wp.lonlat === undefined ||
            (wp.lonlat.lon != lonlat.lon || wp.lonlat.lat != lonlat.lat)) {
            this.notice("Calculating route", "waiting");
        }
        wp.updateLonLat(lonlat);
        wp.draw();
        var next = this.Route.getWaypoint(wp.position+1);
        if (next !== undefined && !next.lonlat) {
            this.Route.selectWaypoint(next.position);
        } else {
            this.Route.selectWaypoint();
        }
        return wp;
    },

    triggerOnLocationUpdated:function (waypoint) {
        console.log("triggerOnLocationUpdated");
        if (waypoint !== undefined) {
            var lonlat = waypoint.lonlat.clone();
            lonlat.transform(this.Map.projection, this.Map.displayProjection);
            this.onLocationUpdated(waypoint, [lonlat.lon, lonlat.lat]);
        }
    },

    updateWaypointDeleteButtons : function () {
        for(var i = 0; i < this.Route.Waypoints.length; i++) {
            var wp = this.Route.Waypoints[i];
            if (wp.Locked) {
                $(wp.viewElement).find("[name='via_del_image']").attr("disabled","disabled").css("visibility", "hidden");
            } else {
                $(wp.viewElement).find("[name='via_del_image']").removeAttr("disabled").css("visibility", "visible");
            }
        }
    },

    routeModified : function (route) {
        console.log("Write to copy box");
        var data = "";
        for(var i = 0; i < route.Links.length; i++) {
            var link = route.Links[i];
            if (link.lineString !== undefined) {
                for (var j = 0; j < link.points.length; j++) {
                    var point = link.points[j].clone();
                    point = point.transform(this.Map.projection, this.Map.displayProjection)
                    data += " " + point.x.toFixed(6) + "," + point.y.toFixed(6);
                }
            } else {
                return;
            }
        }
        var html = "";

        html += "<kml xmlns='http://earth.google.com/kml/2.0'>";
        html += "<Document><Folder><Placemark><LineString><coordinates>";
        html += data;
        html += "</coordinates></LineString></Placemark></Folder></Document>";
        html += "</kml>";

        $("#copybox_field").val(html);

    },

    /**
     * Creates a UI element for the Way point, and adds it
     * to the list. May have to renumber the UI after done.
     * @param wp  The Waypoint being added to the UI.
     */
    addWaypointUI : function (wp) {
        var wp_li = this.createWaypointDOMElement(this.Route, wp);
        var ul = $("#route_via");
        ul.append(wp_li);
    },

    addWaypoint : function (route) {
        /*
         * Create a new DOM element to enter waypoint info
         * We always add before the last one.
         */
        var wp = route.insertWaypoint(-1);
        wp.type = "other";
        wp.Lockable = true;
        wp.Unlockable = true;
        route.draw();
    },

    removeWaypoint : function (waypoint) {
        /*
         * Remove a waypoint from the UI and the route object
         */

        // Deselect waypoint
        var selected = this.Route.getWaypoint("selected");

        if (selected !== undefined && selected.position == waypoint) {
            this.Route.selectWaypoint();
        }

        // Delete waypoint
        $(waypoint.viewElement).remove();
        waypoint.viewElement = undefined;
        this.notice("Calculating route", "waiting");
        this.Route.removeWaypoint(waypoint.position, true);

        // Ensure there are always at least two waypoints (start and end)
        this.updateWaypointDeleteButtons();

        $("#map").height($("#navigation").height());
        // Redraw map
        this.Map.updateSize();
    },

    /*
     * Renumber the UI based on the Waypoints Model.
     */
    renumberWaypointUI : function () {
        for(var index = 0; index < this.Route.Waypoints.length; index++) {
            var wp = this.Route.Waypoints[index];
            var wp_li = wp.viewElement;

            var waypointName;
            switch(wp.type) {
                case "start" :
                    waypointName = "start";
                    break;
                case "end" :
                    waypointName = "finish";
                    break;
                case "via" :
                    waypointName = "waypoint " + wp.position;
                    break;
                default:
                    waypointName = "error ";
            }

            // Update HTML list
            $(wp_li).attr("waypointnr", wp.position);

            var marker_image = $(wp_li).find("img.marker");
            marker_image.attr("src", wp.markerUrl());
            marker_image.attr("title", "Click to position " + waypointName + " on the map");

            var del_button = $("input[name='via_del_image']", wp_li);
            del_button.attr("alt", "Remove " + waypointName + " from the map");
            del_button.attr("title", "Remove " + waypointName + " from the map");
        }
    },

    toggleWaypointLock : function (waypoint, lock_button) {
        if (waypoint.Locked) {
            if (waypoint.Unlockable) {
                waypoint.Locked = undefined;
            }
        } else {
            if (waypoint.Lockable) {
                waypoint.Locked = true;
            }
        }
    },

    createWaypointDOMElement : function (route, waypoint) {
        var ctrl = this;

        var waypointName;
        if (waypoint.type == "start") {
            waypointName = "start";
        } else if (waypoint.type == "end") {
            waypointName = "end";
        } else {
            waypointName = "waypoint " + waypoint.position;
        }

        var wp_li = $(document.createElement("li"));
        wp_li.attr("waypointnr", waypoint.position);
        wp_li.addClass("waypoint");

        var marker_image = $(document.createElement("img"));
        marker_image.attr("src", waypoint.markerUrl());
        marker_image.attr("alt", "Via:");
        marker_image.attr("title", "Click to position " + waypointName + " on the map");
        marker_image.bind("click", function () {
            var wp = route.getWaypoint("selected");
            if (wp !== undefined && wp.position == this.parentNode.attributes.waypointnr.value) {
                // Already selected, deselect
                route.selectWaypoint();
            } else {
                // Select
                route.selectWaypoint(this.parentNode.attributes.waypointnr.value);
            }
        });
        marker_image.addClass("marker");

        var location = $(document.createElement("input"));
        location.attr("type", "text");
        location.attr("name", "via_location");
        location.addClass("wp_location");
        location.attr("disabled", "disabled");
        if (waypoint.lonlat) {
            var lonlat = waypoint.lonlat.clone();
            lonlat.transform(this.Map.projection, this.Map.displayProjection);
            location.val(lonlat.lon.toFixed(6) + "," + lonlat.lat.toFixed(6));
        }
        wp_li.addClass("via");
        wp_li.append(marker_image);
        wp_li.append(' ');
        wp_li.append(location);

        waypoint.viewElement = wp_li;
        wp_li.waypoint = waypoint;

        return wp_li;
    }
});