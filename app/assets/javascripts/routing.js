
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

    Links : [],

    initializeWithKML : function (kml) {
        Links = [];
        Waypoints = [];

        var link = new BusPass.Route.Link({
            route : this
        });

        var feature = link.parseKMLToFeature(kml);
        link.initializeWaypointsFromFeature(feature);
        Waypoints = [link.startWaypoint, link.endWaypoint];
        Links = [link];
        this.updateWaypointsState();
    },

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

    // WP.length > 1, Links.length == WP.length -1
    // forall i . 0 <= i < WP.length-1, WP[i] == Link[i].start
    // forall i . 0 < i < WP.length, WP[1] == Link[i-1].end
    insertWaypoint : function (index, wp) {
        if (this.Waypoints.length == 0) {
            index = 0;
        }
        while (index < 0) {
            index = this.Waypoints.length - 1 - index;
        }
        if (index > this.Waypoints.length) {
            // Will be adding to this index
            index = this.Waypoints.length;
        }
        this.Waypoints.splice(index, 0, wp);
        this.updateWaypointsState();
        // 0 <= index < Waypoints.length
        if (index == 0) {
            // WP inserted at beginning,
            // iInsert new Link at beginning if a link exists
            // or there is now 2 Waypoints, create first link.
            if (this.Links.length > 0) {
                var link = new BusPass.Route.Link({
                    route : this,
                    startWaypoint : wp,
                    endWaypoint : this.Links[0].startWaypoint
                });
                wp.forwardLink = link;
                this.Links.splice(index,0,link);
            } else {
                if (this.Waypoints.length > 0) {
                    var link = new BusPass.Route.Link({
                        route : this,
                        startWaypoint : wp,
                        endWaypoint : this.Waypoints[1]
                    });
                    this.Links.splice(index,0,link);
                }
            }
        }
        else {
            if (index == this.Waypoints.length-1) {
                // WP added at end
                // Insert new link at end if link exists
                // or there are now 2 waypoints, create first link.
                if (this.Links.length > 0) {
                    var link = new BusPass.Route.Link({
                        route : this,
                        startWaypoint : this.Links[this.Links.length-1].endWaypoint,
                        endWaypoint : wp
                    });
                    wp.backLink = link;
                    this.Links.splice(index,0,link);
                } else {
                    if (this.Waypoints.length > 0) {
                        var link = new BusPass.Route.Link({
                            route : this,
                            startWaypoint : this.Waypoint[0],
                            endWaypoint : wp
                        })
                        wp.backLink = link;
                        this.Links.splice(index,0,link);
                    }
                }
            }
            else {
                // Remove the link and replace with 2 from the split
                var links = this.Links[index].splitLinkToLinks(wp);
                wp.backLink = links[0];
                wp.forwardLink = links[1];
                this.Links.splice(index,1,links[0],links[1]);
            }
        }
    },

    removeWaypoint : function (id) {
        var index = 0;
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
        if (this.Waypoints.length == 0) {
            index = 0;
        }
        while (index < 0) {
            index = this.Waypoints.length - 1 - index;
        }
        if (index > this.Waypoints.length) {
            index = this.Waypoints.length-1;
        }
        // 0 <= index <= this.Waypoints.length-1
        var wp = this.Waypoints[index];
        if (wp == this.SelectedWaypoint) {
            this.SelectedWaypoint = undefined;
        }
        this.Waypoints.splice(index,1);
        this.updateWaypointsState();
        if (index == 0) {
            // First WP was removed, remove first link
            if (this.Links.length > 0) {
                var link = this.Links[0];
                link.endWaypoint.backLink = undefined;
                this.Links.splice(0,1);
                link.destroy();
            }
        } else {
            if (index == this.Waypoints.length) {
                // Last WP was removed, remove last link
                if (this.Links.length > 0) {
                    var link = this.Links[this.Links.length-1];
                    link.startWaypoint.forwardLink = undefined;
                    this.Links.splice(this.Links.length-1,1);
                    link.destroy();
                }
            } else {
                // 1 < index < Waypoints.length
                if (this.Links.length > 1) {
                    var link1 = this.Links[index-1];
                    var link2 = this.Links[index];
                    var link = this.joinLinksToLink(link1, link2);
                    link.startWaypoint.forwardLink = link;
                    link.endWaypoint.backLink = link;
                    this.Links.splice(index-1,1,link);
                    link1.destroy();
                    link2.destroy();
                }
            }
        }
        wp.destroy();
    },

    updateWaypointsState : function () {
        // If we have a selected waypoint and we don't find it, we get rid of the current selection.
        var keepSelected = this.SelectedWaypoint === undefined;
        for (var i = 0; i < this.Waypoints.length; i++) {
            var wp = this.Waypoints[i];
            keepSelected = keepSelected || wp == this.SelectedWaypoint
            wp.type = i == 0 ? "start" : (i == this.Waypoints.length ? "end" : "via");
            wp.position = i;
        }
        if (!keepSelected) {
            this.SelectedWaypoint = undefined;
        }
    },

    updateLinksState : function () {
        for (var i = 0; i < this.Links.length; i++) {
            var link = this.Links[i];
            if (link.feature === undefined) {
                link.launchGetRoute();
            }
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
            if (this.SelectedWaypoint.type == "end") {
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

    joinLinksToLink : function (link1,link2) {
        var link = new BusPass.Route.Link({
            route : this.route,
            startWaypoint : link1.startWaypoint,
            endWaypoint : link2.endWaypoint
        });
        return link
    },

    CLASS_NAME : "BusPass.Route"
});

BusPass.Route.Link = OpenLayers.Class({

    routeApi : undefined,

    route : null,

    startWaypoint : null,

    endWaypoint : null,

    initialize : function (options) {
        OpenLayers.Util.extend(this, options);
        if (this.scope == null) {
            this.scope = this;
        }
        var ctrl = this;
    },

    points : [],

    feature : null,

    setFeature : function (feature) {
        this.feature = feature;
        this.points = this.feature[0].geometry.components;
    },

    initializeWaypointsFromFeature : function (feature) {
        if (this.feature !== undefined) {
            this.setFeature(feature);
        }
        this.startWaypoint = this.route.createWaypoint(this.points[0]);
        this.endWaypoint = this.route.createWaypoint(this.points[this.points.length-1]);
    },

    setWaypoints : function (fromWp, toWp) {
        this.startWaypoint = fromWp;
        this.endWaypoint = toWp;
    },

    parseKMLToFeature : function (xml) {
        var kml = new OpenLayers.Format.KML({
            externalProjection : this.Map.displayProjection,
            internalProjection : this.Map.projection
        });
        var feature = kml.read(xml);
        return feature;
    },

    launchGetRoute : function (returnCallback, errorCallback) {
        var self = this;
        self.routeApi.getRoute(self.startWaypoint.lonlat, self.endWaypoint.lonlat,
            function (xml) {
                var feature = self.parseKMLToFeature(xml);
                if (feature) {
                    setFeature(feature);
                }
                if (returnCallback !== undefined) {
                    returnCallback(self);
                }
            },
            function(jqXHR, textStatus, errorThrown) {
                if (errorCallback !== undefined) {
                    errorCallback(self, jqXHR, textStatus, errorThrown);
                }
            });
    },

    splitLinkToLinks : function (wp) {
        var link1 = new BusPass.Route.Link({
            route : this.route,
            startWaypoint : this.startWaypoint,
            endWaypoint : wp
        });

        var link2 = new BusPass.Route.Link({
            route : this.route,
            startWaypoint : wp,
            endWaypoint : this.endWaypoint
        });
        return [link1, link2];
    },

    draw : function () {
        if (this.route.Layer !== undefined) {
            this.route.Layer.addFeatures(this.feature);
        }
    },

    destroy : function () {
        if (this.feature) {
            this.route.Layer.removeFeatures(this.feature);
            this.feature = undefined;
        }
        this.startWaypoint = undefined;
        this.endWaypoint = undefined;
        this.route = undefined;
        this.points = undefined;
    }
});

BusPass.Route.Waypoint = OpenLayers.Class({

    route : null,

    markerUrl : function() { return '/assets/yours/markers/marker-green.png'; },

    onWaypointUpdated : function(wp) {
        this.route.triggerOnLocationUpdated(wp);
    },

    backlink : undefined,

    forwardLink : undefined,

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

    destroy : function() {
        if (this.marker !== undefined) {
            this.route.Markers.removeFeatures(this.marker);
            this.marker.destroy();
            this.marker = undefined;
            this.lonlat = undefined;
            this.backLink = undefined;
            this.forwardLink = undefined;
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

BusPass.Route.Api = OpenLayers.Class({

    apiUrl : "/transport.php?url=http://www.yournavigation.com/route.php?",

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
    },

    routeCache : {},

    getRoute : function(flonlat, tlonlat, returnCallback, errorCallback) {

        var self = this;

        var search = 'flat=' + flonlat.lat +
            '&flon=' + flonlat.lon +
            '&tlat=' + tlonlat.lat +
            '&tlon=' + tlonlat.lon;
           search += '&v=' + this.type +
            '&fast=' + this.fast +
            '&layer=' + this.layer;

        if (self.routeCache[search] === undefined) {
            // Not in cache, request from server
            var url = self.apiUrl + search;
            $.get(url, {}, function(xml) {
                if (xml.childNodes.length > 0 && xml.childNodes[0].nodeName == "kml") {
                    self.routeCache[search] = xml;
                }
                returnCallback(xml);
            }, "xml").error(errorCallback);
        } else {
            returnCallback(xml);
        }
    }
});
