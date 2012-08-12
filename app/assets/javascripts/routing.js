
BusPass.Route = OpenLayers.Class({

    /**
     * Attribute: scope
     * This attribute is the context for the onRouteSelect,
     * onRouteUnselect, onRouteHighlight, and onRouteUnhighlight
     * callbacks.
     */
    scope : null,

    onRouteUpdated : function(route) {},

    Map : null,

    /**
     * Property: Yours.Route.parameters.fast
     * Method for route calculation
     *
     * 0 - shortest route
     * 1 - fastest route (default)
     */
    fast: '1',

    /**
     * Property: Yours.Route.parameters.type
     * Type of transportation to use for calculation
     *
     * motorcar - routing for regular cars (default)
     * hvg - Heavy goods, routing for trucks
     * psv - Public transport, routing using public transport
     * bicycle - routing using bicycle
     * foot - routing on foot
     * goods
     * horse
     * motorcycle
     * moped
     * mofa
     * motorboat
     * boat
     */
    type: 'motorcar',

    layer: 'mapnik',

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

    MarkersLayer : null,

    SelectedWaypoint : undefined,

    Waypoints : [],

    Segments : [],

    getWaypoint : function(id) {
        switch(id) {
            case "start":
                wp = this.Waypoints[0];
                break;
            case "end":
                wp = this.Waypoints[this.Waypoints.length - 1];
                break;
            default:
                // id is an index 0,...n
                wp = this.Waypoints[id];
        }
    },

    insertWaypoint : function (index, wp) {
        this.Waypoints.splice(index, 0, wp);
        this.updateWaypointsState();
    },

    createWaypoint : function (index) {
        var wp = new BusPass.Route.Waypoint({ route : this });
        this.Waypoints.splice(index, 0, wp);
        this.updateWaypointsState();
        return wp;
    },

    removeWaypoint : function (id) {
        switch(id) {
            case "start":
                index = 0;
                break;
            case "end":
                index = this.Waypoints.length - 1;
                break;
            default:
                index = id;
        }
        var wp = this.Waypoints[index];
        if (wp == this.SelectedWaypoint) {
            this.SelectedWaypoint = undefined;
        }
        this.Waypoints.splice(index,1);
        this.updateWaypointsState();
    },

    updateWaypointsState : function () {
        // If we have a selected waypoint and we don't find it, we get rid of the current selection.
        var keepSelected = this.SelectedWaypoint === undefined;
        for (var i = 0; i < this.Waypoints.length; i++) {
            var wp = this.Waypoints[i];
            keepSelected = keepSelected || wp == this.SelectedWaypoint
            type = i == 0 ? "start" : (i == this.Waypoints.length ? "end" : "via");
            wp.position = i;
        }
        if (!keepSelected) {
            this.SelectedWaypoint = undefined;
        }
    },

    selectWaypoint : function (id) {
        switch(id) {
            case "start":
                index = 0;
                break;
            case "end":
                index = this.Waypoints.length - 1;
                break;
            default:
                index = id;
        }
        if (id !== undefined) {
            this.SelectedWaypoint = undefined;
        } else {
            this.SelectedWaypoint = this.Waypoints[index];
        }
        return this.SelectedWaypoint;
    },

    incrementSelectedWaypoint : function () {
        if (this.SelectedWaypoint !== undefined) {
            if (this.SelectedWaypoint.type == "last") {
              this.SelectedWaypoint = undefined;
            } else {
                this.SelectedWaypoint = this.Waypoints[this.SelectedWaypoint.position+1];
            }
        } else {
            if (this.Waypoints.length > 0) {
                this.SelectedWaypoint = this.Waypoints[0];
            }
        }
        return this.SelectedWaypoint;
    },

    CLASS_NAME : "BusPass.Route"
});

BusPass.Route.Waypoint = OpenLayers.Class({

    route : null,

    markerUrl : function() { return '/assets/yours/markers/marker-green.png'; },

    onWaypointUpdated : function(wp) {
        this.route.triggerOnLocationUpdated(wp);
    },

    type : "",

    position : null,

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
                this.route.Markers.removeFeatures([this.marker]);
                this.marker.destroy();
            }

            /* Create a marker and add it to the marker layer */
            this.marker = new OpenLayers.Feature.Vector(
                new OpenLayers.Geometry.Point(this.lonlat.lon, this.lonlat.lat),
                {waypoint: this, image: this.markerUrl()}
            );

            this.route.Markers.addFeatures([this.marker]);
        }
    },

    /*
     Function: destroy

     Remove Waypoint from the Vector Layer and destroy it's location information

     */
    destroy : function() {
        if (this.marker !== undefined) {
            this.route.Markers.removeFeatures(this.marker);
            this.marker.destroy();
            this.marker = undefined;
            this.lonlat = undefined;
        }
    },

    update : function (result) {
        if (result == 'OK') {
            if (this.onWaypointUpdated !== undefined) {
                var that = this;
                this.onWaypointUpdated(that);
            }
        }
    },

    CLASS_NAME : "BusPass.Route.Waypoint"
});
