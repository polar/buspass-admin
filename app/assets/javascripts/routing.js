
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
        var data = [];
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

    /**
     * Returns the actual points making up the lineStrings. That is so, if we
     * manipulate them with ModifyFeature Control we manipulate the drawing.
     * @return {*}
     */
    createModifyComponents : function () {
        var data = [];
        var last_wp = null;
        for(var i = 0; i < this.Links.length; i++) {
            var link = this.Links[i];
            if (link.lineString !== undefined) {
                // Each linestring should contain the Waypoint geometry.
                // We don't include the last point in each link until the end
                // since the beginning of one link is the end of the last.
                for (var j = 0; j < link.points.length-1; j++) {
                    var point = link.lineString.geometry.components[j];
                    data.push(point);
                }
            } else {
                return;
            }
            // Add the last point.
            if (i == this.Links.length - 1) {
                data.push(link.endWaypoint.geometry);
            }
        }
        return data;
    },

    createWaypointModifyLineString : function () {
        var points = this.createModifyComponents();
        var geometry = new OpenLayers.Geometry.LineString(points);
        var lineString = new OpenLayers.Feature.Vector(geometry);
        return lineString;
    },

    createLineString : function () {
        var points = this.getPoints();
        var geometry = new OpenLayers.Geometry.LineString(points);
        var lineString = new OpenLayers.Feature.Vector(geometry);
        return lineString;
    },

    createLineStringFromTo : function (from, to) {
        var points = [];
        var inbetween = false;
        for(var i = 0; i < this.Links.length; i++) {
            var link = this.Links[i];
            if (inbetween || link.startWaypoint == from) {
                inbetween = true;
                var pts = link.getPoints();
                // Avoid duplication with the start point in the next link..
                for (var j = 0; j < pts.length-1; j++) {
                    points.push(pts[j]);
                }
            }
            if (link.endWaypoint == to) {
                // Add the last endpoint
                points.push(link.endWaypoint.geometry);
                var geometry = new OpenLayers.Geometry.LineString(points);
                var lineString = new OpenLayers.Feature.Vector(geometry);
                return lineString;
            }
        }
        throw "Bad Args";
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
    insertWaypoint : function (index, wp, reroute, onCompleteCB, onErrorCB) {
        if (this.Waypoints.length == 0) {
            index = 0;
        }
        // Install at last position if index isn't a number
        // Ex: insertWaypoint("last", wp);
        if (isNaN(index)) {
            switch (index) {
                case "start" :
                    index = 0;
                    break;
                default:
                    index = this.Waypoints.length;
                    break;
            }
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
        // index == wp.position
        if (wp.position == 0) {
            // WP inserted at beginning,
            // Insert new Link at beginning if a link exists
            // or if there is now 2 Waypoints, create first link.
            if (this.Links.length > 0) {
                var link = new BusPass.Route.Link({
                    route : this,
                    startWaypoint : wp,
                    endWaypoint : this.Links[0].startWaypoint
                });
                this.Links.splice(0,0,link);
            } else {
                if (this.Waypoints.length > 1) {
                    var link = new BusPass.Route.Link({
                        route : this,
                        startWaypoint : wp,
                        endWaypoint : this.Waypoints[1]
                    });
                    this.Links.push(link);
                }
            }
        }
        else {
            if (wp.position == this.Waypoints.length-1) {
                // WP added at end
                // Insert new link at end if link exists
                // or there are now 2 waypoints, create first link.
                if (this.Links.length > 0) {
                    var link = new BusPass.Route.Link({
                        route : this,
                        startWaypoint : this.Links[this.Links.length-1].endWaypoint,
                        endWaypoint : wp
                    });
                    this.Links.push(link);
                } else {
                    if (this.Waypoints.length > 1) {
                        var link = new BusPass.Route.Link({
                            route : this,
                            startWaypoint : this.Waypoints[0],
                            endWaypoint : wp
                        });
                        this.Links.push(link);
                    }
                }
            }
            else {
                // Remove the link and replace with 2 from the split
                var link = this.Links[index-1];
                if (!wp.lonlat) {
                    if (link.lineString) {
                        wp.setLonLat(link.getMidpoint());
                        // Make sure it has a marker geometry that can be moved around.
                    }
                }
                var links = this.splitLinkToLinks(link, wp);
                this.Links.splice(index-1,1,links[0],links[1]);
                link.destroy();
            }
        }
        wp.draw();
        wp.drawValidLinks();
        if (reroute) {
            wp.updateValidLinks(onCompleteCB, onErrorCB);
        } else {
            if (onCompleteCB) {
                onCompleteCB(wp);
            }
        }
        return wp;
    },

    removeWaypoint:function (id, reroute, onCompleteCB, onErrorCB) {
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
        console.log("RemoveWaypoint wp " + index + " of " + this.Waypoints.length + "/" + this.Links.length + " at " + wp.backLink + " forward " + wp.forwardLink);
        this.Waypoints.splice(index, 1);
        this._updateWaypointsState();
        var linkToBeRerouted = undefined;
        if (wp.backLink && wp.forwardLink) {
            var link1 = this.Links[index - 1];
            if (wp.backLink != link1) {
                console.log("RemoveWaypoint : inconsistent back link");
            }
            var link2 = this.Links[index];
            if (wp.forwardLink != link2) {
                console.log("RemoveWaypoint : inconsistent forward link");
            }
            var link = this.joinLinksToLink(link1, link2);
            this.Links.splice(index - 1, 2, link);
            link1.destroy();
            link2.destroy();
            linkToBeRerouted = link;
        } else {
            // Destroying the first or last Waypoint.
            if (wp.backLink) {
                // This is the last Waypoint, remove last link.
                wp.backLink.destroy();
                this.Links.splice(index-1, 1);
            }  else  if (wp.forwardLink) {
                // This is the first Waypoint, remove first link.
                wp.forwardLink.destroy();
                this.Links.splice(0,1);
            } else {
                alert("Bad Waypoint delete");
            }
        }
        wp.destroy();
        if (reroute && linkToBeRerouted) {
            linkToBeRerouted.reroute(onCompleteCB, onErrorCB);
        }
    },

    appendNewWaypoint : function (lonlat, lineString) {
        if (this.Waypoints.length > 0) {
            var last = this.getWaypoint("end");
            var wp = this.newWaypoint({ lonlat : lonlat});
            this.Waypoints.push(wp);
            var link = new BusPass.Route.Link({
                route : this,
                startWaypoint : last,
                endWaypoint : wp,
                lineString : lineString
            });
            this.Links.push(link);
            this._updateWaypointsState();
            return wp;
        } else {
            var wp = this.newWaypoint({ lonlat : lonlat});
            this.Waypoints.push(wp);
            this._updateWaypointsState();
            return wp;
        }
    },

    _updateWaypointsState : function () {
        // If we have a selected waypoint and we don't find it, we get rid of the current selection.
        var keepSelected = this.SelectedWaypoint === undefined;
        // If we specifically set the waypoint type to "other", we leave it, unless it's start or end.
        for (var i = 0; i < this.Waypoints.length; i++) {
            var wp = this.Waypoints[i];
            keepSelected = keepSelected || wp == this.SelectedWaypoint
            wp.type = i == 0 ? "start" : (i == this.Waypoints.length-1 ? "end" : (wp.type == "other" ? "other" : "via"));
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

    applyLineString1 : function (lineString) {
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
            while(index < components.length && components[index]._vertex != link.endWaypoint) {
                var point = components[index];
                points.push(point);
                index += 1;
            }
            if (index == components.length) {
                console.log("applylinestring1: ran out of points.");
            } else {
                points.push(components[index]);
            }
            link.lineString = new OpenLayers.Feature.Vector(
                new OpenLayers.Geometry.LineString(points));
            link.connectEndpoints();
            link.points = link.lineString.geometry.components;
            collected += points.length;
        }
    },

    reroute : function (onCompleteCB, onErrorCB) {
        var returns = [];
        var nreturns = 0;
        var nlinks = this.Links.length;
        var route = this;

        if (nlinks == 0) {
            if (onCompleteCB) {
                onCompleteCB(route);
                return;
            }
        }

        function linkReroute(link) {
            returns[link.position] = "ok";
            nreturns += 1;
            if (nreturns == nlinks) {
                for(var i = 0; i < nlinks; i ++) {
                    if (returns[i] != "ok") {
                        if (onCompleteCB) {
                            onCompleteCB(route);
                        }
                        return;
                    }
                }
                if (onErrorCB) {
                    onErrorCB(route);
                }
            }
        }
        function linkError(link) {
            returns[link.position] = "error";
            nreturns += 1;
            if (nreturns == nlinks) {
                for (var i = 0; i < nlinks; i++) {
                    if (returns[i] != "ok") {
                        if (onCompleteCB) {
                            onCompleteCB(route);
                        }
                        return;
                    }
                }
                if (onErrorCB) {
                    onErrorCB(route);
                }
            }
        }
        for(var i = 0; i < this.Links.length; i++) {
            var link = this.Links[i];
            link.update(linkReroute, linkError);
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
        if (id !== undefined &&
            id.CLASS_NAME &&
            id.CLASS_NAME == "BusPass.Route.Waypoint" &&
            id == this.Waypoints[id.position]) {
            this.SelectedWaypoint = id;
        } else {
            var index = 0;
            switch(id) {
                case "start":
                    index = 0;
                    break;
                case "end":
                case "last":
                    index = this.Waypoints.length - 1;
                    break;
                default:
                    index = id;
            }
            console.log("Selected Waypoint " + index);
            if (id === undefined || isNaN(index)) {
                this.SelectedWaypoint = undefined;
            } else {
                this.SelectedWaypoint = this.Waypoints[index];
            }
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
            console.log("Cursor should be set " + this.SelectedWaypoint.position);
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

    redrawWaypoints : function() {
        for (var i = 0; i < this.Waypoints.length; i++) {
            this.Waypoints[i].draw();
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
            complete &= this.Links[i].startWaypoint.lonlat != null;
            complete &= this.Links[i].endWaypoint.lonlat != null;
            complete &= this.Links[i].PendingRoute === undefined;
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

    reverse : function() {
        this.Links = this.Links.reverse();
        this.Waypoints = this.Waypoints.reverse();
        for(var i = 0; i < this.Links.length; i++) {
            this.Links[i].reverse();
        }
        if (this.Waypoints[0]) {
            this.Waypoints[0].type = "start";
            this.Waypoints[0].backLink = null;
            this.Waypoints[this.Waypoints.length - 1].forwardLink = null;
        }
        if (this.Waypoints.length > 1) {
            this.Waypoints[this.Waypoints.length-1].type = "end";
        }
        for(var i = 0; i < this.Waypoints.length; i++) {
            this.Waypoints[i].position = i;
        }
    },

    /**
     * This function may be used after a modify control may have deleted some
     * geometry components that we need to keep next to the way points.
     */
    connectLinkEndpoints : function () {
        for(var i = 0; i < this.Links.length; i++) {
            this.Links[i].connectEndpoints();
        }
    },

    CLASS_NAME : "BusPass.Route"
});

BusPass.Route.Link = OpenLayers.Class({

    route : null,

    startWaypoint : null,

    endWaypoint : null,

    autodraw : true,

    onLinkUpdated : function (link) {
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
        } else {
            this.lineString = new OpenLayers.Feature.Vector(
                new OpenLayers.Geometry.LineString([
                    this.startWaypoint.geometry,
                    this.endWaypoint.geometry])
            );
            this.connectEndpoints();
        }
    },

    /**
     * A link is valid if both it's waypoints have their lonlat set.
     * We can have "phantom" waypoints that are merely geometry holders
     * waiting to be set. Also links may have their lonlat's set, but there geometry is
     * different due to a drag. Still a valid structured link.
     */
    isValid : function () {
        return this.startWaypoint && this.startWaypoint.isLonLatSet() &&
            this.endWaypoint && this.endWaypoint.isLonLatSet();
    },

    reverse : function() {
        var x = this.startWaypoint;
        this.startWaypoint = this.endWaypoint;
        this.endWaypoint = x;
        if (this.startWaypoint) {
            this.startWaypoint.forwardLink = this;
        }
        if (this.endWaypoint) {
            this.endWaypoint.backLink = this;
        }
        if (this.lineString) {
            this.lineString.geometry.components = this.lineString.geometry.components.reverse();
            this.points = this.lineString.geometry.components;
        }
    },

    startWaypointUpdated : function (link, wp, completeCallback, errorCallback) {
        this.connectEndpoints();
        if (this.route.autoroute) {
            this.launchGetRoute(
                function (link) {
                    if (!link.isDestroyed()) {
                        link.onLinkUpdated(link);
                    }
                    if (completeCallback){
                        completeCallback(link, wp);
                    }
                },
                function (self, jqXHR, textStatus, errorThrown) {
                    if (errorCallback) {
                        errorCallback.call(self, jqXHR, textStatus, errorThrown);
                    }
                }
            );
        } else {
            if (completeCallback){
                completeCallback(link, wp);
            }
        }
    },

    endWaypointUpdated : function (link, wp, completeCallback, errorCallback) {
        this.connectEndpoints();
        if (this.route.autoroute) {
            this.launchGetRoute(
                function (link) {
                    if (!link.isDestroyed()) {
                        link.onLinkUpdated(link);
                    }
                    if (completeCallback) {
                        completeCallback(link, wp);
                    }
                },
                function (self, jqXHR, textStatus, errorThrown) {
                    if (errorCallback) {
                        errorCallback.call(self, jqXHR, textStatus, errorThrown);
                    }
                }
            );
        } else {
            if (completeCallback) {
                completeCallback(link,wp);
            }
        }
    },

    reroute : function (draw) {
        this.launchGetRoute(function (link) {
            if (!link.isDestroyed()) {
                link.triggerUpdate();
            }
        });
    },

    update : function (onCompleteCB, onErrorCB) {
        if (this.isValid()) {
            this.connectEndpoints();
            if (this.route.autoroute) {
                function completeCB(link) {
                    if (link.autodraw) {
                        link.draw();
                    }
                    if (onCompleteCB) {
                        onCompleteCB(link);
                    }
                }

                function errorCB(link) {
                    if (link.autodraw) {
                        link.draw();
                    }
                    if (onErrorCB) {
                        onErrorCB(link);
                    }
                }
                this.launchGetRoute(completeCB, errorCB);
            } else {
                if (onCompleteCB) {
                    onCompleteCB(this);
                }
            }
        } else {
            if (onCompleteCB) {
                onCompleteCB(this);
            }
        }
    },

    points : [],

    lineString : null,

    linkUpdated : function () {
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
        var start = this.startWaypoint.geometry;
        var finish = this.endWaypoint.geometry;
        var startPoint = new OpenLayers.Geometry.Point(start.lon, start.lat);
        var endPoint = new OpenLayers.Geometry.Point(finish.lon, finish.lat);

        if (points[0] !== start) {
            this.lineString.geometry.addComponent(start, 0);
        }
        points = this.lineString.geometry.components;
        if (points.length == 1 || points[points.length-1] !== finish) {
            this.lineString.geometry.addComponent(finish);
        }
        this.points = this.lineString.geometry.components;
    },

    getPoints : function () {
        return this.lineString.geometry.components;
    },

    reset : function () {
        if (this.lineString) {
            this.route.RouteLayer.removeFeatures(this.lineString);
        }
        var lineString = new OpenLayers.Feature.Vector(
            new OpenLayers.Geometry.LineString(
                [this.startWaypoint.geometry, this.endWaypoint.geometry]
            ));
        this.lineString = lineString;
        this.points = this.lineString.geometry.components;
    },

    launchGetRoute : function (returnCallback, errorCallback) {
        var link = this;
        if (!link.startWaypoint || !link.endWaypoint) {
            var name1 = link.startWaypoint ? link.startWaypoint.name : "no start";
            var name2 = link.endWaypoint ? link.endWaypoint.name : "no end";
            alert("bad call on BusPass.Route.Link.launchGetRoute " + name1 + " -> " + name2);
            if (errorCallback !== undefined) {
                errorCallback(link);
            }
            return;
        }
        this.RoutingError = undefined;
        if (this.points) {
            this.points = undefined;
        }
        if (link.startWaypoint.lonlat && link.endWaypoint.lonlat) {
            if (!link.route.autoroute) {
                link.reset();
                if (returnCallback !== undefined) {
                    returnCallback(link);
                }
                return;
            }
            link.PendingRoute = true;
            link.route.RouteApi.getRoute(link.startWaypoint.lonlat, link.endWaypoint.lonlat,
                function (xml) {
                    delete link.PendingRoute;
                    try {
                        // Since this is an Ajax return, this link may have already been
                        // destroyed. If it doesn't have a route, it's gone. We will
                        // still maintain callback integrity, but the callback should
                        // notice.
                        if (!link.isDestroyed()){
                            var features = link.route.parseKMLToFeatures(xml);
                            if (features) {
                                link.route.RouteLayer.removeFeatures(link.lineString);
                                // LineString *should* be the first one and it should be a OL.Feature.Vector.
                                link.lineString = features[0];
                                link.connectEndpoints();
                            }
                        }
                    } catch (err) {
                        console.log("Route Error: bad line string.");
                        link.RoutingError = err;
                    }
                    if (returnCallback !== undefined) {
                        returnCallback(link);
                    }
                },
                function(jqXHR, textStatus, errorThrown) {
                    delete link.PendingRoute;
                    if (errorCallback !== undefined) {
                        errorCallback(link, jqXHR, textStatus, errorThrown);
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

    getMidpoint : function () {
        if (this.lineString) {
            var components = this.lineString.geometry.components;
            var distance = this.lineString.geometry.getLength();
            var current_dist = 0;
            var last = components[0];
            for(var i = 1; i < components.length; i++) {
                var dist = last.distanceTo(components[i]);
                if (current_dist < distance/2.0 && distance/2.0 < current_dist + dist) {
                    return new OpenLayers.LonLat((last.x + components[i].x)/2.0,(last.y + components[i].y)/2.0);
                } else {
                    last = components[i];
                    current_dist += dist;
                }
            }
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

    autodraw : true,

    markerUrl : function() {
        switch (this.type) {
            case 'via':
                return '/assets/yours/markers/number' + this.position + '.png';
            case 'start':
                return '/assets/yours/markers/route-start.png';
            case 'end':
                return '/assets/yours/markers/route-stop.png';
            default:
                return '/assets/yours/markers/yellow.png';
        }
    },

    onLinksGeometryUpdated : function(wp) {
    },

    backLink : undefined,

    forwardLink : undefined,

    type : "",

    position : null,

    geometry : null,

    setLonLat : function (lonlat) {
        this.lonlat  = lonlat.clone();
        this.geometry.x = lonlat.lon;
        this.geometry.y = lonlat.lat;

        if (this.autodraw) {
            this.draw();
        }
    },

    isLonLatSet : function () {
        return this.lonlat !== undefined;
    },

    /**
     * A waypoint is valid, if it has it's lonlat set and the geometry is the same location
     */
    isValid : function () {
        return this.isLonLatSet() && this.isCurrentLonLat(this.lonlat);
    },

    /**
     * Effectively moves the Waypoint back to where it was. Certain controls (Drag) might move the waypoint
     * Geometry. We reset to the last setLonLat();
     */
    resetGeometry : function () {
        if (this.lonlat) {
            this.geometry.x = this.lonlat.lon;
            this.geometry.y = this.lonlat.lat;

            if (this.autodraw) {
               this.draw();
            }
        }
    },

    /**
     * Returns the LonLat location in the Map's projection according to the current Geometry..
     *
     * @return {OpenLayers.LonLat}
     */
    getGeometryLonLat : function () {
        if (this.geometry) {
            return new OpenLayers.LonLat(this.geometry.x, this.geometry.y);
        }
        return undefined;
    },

    hasLink : function () {
        return this.backLink || this.forwardLink ;
    },

    hasValidLinks : function () {
        return (!this.backLink || this.backLink.isValid()) && (!this.forwardLink || this.forwardLink.isValid());
    },

    /**
     * Returns true if and only if the Waypoint has a geometry (point set) and it has
     * the same location.
     *
     * @param lonlat
     * @return {Boolean}
     */
    isCurrentLonLat : function (lonlat) {
        if (this.lonlat && lonlat) {
            return this.geometry && this.geometry.x == lonlat.lon && this.geometry.y == lonlat.lat;
        } else {
            return false;
        }
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
        console.log("Waypoint.initialize(geometry=" + this.geometry);
        if (!this.geometry) {
            this.geometry =  new OpenLayers.Geometry.Point(0,0);
            console.log("Waypoint.initialize(new geometry=" + this.geometry);
            console.log("Waypoint.initialize(geometry.bounds=" + this.geometry.bounds);
            this.geometry._vertex = this;
        }
        if (this.lonlat) {
            this.setLonLat(this.lonlat);
        }
    },

    /*
     * Function: draw
     *
     * Draw a Waypoint on the Vector Layer. If no lonlat is available, the
     * Waypoint will not be drawn.
     */
    draw : function() {
        if (this.geometry !== undefined) {
            // Delete old marker, if available. It's label may have changed.
            // We keep the same geometry.
            if (this.marker !== undefined) {
                this.route.MarkersLayer.removeFeatures([this.marker]);
                // we need to reset the bounds because they might be 0,0,0,0 if
                // there wasn't an image before.
                this.geometry.bounds = null;
                this.marker.destroy();
                this.marker = undefined;
            }
            if (this.marker === undefined) {
                // Create a marker and add it to the marker layer using the same geometry.
                // This allows us the map to move the waypoint during dragging.
                //
                this.marker = new OpenLayers.Feature.Vector(
                    this.geometry,
                    {
                        waypoint: this,
                        image: this.markerUrl()
                    });

                this.route.MarkersLayer.addFeatures([this.marker]);
            }
        }
    },

    drawValidLinks : function () {
        if (this.backLink && this.backLink.isValid()) {
            this.backLink.draw();
        }
        if (this.forwardLink && this.forwardLink.isValid()) {
            this.forwardLink.draw();
        }
    },

    destroy : function() {
        if (this.marker !== undefined) {
            this.route.MarkersLayer.removeFeatures(this.marker);
            this.geometry = undefined;
            this.marker.destroy();
            this.marker = undefined;
            this.backLink = undefined;
            this.forwardLink = undefined;
        }
    },

    updateValidLinks : function (onCompleteCB, onErrorCB) {
        var backreturned = true;
        var forwreturned = true;
        var waypoint = this;

        function completeBacklink() {
            backreturned = true;
            if (forwreturned && forwreturned != "error") {
                if (onCompleteCB) {
                    onCompleteCB(waypoint);
                    if (waypoint.onLinksGeometryUpdated !== undefined) {
                        waypoint.onLinksGeometryUpdated(this);
                    }
                }
                if (waypoint.autodraw) {
                    waypoint.drawValidLinks();
                }
            } else {
                if (onErrorCB) {
                    onErrorCB(waypoint);
                }
                if (waypoint.autodraw) {
                    waypoint.drawValidLinks();
                }
            }
        }
        function completeForwardLink() {
            forwreturned = true;
            if (backreturned && backreturned != "error") {
                if (onCompleteCB) {
                    onCompleteCB(waypoint);
                    if (waypoint.onLinksGeometryUpdated !== undefined) {
                        waypoint.onLinksGeometryUpdated(this);
                    }
                }
                if (waypoint.autodraw) {
                    waypoint.drawValidLinks();
                }
            } else {
                if (onErrorCB) {
                    onErrorCB(waypoint);
                    if (waypoint.onLinksGeometryUpdated !== undefined) {
                        waypoint.onLinksGeometryUpdated(this);
                    }
                }
                if (waypoint.autodraw) {
                    waypoint.drawValidLinks();
                }
            }
        }
        function errorBacklink() {
            backreturned = "error";
            if (!forwreturned) {
                if (onErrorCB) {
                    onErrorCB(waypoint);
                    if (waypoint.onLinksGeometryUpdated !== undefined) {
                        waypoint.onLinksGeometryUpdated(this);
                    }
                }
                if (waypoint.autodraw) {
                    waypoint.drawValidLinks();
                }
            }
        }
        function errorForwardlink() {
            forwreturned = "error";
            if (!backreturned) {
                if (onErrorCB) {
                    onErrorCB(waypoint);
                    if (waypoint.onLinksGeometryUpdated !== undefined) {
                        waypoint.onLinksGeometryUpdated(this);
                    }
                }
                if (waypoint.autodraw) {
                    waypoint.drawValidLinks();
                }
            }
        }
        var calls_made = false;
        if (this.backLink && this.backLink.isValid()) {
            backreturned = false;
            calls_made = true;
            this.backLink.endWaypointUpdated(this.backLink, this, completeBacklink, errorBacklink);
        }
        if (this.forwardLink && this.forwardLink.isValid()) {
            forwreturned = false;
            calls_made = true;
            this.forwardLink.startWaypointUpdated(this.forwardLink, this, completeForwardLink, errorBacklink);
        }
        if (!calls_made) {
            if (onCompleteCB) {
                onCompleteCB(waypoint);
            }
        }
    },

    updateLonLat : function (lonlat, doDraw,  completeCB, errorCB) {
        this.setLonLat(lonlat);
        if (doDraw) {
            this.draw();
        }
        this.updateValidLinks(completeCB, errorCB);
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
