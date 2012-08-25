/**
 * StopPointsController
 *
 *= require ModifyFeature
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

    lock : function () {
        if (this.Waypoint !== undefined) {
            this.Waypoint.Locked = true;
        }
    },

    isLocked : function () {
        if (this.Waypoint !== undefined) {
            return this.Waypoint.Locked;
        }
    },

    setWaypoint : function (wp) {
        this.Waypoint = wp;
        this.Waypoint.Locked = true;
        this.Waypoint.Unlockable = false;
        this.Waypoint.StopPoint = this;
    },

    markerUrl : function() {
        switch (this.type) {
            case 'via':
                return '/assets/yours/markers/number' + this.position + '.png';
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

        // Markers go on top, but will be switched if drawing lines, instead of auto-routing.
        this.Map.addLayers([this.BackLayer, this.RouteLayer, this.MarkersLayer]);

        this.Controls = {
            click: new BusPass.ClickLocationControl({
                onLocationClick : function(lonlat) {
                    var sp = ctrl.onMapClick(lonlat);
                    if (sp) {
                        ctrl.triggerOnLocationUpdated(sp);
                    }
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
                        var sp = wp.StopPoint;
                        if (sp) {
                            ctrl.triggerOnLocationUpdated(sp);
                        }
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

        $("#add_waypoint").click(function () {
            ctrl.addStopPoint();
        });
        $("#autoroute").click(function () {
            console.log("Auto Routes Button " + $(this).hasClass("active"));
            ctrl.setAutoroute($(this).hasClass("active"));
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

        this.initializeFromOptions();
        $("#map").height($("#navigation").height());
        this.Map.updateSize();
    },

    initializeFromOptions : function () {
        this.addStopPoint();
        this.addStopPoint();
    },

    parseKMLToFeatures : function (xml) {
        var kml = new OpenLayers.Format.KML({
            externalProjection : this.Map.displayProjection,
            internalProjection : this.Map.projection
        });
        var features = kml.read(xml);
        return features;
    },

    routeUpdated : function (route) {
        console.log("routeUpdated");
    },

    onLocationUpdated : function (stop_point) {
        var ctrl = this;
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
        this.StopPoints.splice(-1,0,sp);
        var wp = this.Route.insertWaypoint(-1);
        wp.Lockable = true;
        wp.Unlockable = true;
        // Add the DOM LI
        sp.Waypoint = wp;
        wp.StopPoint = sp;

        var sp_li = this.createStopPointDOMElement(sp);

        var ul = $("#route_via");
        if (ul.children().length == 0) {
            ul.append(sp_li);
        } else {
            // Add before the last one.
            ul.find("li.waypoint:last-child").before(sp_li);
        }

        this.updateUI();

        this.Route.selectWaypoint(wp.position);
        this.Controls.click.activate();

        // By inserting new elements we may have moved the map
        $("#map").height($("#navigation").height());
        this.Map.updateSize();
    },

    removeStopPoint : function (stop_point) {
        /*
         * Remove a waypoint from the UI and the route object
         */

        // Deselect waypoint
        var selected = this.Route.getWaypoint("selected");

        if (selected !== undefined && selected == stop_point.waypoint) {
            this.Route.selectWaypoint();
        }

        if (stop_point.position == 0) {
            // Remove all Waypoints uptil the next.
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
        var wp = this.Route.newWaypoint({
            markerUrl : function () {
                return "/assets/yours/markers/yellow.png";
            }
        });
        this.Route.insertWaypoint(sp.Waypoint.position+1, wp);
        if (wp) {
            wp.StopPoint = sp;
            this.Route.selectWaypoint(wp.position);
            this.Controls.click.activate();
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

            // If the waypoint has a link and the location has changed.
            if ((wp.backLink || wp.forwardLink ) && wp.lonlat === undefined ||
                (wp.lonlat.lon != lonlat.lon || wp.lonlat.lat != lonlat.lat)) {
                this.notice("Calculating route", "waiting");
            }
            wp.updateLonLat(lonlat);
            wp.draw();
            var next_stop_point = this.StopPoints[wp.StopPoint.position+1];
            if (next_stop_point !== undefined) {
                var next = this.Route.getWaypoint(next_stop_point.Waypoint.position);
                if (next !== undefined && !next.lonlat) {
                    if (this.Route.selectWaypoint(next.position) === undefined) {
                        this.Controls.click.deactivate();
                    }
                } else {
                    this.Route.selectWaypoint();
                    this.Controls.click.deactivate();
                }
            } else {
                this.Route.selectWaypoint();
                this.Controls.click.deactivate();
            }
            // This might return undefined.
            return wp.StopPoint;
        } else {
            console.log("onMapClick without selected waypoint.");
            return null;
        }
    },

    /*
     * Renumber the UI based on the StopPoint Model.
     */
    updateUI : function () {
        for(var index = 0; index < this.StopPoints.length; index++) {

            var sp = this.StopPoints[index];
            sp.position = index;
            var sp_li = $(sp.viewElement);

            if (this.StopPoints.length < 3) {
                sp_li.find("[name='via_del_image']").attr("disabled","disabled").css("visibility", "hidden");
            } else {
                sp_li.find("[name='via_del_image']").removeAttr("disabled").css("visibility", "visible");
            }

            // Update HTML list
            sp_li.attr("data-position", sp.position);

            var marker_image = sp_li.find("img.marker");
            marker_image.attr("src", sp.markerUrl());

            var addwp_button = sp_li.find("input[name='add_waypoint_image']");
            if (index < this.StopPoints.length-1) {
                addwp_button.removeAttr("disabled");
                addwp_button.css("visibility", "visible");
            } else {
                addwp_button.attr("disabled", "disabled");
                addwp_button.css("visibility", "hidden");
            }

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
        location.attr("type", "text");
        location.attr("name", "sp_location");
        location.addClass("sp_location");
        if (stop_point.Waypoint.lonlat) {
            var lonlat = waypoint.lonlat.clone();
            lonlat.transform(this.Map.projection, this.Map.displayProjection);
            location.val(lonlat.lon.toFixed(6) + "," + lonlat.lat.toFixed(6));
        }
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
        del_button.attr("type", "image");
        del_button.attr("name", "via_del_image");
        del_button.attr("src", "/assets/yours/images/del.png");
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
        addwp_button.attr("type", "button");
        addwp_button.attr("name", "add_waypoint_image");
        addwp_button.attr("alt", "Add Waypoint");
        addwp_button.attr("title", "Add Waypoint");
        addwp_button.bind("click", function () {
            this.Controller.addWaypoint(this.StopPoint);
        });
        addwp_button.attr("value", "Add WayPoint to the biggest name possible");
        addwp_button.attr("disabled", "disabled");
        addwp_button.css("visibility", "hidden");
        addwp_button.addClass("add_waypoint_image");

        sp_li.addClass("waypoint");
        sp_li.append(marker_image);
        sp_li.append(' ');
        sp_li.append(location);
        sp_li.append(' ');
        sp_li.append(name);
        sp_li.append(' ');
        sp_li.append(del_button);
        sp_li.append(' ');
        sp_li.append(addwp_button);

        return sp_li;
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