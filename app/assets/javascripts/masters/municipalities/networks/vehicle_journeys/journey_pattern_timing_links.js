/*
 *= require OpenLayers-2.11/OpenStreetMap
 *= require ClickLocationControl
 *= require routing
 */

function init() {
    new BusPass.PathFinderController({

    });
}

BusPass.PathFinderController = OpenLayers.Class({

    /**
     * Attribute: scope
     * This attribute is the context for the onRouteSelect,
     * onRouteUnselect, onRouteHighlight, and onRouteUnhighlight
     * callbacks.
     */
    scope : null,

    id : "map",

    coordinates : null,

    onLocationUpdated : function(coordinates) {},

    Map : null,

    Controls : null,

    MarkersLayer : null,

    RouteLayer : null,

    SelectedWaypoint : undefined,

    /**
     * Constructor: BusPass.MapLocationTool
     */
    initialize : function (options) {
        OpenLayers.Util.extend(this, options);
        if (this.scope == null) {
            this.scope = this;
        }
        var ctrl = this;

        // Map definition based on http://wiki.openstreetmap.org/index.php/OpenLayers_Simple_Example
        this.Map = new OpenLayers.Map ("map", {
            controls: [
                new OpenLayers.Control.Navigation(),
                new OpenLayers.Control.PanZoomBar(),
                new OpenLayers.Control.Attribution()
            ],
            maxExtent: new OpenLayers.Bounds(-20037508.34,-20037508.34,20037508.34,20037508.34),
            maxResolution: 156543.0399,
            numZoomLevels: 20,
            units: 'm',
            projection: new OpenLayers.Projection("EPSG:900913"),
            displayProjection: new OpenLayers.Projection("EPSG:4326")
        } );
        var layerMapnik = new OpenLayers.Layer.OSM.Mapnik("Mapnik");

        this.Map.addLayers([layerMapnik]);

        this.RouteLayer = new OpenLayers.Layer.Vector("Route");
        this.MarkersLayer = new OpenLayers.Layer.Vector("Markers", {
            styleMap: new OpenLayers.StyleMap({
                "default": new OpenLayers.Style({
                    graphicOpacity: 0.75,
                    externalGraphic: '${image}',
                    graphicWidth: 20,
                    graphicHeight: 34,
                    graphicXOffset: -10,
                    graphicYOffset: -34
                }),
                "select": new OpenLayers.Style({
                    graphicOpacity: 1,
                    cursor: 'move'
                })
            })
        });
        this.Map.addLayers([this.RouteLayer, this.MarkersLayer]);


        this.Controls = {
            click: new BusPass.ClickLocationControl({
                onLocationClick : function(lonlat) {
                    var wp = ctrl.onWaypointClick(lonlat);
                    ctrl.triggerOnLocationUpdated(wp);
                }
            }),
            drag: new OpenLayers.Control.DragFeature(this.MarkersLayer, {
                onComplete: function(feature, pixel) {
                    // The pixel coordinate represents the mouse pointer, which is not the center of the image,
                    // but the location where the user picked the image. Therefore, we use the geometry of the
                    // image, which is the actual image location (respecting any offsets defining its base)
                    var location = new OpenLayers.LonLat(feature.geometry.x, feature.geometry.y);
                    var wp = feature.attributes.waypoint;
                    wp.lonlat = location;
                    ctrl.triggerOnLocationUpdated(wp);
                }
            }),
            select: new OpenLayers.Control.SelectFeature(this.MarkersLayer, {hover: true})
        };
        // Add control to handle mouse clicks for placing markers
        this.Map.addControl(this.Controls.click);
        // Add control to handle mouse drags for moving markers
        this.Map.addControl(this.Controls.drag);
        this.Controls.drag.activate();
        // Add control to show which marker we point at
        this.Map.addControl(this.Controls.select);
        this.Controls.select.activate();

        if (!this.Map.getCenter()) {
            if (this.coordinates) {
                var pos = new OpenLayers.LonLat(coordinates[0], coordinates[1]);
                var transformedLonLat = pos.transform(this.Map.displayProjection, this.Map.projection);
                // make believe we are already set.
                this.onWaypointClick(transformedLonLat);
                this.Map.setCenter(transformedLonLat, 14);
            } else {
                var pos = new OpenLayers.LonLat(-74,34);
                this.Map.setCenter(pos.transform(this.Map.displayProjection, this.Map.projection), 4);
            }
        }

        $("add_waypoint").click(function() {
            console.log("Add Waypoint Button");
            ctrl.addWaypoint(ctrl.Route);
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
            MarkersLayer : this.MarkersLayer
        });

        $("#route_via").append(this.createWaypointDOMElement(this.Route, this.Route.insertWaypoint(-1)));
        $("#route_via").append(this.createWaypointDOMElement(this.Route, this.Route.insertWaypoint(-1)));
        this.Route.selectWaypoint("start");

    },

    onWaypointClick : function (lonlat) {
        var wp = this.Route.getWaypoint("selected");
        console.log("onWaypointClick(" + lonlat + ") = " + wp);

        wp.updateLonLat(lonlat);
        wp.draw();
        this.Route.incrementSelectedWaypoint();
        return wp;
    },

    triggerOnLocationUpdated:function (waypoint) {
        console.log("triggerOnLocationUpdated");
        if (waypoint !== undefined) {
            var point = new OpenLayers.Geometry.Point(waypoint.lonlat.lon, waypoint.lonlat.lat);
            var newPoint = point.transform(this.Map.projection, this.Map.displayProjection);
            var data = newPoint.x.toFixed(6) + ',' + newPoint.y.toFixed(6);
            var lon = newPoint.x.toFixed(6);
            var lat = newPoint.y.toFixed(6);
            this.onLocationUpdated([lon, lat]);
        }
    },

    onLocationUpdated : function(coordinates) {
        console.log("onLocationUpdated("+coordinates+")");
    },

    updateWaypointDeleteButtons : function () {
            // Enable the remove buttons based on the number of waypoints
            var disable_delete = $("#route_via li").length <= 2;
            if (disable_delete) {
                $("#route_via input[name='via_del_image']").attr("disabled", "disabled").css("visibility", "hidden");
            } else {
                $("#route_via input[name='via_del_image']").removeAttr("disabled").css("visibility", "visible");
            }
        },

    addWaypoint : function (route) {
            /*
             * Create a new DOM element to enter waypoint info
             */
            var wp = route.insertWaypoint(-1);
            route.selectWaypoint(wp.position);

            // Update the number of the end
            $("li.waypoint[waypointnr='" + wp.position + "']").attr("waypointnr", wp.position + 1);

            // Add the DOM LI
            var wypt_li = this.createWaypointDOMElement(route, wp);
            $("#route_via > li.waypoint:last-child").before(wypt_li);

            // Enable delete buttons once we have more than two waypoints
            this.updateWaypointDeleteButtons();

            // By inserting new elements we may have moved the map
            this.Map.updateSize();
        },

    createWaypointDOMElement : function (route, waypoint) {
            var waypointName;
            if (waypoint.type == "start") {
                waypointName = "start";
            } else if (waypoint.type == "end") {
                waypointName = "end";
            } else {
                waypointName = "waypoint " + waypoint.position;
            }

            var wypt_li = $(document.createElement("li"));
            wypt_li.attr("waypointnr", waypoint.position);
            wypt_li.addClass("waypoint");

            var marker_image = $(document.createElement("img"));
            marker_image.attr("src", waypoint.markerUrl());
            marker_image.attr("alt", "Via:");
            marker_image.attr("title", "Click to position " + waypointName +  " on the map");
            marker_image.bind("click", function() {
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

            var del_button = $(document.createElement("input"));
            del_button.attr("type", "image");
            del_button.attr("name", "via_del_image");
            del_button.attr("src", "/assets/yours/images/del.png");
            del_button.attr("alt", "Remove " + waypointName + " from the map");
            del_button.attr("title", "Remove " + waypointName + " from the map");
            del_button.bind("click", function() { elementClick(this); });
            del_button.attr("value", "");
            del_button.attr("disabled", "disabled");
            del_button.css("visibility", "hidden");
            del_button.addClass("via_del_image");

            var via_image = $(document.createElement("img"));
            via_image.attr("src", "/assets/yours/images/ajax-loader.gif");
            via_image.css("visibility", "hidden");
            via_image.attr("alt", "");
            via_image.addClass("via_image");

            var via_message = $(document.createElement("span"));
            via_message.addClass("via_message");

            wypt_li.addClass("via");
            wypt_li.append(marker_image);
            wypt_li.append(' ');
            wypt_li.append(location);
            wypt_li.append(' ');
            wypt_li.append(del_button);
            wypt_li.append(' ');
            wypt_li.append(via_image);
            wypt_li.append(via_message);

            return wypt_li;
        },
});