
BusPass.Route = OpenLayers.Class({

    /**
     * Attribute: scope
     * This attribute is the context for the onRouteSelect,
     * onRouteUnselect, onRouteHighlight, and onRouteUnhighlight
     * callbacks.
     */
    scope : null,

    RouteApi : null,

    /**
     * This option tells the Router to invoke the Route Finding Service
     * to get a route. Otherwise, it just draws straight lines.
     */
    autoroute : true,

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

    Controls : null,

    MarkersLayer : null,

    RouteLayer : null,

    SelectedWaypoint : undefined,

    Waypoints : [],

    Links : [],

    parseKMLToFeatures : function (xml) {
        var kml = new OpenLayers.Format.KML({
            externalProjection : this.Map.displayProjection,
            internalProjection : this.Map.projection
        });
        var features = kml.read(xml);
        return features;
    },

    /**
     *
     * @param lineString OpenLayers.Feature.Vector(LineString)
     */
    initializeWithLineString : function (lineString) {
        for(var i = 0; i < this.Links.length; i++) {
            this.Links[i].destroy();
        }
        if (this.Waypoints && this.Waypoints.length > 1) {
            var removed = this.Waypoints.splice(1,this.Waypoints.length-2);
            for(var i = 0; i < removed.length; i++) {
                removed[i].destroy();
            }
        }

        var link = new BusPass.Route.Link({
            route : this,
            startWaypoint : this.Waypoints[0],
            endWaypoint : this.Waypoints[1],
            lineString : lineString
        });

        this.Links = [link];
        this._updateWaypointsState();

    },

    initializeWithKML : function (kml) {
        var features =  this.parseKMLToFeatures(kml);
        // The lineString should be the first feature.
        // Others are ignored.
        this.initializeWithLineString(features[0]);
    },

    /**
     * Returns the actual points making up the lineStrings. That is so, if we
     * manipulate them with ModifyFeature Control we manipulate the drawing.
     * @return {*}
     */
    getPoints : function () {
        data = [];
        for(var i = 0; i < this.Links.length; i++) {
            var link = this.Links[i];
            var vertex = link.startWaypoint.marker.geometry;
            vertex._vertex = link.startWaypoint;
            data.push(vertex);
            if (link.lineString !== undefined) {
                for (var j = 0; j < link.points.length; j++) {
                    var point = link.points[j];
                    data.push(point);
                }
            } else {
                return;
            }
            if (i == this.Links.length - 1) {
                vertex = link.endWaypoint.marker.geometry;
                vertex._vertex = link.endWaypoint;
                data.push(vertex);
            }
        }
        return data;
    },

    createLineString : function () {
        var points = this.getPoints();
        var geometry = new OpenLayers.Geometry.LineString(points);
        var lineString = new OpenLayers.Feature.Vector(geometry);
        return lineString;
    },

    newWaypoint : function(options) {
        options = OpenLayers.Util.extend({}, options);
        options = OpenLayers.Util.extend(options, {
            route : this
        });
        var wp = new BusPass.Route.Waypoint(options);
        return wp;
    },

    getWaypoint : function(id) {
        switch(id) {
            case "start":
                wp = this.Waypoints[0];
                break;
            case "end":
                wp = this.Waypoints[this.Waypoints.length - 1];
                break;
            case "selected":
                wp = this.SelectedWaypoint;
                break;
            default:
                // id is an index 0,...n
                wp = this.Waypoints[id];
        }
        return wp;
    },

    // WP.length > 1, Links.length == WP.length -1
    // forall i . 0 <= i < WP.length-1, WP[i] == Link[i].start
    // forall i . 0 < i < WP.length, WP[1] == Link[i-1].end
    insertWaypoint : function (index, wp) {
        if (this.Waypoints.length == 0) {
            index = 0;
        }
        // Install at last position if index isn't a number
        // Ex: insertWaypoint("last", wp);
        if (isNaN(index)) {
            index = this.Waypoints.length;
        }
        // negative modulo. -1 is before the last one
        while (index < 0) {
            index = this.Waypoints.length + index;
        }
        if (index > this.Waypoints.length) {
            // Will be adding to this index
            index = this.Waypoints.length;
        }
        if (wp === undefined) {
            wp = new BusPass.Route.Waypoint({
                route : this
            });
        }
        this.Waypoints.splice(index, 0, wp);
        this._updateWaypointsState();
        // 0 <= index < Waypoints.length
        if (index == 0) {
            // WP inserted at beginning,
            // Insert new Link at beginning if a link exists
            // or if there is now 2 Waypoints, create first link.
            if (this.Links.length > 0) {
                var link = new BusPass.Route.Link({
                    route : this,
                    startWaypoint : wp,
                    endWaypoint : this.Links[0].startWaypoint
                });
                this.Links.splice(index,0,link);
            } else {
                if (this.Waypoints.length > 1) {
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
                    this.Links.splice(index,0,link);
                } else {
                    if (this.Waypoints.length > 1) {
                        var link = new BusPass.Route.Link({
                            route : this,
                            startWaypoint : this.Waypoints[0],
                            endWaypoint : wp
                        });
                        this.Links.splice(index,0,link);
                    }
                }
            }
            else {
                // Remove the link and replace with 2 from the split
                var link = this.Links[index-1];
                var links = this.splitLinkToLinks(link, wp);
                this.Links.splice(index-1,1,links[0],links[1]);
                link.destroy();
            }
        }
        return wp;
    },

    removeWaypoint:function (id, reroute) {
        console.log("removeWaypoint " + id + " reroute " + reroute);
        var index = 0;
        var wp;
        if (id.CLASS_NAME && id.CLASS_NAME == "BusPass.Route.Waypoint") {
            index = id.position;
            wp = id;
            console.log("RemoveWaypoint wp a "  + index);
        } else {
            switch (id) {
                case "start":
                    index = 0;
                    break;
                case "end":
                    index = this.Waypoints.length - 1;
                    break;
                case "selected":
                    index = this.SelectedWaypoint.position;
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
                index = this.Waypoints.length - 1;
            }
            wp = this.Waypoints[index];
        }
        console.log("RemoveWaypoint wp at " + index);
        // 0 <= index <= this.Waypoints.length-1
        if (wp == this.SelectedWaypoint) {
            this.SelectedWaypoint = undefined;
        }
        this.Waypoints.splice(index, 1);
        this._updateWaypointsState();
        console.log("RemoveWaypoint wp at " + wp.backLink + " forward " + wp.forwardLink);
        if (wp.backLink && wp.forwardLink) {
            var link1 = this.Links[index - 1];
            if (wp.backLink != link1) {
                console.log("RemoveWaypoint : inconsistent backLinke");
            }
            var link2 = this.Links[index];
            if (wp.forwardLink != link2) {
                console.log("RemoveWaypoint : inconsistent forwardLink");
            }
            var link = this.joinLinksToLink(link1, link2);
            this.Links.splice(index - 1, 2, link);
            if (reroute) {
                link.reroute();
            } else {
                if (link1.points && link2.points) {
                    var vertex = link1.endWaypoint.marker.geometry;
                    var components = [];
                    for(var i = 0; i < link1.points.length; i++) {
                        components.push(link1.points[i].clone());
                    }
                    components.push(vertex.clone());
                    for(var j = 0; j < link2.points.length; j++) {
                        components.push(link2.points[j].clone());
                    }
                    link.lineString = new OpenLayers.Feature.Vector(
                        new OpenLayers.Geometry.LineString(components));
                    link.points = link.lineString.geometry.components;
                } else {
                    console.log("We need to wait for an upate");
                }
            }
            link1.destroy();
            link2.destroy();
        } else {
            if (wp.backLink) {
                wp.backLink.destroy();
            }
            if (wp.forwardLink) {
                wp.forwardLink.destroy();
            }
            this.Links.splice(index, 1);
        }
        wp.destroy();
    },

    _updateWaypointsState : function () {
        // If we have a selected waypoint and we don't find it, we get rid of the current selection.
        var keepSelected = this.SelectedWaypoint === undefined;
        for (var i = 0; i < this.Waypoints.length; i++) {
            var wp = this.Waypoints[i];
            keepSelected = keepSelected || wp == this.SelectedWaypoint
            wp.type = i == 0 ? "start" : (i == this.Waypoints.length-1 ? "end" : "via");
            wp.position = i;
        }
        if (!keepSelected) {
            this.SelectedWaypoint = undefined;
        }
    },

    applyLineString : function (lineString) {
        var components = lineString.geometry.components;
        var index = 0;
        var collected = 0;
        for(var i = 0; i < this.Links.length; i++) {
            var link = this.Links[i];
            var points = [];
            while(index < components.length && components[index]._vertex != link.startWaypoint) {
                var point = components[index];
                console.log("Link " + i + " point " + points.length + " is not in the beginning.");
                index += 1;
            }
            // Skip putting the vertex point in the Link's LineString
            if (components[index]._vertex == link.startWaypoint) {
                index += 1;
            } else {
                console.log("Link " + i + " inconsistent on startWaypoint");
            }
            while(index < components.length && components[index]._vertex != link.endWaypoint) {
                var point = components[index];
                points.push(point)
                index += 1;
            }
            // Skip putting the vertex point in the Link's LineString
            if (components[index]._vertex == link.endWaypoint) {
                // There should only be one waypoint vertex point in between the links.
                // components[index]._vertex should also == next link.startWaypoint.
                // catch it at the top.
            } else {
                console.log("Link " + i + " inconsistent on startWaypoint");
            }
            link.lineString = new OpenLayers.Feature.Vector(new OpenLayers.Geometry.LineString(points));
            link.points = link.lineString.geometry.components;
            collected += points.length;
        }
    },

    reroute : function () {
        for(var i = 0; i < this.Links.length; i++) {
            var link = this.Links[i];
            link.reroute();
        }
    },

    eraseLinks : function () {
        for(var i = 0; i < this.Links.length; i++) {
            var link = this.Links[i];
            link.erase();
        }
    },

    clear : function () {
        for(var i = 0; i < this.Waypoints.length; i++) {
            var wp = this.Waypoints[i];
            wp.destroy();
        }
        for(var i = 0; i < this.Links.length; i++) {
            var link = this.Links[i];
            link.destroy();
        }
        this.Waypoints = [];
        this.Links = [];
        this.SelectedWaypoint = undefined;
    },

    updateLinksState : function () {
        for (var i = 0; i < this.Links.length; i++) {
            var link = this.Links[i];
            if (link.lineString === undefined) {
                link.launchGetRoute();
            }
        }
    },

    selectWaypoint : function (id) {
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
        console.log("Selected Waypoint " + index);
        if (id === undefined) {
            this.SelectedWaypoint = undefined;
        } else {
            this.SelectedWaypoint = this.Waypoints[index];
        }
        this.setSelectedCursor();
        return this.SelectedWaypoint;
    },

    // TODO: This shouldn't be here.
    setSelectedCursor : function () {
        // Setting the cursor on the layer only does not work, so the cursor is set on the container of all layers
        if (this.SelectedWaypoint === undefined) {

            console.log("Now Selected Waypoint undefined");
            $(this.MarkersLayer.div.parentNode).css("cursor",  "default");
            this.Controls.click.deactivate();
        } else {
            console.log("Now Selected Waypoint " + this.SelectedWaypoint.position);
            this.Controls.click.activate();
            $(this.MarkersLayer.div.parentNode).css("cursor",  "url(" + this.SelectedWaypoint.markerUrl() + ") 9 34, pointer");
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
        this.setSelectedCursor();
        return this.SelectedWaypoint;
    },

    splitLinkToLinks : function (link, wp) {
        var link1 = new BusPass.Route.Link({
            route : this,
            startWaypoint : link.startWaypoint,
            endWaypoint : wp
        });

        var link2 = new BusPass.Route.Link({
            route : this,
            startWaypoint : wp,
            endWaypoint : link.endWaypoint
        });

        return [link1, link2];
    },

    joinLinksToLink : function (link1, link2) {
        var link = new BusPass.Route.Link({
            route : this,
            startWaypoint : link1.startWaypoint,
            endWaypoint : link2.endWaypoint
        });
        return link;
    },

    draw : function () {
        for (var i = 0; i < this.Waypoints.length; i++) {
            this.Waypoints[i].draw();
        }
        for (var i = 0; i < this.Links.length; i++) {
            this.Links[i].draw();
        }
    },

    /*
     * A route is complete if all it has at least one link
     * and all its links have points. When a link is being
     * updated its points are removed. This is meant to be
     * used in "onRouteUpdated".
     */
    isComplete : function () {
        var complete = this.Links.length > 0;
        for(var i = 0; i < this.Links.length; i++) {
            complete &= this.Links[i].points !== undefined;
        }
        return complete;
    },

    /*
     * returns the routing errors if any.
     */
    getRoutingErrors : function () {
        var error = [];
        for(var i = 0; i < this.Links.length; i++) {
            if (this.Links[i].RoutingError !== undefined) {
                error += this.Links[i].RoutingError;
            }
        }
        return error;
    },

    triggerRouteUpdated : function () {
        console.log("triggerRouteUpdated");
        if (this.onRouteUpdated) {
            this.onRouteUpdated(this);
        }
    },

    linkUpdated : function (link) {
        console.log("linkUpdated");
        this.draw();
        this.triggerRouteUpdated();
    },

    CLASS_NAME : "BusPass.Route"
});

BusPass.Route.Link = OpenLayers.Class({

    route : null,

    startWaypoint : null,

    endWaypoint : null,

    onLinkUpdated : function (link) {
        this.route.linkUpdated(this.route, this);
    },

    initialize : function (options) {
        OpenLayers.Util.extend(this, options);
        if (this.scope == null) {
            this.scope = this;
        }
        var ctrl = this;
        if (this.startWaypoint) {
            this.startWaypoint.forwardLink = this;
        }
        if (this.endWaypoint) {
            this.endWaypoint.backLink = this;
        }
        if (this.lineString) {
            if (this.startWaypoint && this.endWaypoint) {
                this.connectEndpoints();
            } else {
                this.points = this.lineString.geometry.components;
                this.startWaypoint = new BusPass.Route.Waypoint({
                    route : this.route,
                    lonlat : new OpenLayers.LonLat(this.points[0].x, this.points[0].y),
                    forwardLink : this
                });
                this.endWaypoint =  new BusPass.Route.Waypoint({
                    route : this.route,
                    lonlat : new OpenLayers.LonLat(this.points[this.points.length - 1].x,
                        this.points[this.points.length - 1].y),
                    backLink : this
                });
                this.connectEndpoints();
            }
        }
    },

    startWaypointUpdated : function (link, wp) {
        this.launchGetRoute(
            function (link) {
                if (!link.isDestroyed()) {
                    link.triggerUpdate();
                }
            },
            function (self, jqXHR, textStatus, errorThrown) {

            }
        );
    },

    endWaypointUpdated : function (link, wp) {
        this.launchGetRoute(
            function (link) {
                if (!link.isDestroyed()) {
                    link.triggerUpdate();
                }
            },
            function (self, jqXHR, textStatus, errorThrown) {

            }
        );
    },

    reroute : function (draw) {
        this.launchGetRoute(function (link) {
            if (!link.isDestroyed()) {
                link.triggerUpdate();
            }
        });
    },

    points : [],

    lineString : null,

    triggerUpdate : function () {
        if (this.onLinkUpdated) {
            this.onLinkUpdated(this);
        }
    },

    /**
     * Returns true if this Link has been destroyed. Useful in
     * Ajax callbacks. This call is only valid after the Link
     * has been properly initialized. That means it is still
     * associated with a route.
     * @return {Boolean}
     */
    isDestroyed : function () {
        return !this.route;
    },

    connectEndpoints : function () {
        var points = this.lineString.geometry.components;
        var start = this.startWaypoint.lonlat;
        var finish = this.endWaypoint.lonlat;
        var startPoint = new OpenLayers.Geometry.Point(start.lon, start.lat);
        var endPoint = new OpenLayers.Geometry.Point(finish.lon, finish.lat);

        if (startPoint.distanceTo(points[0]) != 0) {
            this.lineString.geometry.addComponent(startPoint, 0);
        }
        points = this.lineString.geometry.components;
        if (points.length == 1 || endPoint.distanceTo(points[points.length-1]) != 0) {
            this.lineString.geometry.addComponent(endPoint);
        }
        this.points = this.lineString.geometry.components;
    },

    launchGetRoute : function (returnCallback, errorCallback) {
        var self = this;
        if (!self.startWaypoint || !self.endWaypoint) {
            alert("bad call on BusPass.Route.Link.launchGetRoute");
        }
        this.RoutingError = undefined;
        if (this.points) {
            this.points = undefined;
        }
        if (self.startWaypoint.lonlat && self.endWaypoint.lonlat) {
            if (!self.route.autoroute) {
                var lineString = new OpenLayers.Feature.Vector(
                    new OpenLayers.Geometry.LineString(
                        [self.startWaypoint.lonlat, self.endWaypoint.lonlat]
                ));
                self.route.RouteLayer.removeFeatures(self.lineString);
                self.lineString = lineString;
                self.points = self.lineString.geometry.components;
                if (returnCallback !== undefined) {
                    returnCallback(self);
                }
                return;
            }
            self.route.RouteApi.getRoute(self.startWaypoint.lonlat, self.endWaypoint.lonlat,
                function (xml) {
                    try {
                        // Since this is an Ajax return, this link may have already been
                        // destroyed. If it doesn't have a route, it's gone. We will
                        // still maintain callback integrity, but the callback should
                        // notice.
                        if (!self.isDestroyed()){
                            var features = self.route.parseKMLToFeatures(xml);
                            if (features) {
                                self.route.RouteLayer.removeFeatures(self.lineString);
                                // LineString *should* be the first one and it should be a OL.Feature.Vector.
                                self.lineString = features[0];
                                self.connectEndpoints();
                            }
                        }
                    } catch (err) {
                        console.log("Route Error: bad line string.");
                        self.RoutingError = err;
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
        }
    },

    erase : function () {
        if (this.lineString) {
            this.route.RouteLayer.removeFeatures(this.lineString);
        }
    },

    draw : function () {
        if (this.route.RouteLayer !== undefined && this.lineString) {
            this.route.RouteLayer.addFeatures(this.lineString);
        }
    },

    destroy : function () {
        if (this.lineString) {
            this.route.RouteLayer.removeFeatures(this.lineString);
            this.lineString = undefined;
        }
        // Due to Joins we may have already changed the
        // forward/back links on the Waypoints. We only nullify
        // the waypoint forward/back links if they are still pointing
        // to this one.
        if (this.startWaypoint && this.startWaypoint.forwardLink == this) {
            this.startWaypoint.forwardLink = undefined;
        }
        if (this.endWaypoint && this.endWaypoint.backLink == this) {
            this.endWaypoint.backLink = undefined;
        }
        this.startWaypoint = undefined;
        this.endWaypoint = undefined;
        this.route = undefined;
        this.points = undefined;
    }
});

BusPass.Route.Waypoint = OpenLayers.Class({

    route : null,

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
    },

    onWaypointUpdated : function(wp) {
    },

    backLink : undefined,

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
                this.route.MarkersLayer.removeFeatures([this.marker]);
                this.marker.destroy();
            }

            /* Create a marker and add it to the marker layer */
            this.marker = new OpenLayers.Feature.Vector(
                new OpenLayers.Geometry.Point(this.lonlat.lon, this.lonlat.lat),
                {
                    waypoint: this,
                    image: this.markerUrl()
                });
            this.marker.geometry._vertex = this;

            this.route.MarkersLayer.addFeatures([this.marker]);
        }
    },

    destroy : function() {
        if (this.marker !== undefined) {
            this.route.MarkersLayer.removeFeatures(this.marker);
            this.marker.destroy();
            this.marker = undefined;
            this.lonlat = undefined;
            this.backLink = undefined;
            this.forwardLink = undefined;
        }
    },

    triggerUpdate : function (result) {
        if (this.backLink) {
            this.backLink.endWaypointUpdated(this.backLink, this);
        }
        if (this.forwardLink) {
            this.forwardLink.startWaypointUpdated(this.forwardLink, this);
        }
        if (this.onWaypointUpdated !== undefined) {
            this.onWaypointUpdated(this);
        }
    },

    updateLonLat : function (lonlat) {
        this.lonlat = lonlat;
        this.triggerUpdate();
    },

    CLASS_NAME : "BusPass.Route.Waypoint"
});

BusPass.Route.Api = OpenLayers.Class({

    apiUrl : "/transport.php?url=http://www.yournavigation.org/api/dev/route.php?",

    /**
     * Property: Yours.Route.parameters.fast
     * Method for route calculation
     *
     * 0 - shortest route
     * 1 - fastest route (default)
     */
    fast: '0',

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

    mapProjection : null,

    apiProjection : null,

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

        flonlat = flonlat.clone().transform(this.mapProjection, this.apiProjection);
        tlonlat = tlonlat.clone().transform(this.mapProjection, this.apiProjection);

        var search = 'flat=' + flonlat.lat +
            '&flon=' + flonlat.lon +
            '&tlat=' + tlonlat.lat +
            '&tlon=' + tlonlat.lon;
           search += '&v=' + this.type +
            '&fast=' + this.fast +
            '&layer=' + this.layer;
        var xml = self.routeCache[search];
        if (xml === undefined) {
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
