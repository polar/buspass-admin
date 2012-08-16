/*
 *= require OpenLayers-2.12/OpenStreetMap
 *= require ClickLocationControl
 *= require ModifyFeature
 *= require routing
 */

function init(center, startPoint, endPoint, defaultRoute) {
    new BusPass.PathFinderController({
        center : center,
        startPoint : startPoint,
        endPoint : endPoint,
        defaultRoute : defaultRoute

    });
}

BusPass.PathFinderController = OpenLayers.Class({

    id : "map",

    /*
     * The coordinates [lon,lat] of where to center the map.
     */
    center : null,

    startPoint : null,

    endPoint : null,

    /*
     * KML String.
     */
    defaultRoute : null,

    onLocationUpdated : function(coordinates) {},

    initializeFromOptions : function () {
        if (this.defaultRoute) {
            this.initializeFromDefaultRoute();
        } else {
            this.initializeFromWaypoints();
        }
    },

    revert : function () {
        $("#route_via").html("");
        this.Route.clear();
        this.initializeFromDefaultRoute();
    },

    notice : function (message, type) {
        if (message == "")  {
            $("#status").html("");
            return;
        }
        switch (type) {
            case 'warning':
                message = '<span class="alert alert-warning">' + message + '</span>';
                break;
            case 'error':
                message = '<span class="alert alert-error">' + message + '</span>';
                break;
            default:
                message = '<span class="alert alert-info">' + message + '</span>';
        }
        $("#status").html(message);
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
                cursor:'move'
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

    MarkersLayer : null,

    RouteLayer : null,

    /**
     * Constructor: BusPass.MapLocationTool
     */
    initialize : function (options) {
        OpenLayers.Util.extend(this, options);
        var ctrl = this;

        this.Map = this.initializeMap();

        this.RouteLayer = new OpenLayers.Layer.Vector("Route", {
            styleMap: this.initializeRouteStyleMap()
        });

        this.MarkersLayer = new OpenLayers.Layer.Vector("Markers", {
            styleMap: this.initializeMarkerStyleMap()
        });

        // Markers go on top, but will be switched if drawing lines, instead of auto-routing.
        this.Map.addLayers([this.RouteLayer, this.MarkersLayer]);

        this.Controls = {
            click: new BusPass.ClickLocationControl({
                onLocationClick : function(lonlat) {
                    var wp = ctrl.onWaypointClick(lonlat);
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
                        if (wp.backLink || wp.forwardLink) {
                            ctrl.notice("Calculating Route");
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
                            ctrl.notice("");
                        }
                        wp.draw();
                        ctrl.triggerOnLocationUpdated(wp);
                    }
                }
            }),
            modify : new BusPass.Controls.ModifyFeature(this.RouteLayer, {
                standalone : true,
                vertexRenderIntent : "vertex"
            }),
            select: new OpenLayers.Control.SelectFeature(this.MarkersLayer, {hover: true})
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
                ctrl.writeToCopyBox(ctrl.Route);
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
            ctrl.setAutoroute($(this).hasClass("active"));
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

        this.initializeFromOptions();
    },

    initializeFromDefaultRoute : function () {
        var parser = new DOMParser();

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
        this.writeToCopyBox(this.Route);
        this.Route.draw();
    },

    initializeFromWaypoints : function () {
        if (this.startPoint) {
            var pos = new OpenLayers.LonLat(this.startPoint[0], this.startPoint[1]);
            var transformedLonLat = pos.transform(this.Map.displayProjection, this.Map.projection);
            var wp = this.Route.newWaypoint(transformedLonLat);
            this.Route.addWaypoint(wp);
        }
        if (this.endPoint) {
            var pos = new OpenLayers.LonLat(this.endPoint[0], this.endPoint[1]);
            var transformedLonLat = pos.transform(this.Map.displayProjection, this.Map.projection);
            var wp = this.Route.newWaypoint(transformedLonLat);
            this.Route.addWaypoint(wp);
        }
        this.lockEndpoints();
        this.initializeRouteUI();
        // We don't select any waypoints because we only do when they are added.
        this.Route.selectWaypoint();
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

    initializeRouteUI : function () {
        $("#route_via").html("");
        for (var i = 0; i < this.Route.Waypoints.length; i++) {
            var wp = this.Route.Waypoints[i];
            this.addWaypointUI(wp);
        }
        this.renumberWaypointUI();
    },

    setAutoroute : function (autoroute) {
        this.Route.autoroute = autoroute;
        if (this.Route.autoroute) {
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
        } else {
            $("#add_waypoint").attr("disabled", "disabled");

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
            this.notice("Could get route. Please move a point.", "warning");
        } else {
            if (route.isComplete()) {
                this.notice("Route is Complete!");
                this.writeToCopyBox(route);
            }
        }
    },

    onLocationUpdated : function(waypoint, coordinates) {
        console.log("onLocationUpdated("+coordinates+")");
        var wp_li = waypoint.viewElement;
        $(wp_li).find("input.wp_location").val(coordinates[0].toFixed(6)+","+coordinates[1].toFixed(6));
    },

    onWaypointClick : function (lonlat) {
        var wp = this.Route.getWaypoint("selected");
        console.log("onWaypointClick(" + lonlat + ") = " + wp);

        // If the waypoint has a link and the location has changed.
        if ((wp.backLink || wp.forwardLink ) && wp.lonlat === undefined ||
            (wp.lonlat.lon != lonlat.lon || wp.lonlat.lat != lonlat.lat)) {
            this.notice("Route is Calculating");
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

    writeToCopyBox : function (route) {
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
        var wp_li = this.createWaypointDOMElement(route, wp);
        var ul = $("#route_via");
        ul.append(wp_li);
    },

    addWaypoint : function (route) {
        /*
         * Create a new DOM element to enter waypoint info
         * We always add before the last one.
         */
        var wp = route.insertWaypoint(-1);
        wp.Lockable = true;
        wp.Unlockable = true;
        // Add the DOM LI
        var wp_li = this.createWaypointDOMElement(route, wp);

        var ul = $("#route_via");
        if (ul.children().length == 0) {
            ul.append(wp_li);
        } else {
            // Add before the last one.
            ul.find("li.waypoint:last-child").before(wp_li);
        }

        this.renumberWaypointUI();

        route.selectWaypoint(wp.position);
        this.Controls.click.activate();

        // Enable delete buttons once we have more than two waypoints
        this.updateWaypointDeleteButtons();

        // By inserting new elements we may have moved the map
        this.Map.updateSize();
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
        this.Route.removeWaypoint(waypoint.position, true);

        // Renumber in the UI
        this.renumberWaypointUI();

        // Ensure there are always at least two waypoints (start and end)
        this.updateWaypointDeleteButtons();

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
        this.setLockUI(waypoint, lock_button);
    },

    /**
     *  TODO: CLean this up!
     * @param waypoint
     * @param lock_button
     */
    setLockUI : function (waypoint, lock_button) {
        var waypointName;
        if (waypoint.type == "start") {
            waypointName = "start";
        } else if (waypoint.type == "end") {
            waypointName = "end";
        } else {
            waypointName = "waypoint " + waypoint.position;
        }
        if (waypoint.Locked) {
            $(waypoint.viewElement).find("[name='via_del_image']").attr("disabled","disabled").css("visibility", "hidden");
        } else {
            $(waypoint.viewElement).find("[name='via_del_image']").removeAttr("disabled").css("visibility", "visible");
        }
        lock_button = $(lock_button);
        if (waypoint.Locked) {
            lock_button.attr("data-locked", "true");
            lock_button.attr("alt", "Unlock " + waypointName + " on the map");
            lock_button.attr("title", "Unlock " + waypointName + " on the map");
            lock_button.attr("src", "/assets/stock_lock.png");
        } else {
            lock_button.attr("data-locked", "false");
            lock_button.attr("src", "/assets/stock_lock_open.png");
            lock_button.attr("alt", "Lock " + waypointName + " on the map");
            lock_button.attr("title", "Lock " + waypointName + " on the map");
        }
        if (waypoint.Locked) {
            if (waypoint.Unlockable)  {
                lock_button.removeAttr("disabled");
            } else {
                lock_button.attr("disabled","disabled");
            }
        } else {
            if (waypoint.Lockable) {
                lock_button.removeAttr("disabled");
            } else {
                lock_button.attr("disabled","disabled");
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
        if (waypoint.lonlat) {
            var lonlat = waypoint.lonlat.clone();
            lonlat.transform(this.Map.projection, this.Map.displayProjection);
            location.val(lonlat.lon.toFixed(6) + "," + lonlat.lat.toFixed(6));
        }

        var del_button = $(document.createElement("input"));
        del_button.attr("type", "image");
        del_button.attr("name", "via_del_image");
        del_button.attr("src", "/assets/yours/images/del.png");
        del_button.attr("alt", "Remove " + waypointName + " from the map");
        del_button.attr("title", "Remove " + waypointName + " from the map");
        del_button.bind("click", function () {
            ctrl.removeWaypoint(waypoint);
        });
        del_button.attr("value", "");
        del_button.attr("disabled", "disabled");
        del_button.css("visibility", "hidden");
        del_button.addClass("via_del_image");

        var lock_button = $(document.createElement("input"));
        lock_button.attr("type", "image");
        lock_button.bind("click", function () {
            ctrl.toggleWaypointLock(waypoint, this);
        });
        lock_button.attr("name", "via_lock_image");
        lock_button.addClass("via_lock_image");
//
//        var via_image = $(document.createElement("img"));
//        via_image.attr("src", "/assets/yours/images/ajax-loader.gif");
//        via_image.css("visibility", "hidden");
//        via_image.attr("alt", "");
//        via_image.addClass("via_image");
//
//        var via_message = $(document.createElement("span"));
//        via_message.addClass("via_message");

        wp_li.addClass("via");
        wp_li.append(marker_image);
        wp_li.append(' ');
        wp_li.append(location);
        wp_li.append(' ');
        wp_li.append(lock_button);
        wp_li.append(' ');
        wp_li.append(del_button);
        wp_li.append(' ');
//        wp_li.append(via_image);
//        wp_li.append(via_message);

        waypoint.viewElement = wp_li;
        wp_li.waypoint = waypoint;

        ctrl.setLockUI(waypoint, lock_button[0]);

        return wp_li;
    }
});