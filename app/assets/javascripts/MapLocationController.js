/**
 * Class: MapLocationController
 *
 *= require ClickLocationControl
 */
BusPass.MapLocationController = OpenLayers.Class({

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

    Markers : null,

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
                new OpenLayers.Control.PanZoomBar()
            ],
            /*eventListeners: {
             //"moveend": mapEvent,
             //"zoomend": mapEvent,
             //"changelayer": mapLayerChanged,
             "changebaselayer": onChangeBaseLayer
             },*/
            maxExtent: new OpenLayers.Bounds(-20037508.34,-20037508.34,20037508.34,20037508.34),
            maxResolution: 156543.0399,
            numZoomLevels: 20,
            units: 'm',
            projection: new OpenLayers.Projection("EPSG:900913"),
            displayProjection: new OpenLayers.Projection("EPSG:4326")
        } );
        var layerMapnik = new OpenLayers.Layer.OSM.Mapnik("Mapnik");

        this.Map.addLayers([layerMapnik]);

        this.Markers = new OpenLayers.Layer.Vector("Markers", {
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
        this.Map.addLayers([this.Markers]);


        this.Controls = {
            click: new BusPass.ClickLocationControl({
                onLocationClick : function(lonlat) {
                    var wp = ctrl.onMapClick(lonlat);
                    ctrl.triggerOnLocationUpdated(wp);
                }
            }),
            drag: new OpenLayers.Control.DragFeature(this.Markers, {
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
            select: new OpenLayers.Control.SelectFeature(this.Markers, {hover: true})
        };
        // Add control to handle mouse clicks for placing markers
        this.Map.addControl(this.Controls.click);
        // Add control to handle mouse drags for moving markers
        this.Map.addControl(this.Controls.drag);
        this.Controls.drag.activate();
        // Add control to show which marker we point at
        this.Map.addControl(this.Controls.select);
        this.Controls.select.activate();

        // Set up a selected Waypoint so we can manipulate it.
        this.selectWaypoint(new BusPass.MapLocationController.Waypoint({
            locationController : this
        }));

        if (!this.Map.getCenter()) {
            if (this.coordinates) {
                var pos = new OpenLayers.LonLat(coordinates[0], coordinates[1]);
                var transformedLonLat = pos.transform(this.Map.displayProjection, this.Map.projection);
                // make believe we are already set.
                this.onMapClick(transformedLonLat);
                this.Map.setCenter(transformedLonLat, 14);
            } else {
                if (navigator.geolocation) {
                    // Our geolocation is available, zoom to it if the user allows us to retrieve it
                    navigator.geolocation.getCurrentPosition(function(position) {
                        var pos = new OpenLayers.LonLat(position.coords.longitude, position.coords.latitude);
                        ctrl.Map.setCenter(pos.transform(ctrl.Map.displayProjection, ctrl.Map.projection), 14);
                    });
                } else {
                    var pos = new OpenLayers.LonLat(-74,34);
                    this.Map.setCenter(pos.transform(this.Map.displayProjection,this.Map.projection), 4);
                }
            }
        }

        $("#map").height($("#navigation").height());
        this.Map.updateSize();

    },

    selectWaypoint : function(wp) {
        this.SelectedWaypoint = wp;
        // Setting the cursor on the layer only does not work, so the cursor is set on the container of all layers
        if (this.SelectedWaypoint === undefined) {
            $(this.Markers.div.parentNode).css("cursor",  "default");
            this.Controls.click.deactivate();
        } else {
            this.Controls.click.activate();
            $(this.Markers.div.parentNode).css("cursor",  "url(" + this.SelectedWaypoint.markerUrl() + ") 9 34, pointer");
        }
    },

    onMapClick : function(location) {
        var wp = this.SelectedWaypoint;
        wp.lonlat = location;
        wp.draw();
        // unselect waypoint, because it is now set and we only need one.
        this.selectWaypoint();
        return wp;
    },


    triggerOnLocationUpdated : function (waypoint) {
        if (waypoint !== undefined) {
            var point = new OpenLayers.Geometry.Point(waypoint.lonlat.lon, waypoint.lonlat.lat);
            var newPoint = point.transform(this.Map.projection, this.Map.displayProjection);
            var data = newPoint.x.toFixed(6) + ',' + newPoint.y.toFixed(6);
            var lon = newPoint.x.toFixed(6);
            var lat = newPoint.y.toFixed(6);
            this.onLocationUpdated([lon,lat]);
        }
    },

    CLASS_NAME : "BusPass.MapLocationTool"
});


BusPass.MapLocationController.Waypoint = OpenLayers.Class({
    locationController : null,

    markerUrl : function() { return '/assets/yours/markers/marker-green.png'; },

    onWaypointUpdated : function(wp) {
        this.locationController.triggerOnLocationUpdated(wp);
    },

    /**
     * Constructor: BusPass.MapLocationController.Waypoint
     */
    initialize : function (options) {
        OpenLayers.Util.extend(this, options);
        if (this.scope == null) {
            this.scope = this;
        }
        var ctrl = this;
    },

    /*
     * Function: draw
     *
     * Draw a Waypoint on the Vector Layer. If no lonlat is available, the
     * Waypoint will not be drawn.
     */
    draw : function() {
        if (this.lonlat !== undefined) {
            // Delete old marker, if available
            if (this.marker !== undefined) {
                this.locationController.Markers.removeFeatures([this.marker]);
                this.marker.destroy();
            }

            /* Create a marker and add it to the marker layer */
            this.marker = new OpenLayers.Feature.Vector(
                new OpenLayers.Geometry.Point(this.lonlat.lon, this.lonlat.lat),
                {waypoint: this, image: this.markerUrl()}
            );

            this.locationController.Markers.addFeatures([this.marker]);
        }
    },

    /*
     Function: destroy

     Remove Waypoint from the Vector Layer and destroy it's location information

     */
    destroy : function() {
        if (this.marker !== undefined) {
            this.locationController.Markers.removeFeatures(this.marker);
            this.marker.destroy();
            this.marker = undefined;
            this.lonlat = undefined;
        }
    },

    update : function (result) {
        if (result == 'OK') {
            if (this.onLinksGeometryUpdated !== undefined) {
                var that = this;
                this.onLinksGeometryUpdated(that);
            }
        }
    },

    CLASS_NAME : "BusPass.MapLocationController.Waypoint"
});
