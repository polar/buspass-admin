/**
 * StopPointsController
 *
 *= require ModifyFeature
 *= require StopPointModifyFeatureControl
 *= require routing
 *= require NameFinder
 *= require_self
 */
var ESCAPE_KEYCODE = 27;

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

    /**
     * Returns the current LonLat location of the StopPoint based on its Waypoint geometry,
     * which could have moved from the set value (during a drag).
     */
    getLonLat : function () {
        return this.Waypoint.getGeometryLonLat();
    },

    /**
     * Sets the Waypoint for this StopPoint. It does not affect the geometry of the Waypoint
     * even if the StopPoint lonlat is set.
     * @param wp
     */

    setWaypoint : function (wp) {
        this.Waypoint = wp;
        this.Waypoint.StopPoint = this;
        this.Waypoint.markerUrl = function () {
            return this.StopPoint.markerUrl();
        }
    },

    /**
     * The markers distinguish among Start Stop and numbered in betweens.
     * @return {String}
     */
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


BusPass.StopPointsRoute = OpenLayers.Class(BusPass.Route, {

    /**
     * This function replaces the reroute function so that it only reroutes
     * the links that are not between locked StopPoints.
     *
     * @param onCompleteCB
     * @param onErrorCB
     */
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

        var links = this.Links;
        var rerouteLinks = [];
        var startStopPoint = links[0].startWaypoint.StopPoint; // It had better be a StopPoint.
        for(var i = 0; i < nlinks; i++) {
            // Find the next StopPoint
            var ilinks = [];
            var endStopPoint = null;
            for(var j = i; j < nlinks && ! endStopPoint; j++) {
                ilinks.push(links[j]);
                if (links[j].endWaypoint.StopPoint) {
                    endStopPoint = links[j].endWaypoint.StopPoint;
                }
            }
            if (startStopPoint && startStopPoint.Locked && endStopPoint && endStopPoint.Locked) {
                // We are between Locked StopPoints, so we ignore these links
                startStopPoint = endStopPoint;
                continue;
            }
            // We are between a Locked StopPoint and an Unlocked StopPoint. we reroute it.
            for(var k = 0; k < ilinks.length; k++) {
                rerouteLinks.push(ilinks[k]);
            }
            startStopPoint = endStopPoint;
        }

        function linkReroute(link) {
            returns[link.position] = "ok";
            nreturns += 1;
            if (nreturns == rerouteLinks.length) {
                for (var i = 0; i < rerouteLinks.length; i++) {
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
            if (nreturns == rerouteLinks.length) {
                for (var i = 0; i < rerouteLinks.length; i++) {
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

        if (rerouteLinks.length == 0) {
            if (onCompleteCB) {
                onCompleteCB(route);
                return;
            }
        }

        for (var i = 0; i < rerouteLinks.length; i++) {
            var link = rerouteLinks[i];
            link.update(linkReroute, linkError);
        }
    }
});

BusPass.StopPointsController = OpenLayers.Class({

    id : "map",

    minMapHeight:400, // pixels


    /**
     * Key Codes used to delete Waypoints from the map. Delete, Backspace
     */
    deleteCodes : [46, 68],

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

    /**
     * The NameFinder Object
     */
    nameFinder : null,

    auto_add_stoppoints : true,

    /**
     * Callback for when a StopPoint gets its location updated from the UI.
     * @param stop_point
     */
    onLocationUpdated : function (stop_point) { },

    /**
     * Callback for when the Route gets updated from the UI or route finders.
     * @param route
     */
    onRouteUpdated : function (route) { },

    /**
     * notice:
     *
     * UI Component
     *
     * Displays a message in the status box : #status
     * If type is "waiting" it will make the spinner visible.
     * If fade is true, messae will fade in 5 seconds.
     * Default type will fade.
     *
     * @param message {String}
     * @param type   ["waiting", "warning", "error", default]
     * @param fade   {Boolean}
     */
    notice : function (message, type, fade) {
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
            case 'success':
                $("#route_waiting").hide();
                message = '<span class="alert alert-success">' + message + '</span>';
                break;
            case 'info':
                $("#route_waiting").hide();
                message = '<span class="alert alert-info">' + message + '</span>';
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

    /**
     * The OpenLayers Map
     */
    Map : null,

    /**
     * A property for various OpenLayers controls.
     * ClickControl, ModifyFeatureControl, DragControl
     */
    Controls : null,

    /**
     * A layer for displaying the original route before editing.
     */
    BackLayer : null,

    /**
     * We have a marker layer so that the Makers remain on top, so lines don't
     * appear to run over them. Also, only allows selection of Waypoints.
     */
    MarkersLayer : null,

    /**
     * The layer on which we draw lines.
     */
    RouteLayer : null,

    /**
     * The layer on which we draw everything when we are modifying a route
     * with DrawLines.
     */
    ModifyLayer : null,


    /**
     * Constructor: BusPass.StopPointsController
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

        // Markers go on top. Modify gets used during Draw Lines
        this.Map.addLayers([this.BackLayer, this.RouteLayer, this.MarkersLayer]);

        this.Controls = {
            click: new BusPass.ClickLocationControl({
                onLocationClick : function(lonlat) {
                    ctrl.onMapClick(lonlat);
                }
            }),
            drag: new OpenLayers.Control.DragFeature(this.MarkersLayer, {
                onStart : function(feature, pixel) {
                    var wp = feature.attributes.waypoint;
                    if (wp !== undefined) {
                        // We don't start dragging if the stop point is locked or we are adding stop points.
                        if (wp.StopPoint && wp.StopPoint.Locked || ctrl.auto_add_stoppoints) {
                            ctrl.notice("Cannot Drag Locked StopPoint", "error");
                            return false;
                        }
                        // Grrr. We are not guaranteed a onComplete if the user only
                        // clicks and doesn't drag! So, we have to delay the reset of
                        // the links to the beginning of the drag if it happens.
                        this.StartDrag = true;
//                        // If we start dragging a StopPoint or Waypoint we reset the
//                        // attached links to straight lines.
//                        if (wp.backLink) {
//                            wp.backLink.reset();
//                            wp.backLink.draw();
//                        }
//                        if (wp.forwardLink) {
//                            wp.forwardLink.reset();
//                            wp.forwardLink.draw();
//                        }
                    }
                },
                onDrag : function(feature, pixel) {
                    var lonlat = new OpenLayers.LonLat(feature.geometry.x, feature.geometry.y);
                    var wp = feature.attributes.waypoint;
                    if (wp !== undefined) {
                        // We don't start dragging if the stop point is locked or we are adding stop points.
                        if (wp.StopPoint && wp.StopPoint.Locked || ctrl.auto_add_stoppoints) {
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
                    if (!feature.geometry) {
                        // For some reason, sometimes a feature doesn't have a geometry, which renders it
                        // useless to us.. We could just let the browser ignore, but will play nice.
                        return;
                    }

                    // The pixel coordinate represents the mouse pointer, which is not the center of the image,
                    // but the location where the user picked the image. Therefore, we use the geometry of the
                    // image, which is the actual image location (respecting any offsets defining its base)
                    var lonlat = new OpenLayers.LonLat(feature.geometry.x, feature.geometry.y);
                    var wp = feature.attributes.waypoint;
                    if (wp !== undefined) {
                        // We don't start dragging if the stop point is locked or we are adding stop points.
                        if (wp.StopPoint && wp.StopPoint.Locked || ctrl.auto_add_stoppoints) {
                            // It's geometry has been moved. Restore its original position
                            wp.resetGeometry();
                            wp.draw();
                            // Gets rid of error message for starting the drag.
                            ctrl.notice("");
                            return false;
                        }
                        if (ctrl.Route.autoroute) {
                            function clearNotice() {
                                ctrl.notice("Route Updated", "success", "fade");
                                var sp = wp.StopPoint;
                                // StopPoint may be undefined if just a waypoint.
                                if (sp) {
                                    ctrl.updateStopPointLocationUI(sp);
                                    ctrl.triggerOnLocationUpdated(sp);
                                }
                                ctrl.routeModified();
                            }
                            function errorNotice() {
                                ctrl.notice("Autoroute failed", "error", "fade");
                                ctrl.Route.draw();
                                var sp = wp.StopPoint;
                                // StopPoint may be undefined if just a waypoint.
                                if (sp) {
                                    ctrl.updateStopPointLocationUI(sp);
                                    ctrl.triggerOnLocationUpdated(sp);
                                }
                                ctrl.routeModified();
                            }
                            ctrl.notice("Calculating Route", "waiting");
                            wp.setLonLat(lonlat);
                            wp.drawValidLinks();
                            // TODO: Name this something else, since it actually tries to autoroute the link.
                            wp.updateValidLinks(clearNotice, errorNotice);
                        } else {
                            wp.setLonLat(lonlat);
                            wp.drawValidLinks();
                            wp.updateValidLinks(clearNotice, errorNotice);
                            var sp = wp.StopPoint;
                            // StopPoint may be undefined if just a waypoint.
                            if (sp) {
                                ctrl.updateStopPointLocationUI(sp);
                                ctrl.triggerOnLocationUpdated(sp);
                            }
                            ctrl.routeModified();
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
        // We'll turn it on when we are ready.
        this.Controls.click.deactivate();

        // Add control to handle mouse drags for moving markers
        this.Map.addControl(this.Controls.drag);
        this.Controls.drag.activate();
        // Add control to show which marker we point at
        this.Map.addControl(this.Controls.select);
        this.Controls.select.activate();

        // Add the Modify control for possible future use. We always want RESHAPE;
        this.Map.addControl(this.Controls.modify);
        this.Controls.modify.mode = OpenLayers.Control.ModifyFeature.RESHAPE;

        // This call may ask the browser for its location.
        this.initializeMapCenter();

        $("#add_stops").click(function () {
            console.log("Autoadd Stops Button " + $(this).hasClass("active"));
            ctrl.setAddStopPoints(!$(this).hasClass("active"));
        });
        $("#add_stops").popover({
            title:
                "When toggled you are adding Stops to the route. You may end this mode by toggling this button or hitting the ESC key."

        });

        $("#drawlines").click(function () {
            console.log("Draw Lines Button " + $(this).hasClass("active"));
            ctrl.setDrawLines(!$(this).hasClass("active"));
        });
        $("#drawlines").popover({
            title:"When toggled you may move individual points in the route regardless of streets. You may end this mode by toggling this button or hitting the ESC key."
        });

        $("#autoroute").click(function () {
            console.log("Auto Routes Button " + $(this).hasClass("active"));
            ctrl.setAutoRoute(!$(this).hasClass("active"));
        });
        $("#autoroute").popover({
            title:"When toggled every placement of a Stop or Intermediate Waypoint will discover a route through the streets. When toggled off, it connects with adjacent Stops or Waypoints using straight lines."
        });

        $("#route_waiting").hide();

        // Deal with the buttons that flip between names and locations.
        $("#show_names").click(function () {
            ctrl.show_names();
        });

        $("#show_locations").click(function () {
            ctrl.show_locations();
        });
        $("#show_names")[0].title = "Shows the names of the stops.";
        $("#show_locations")[0].title = "Shows the GPS locations of the stops."

        $("#clear_route").click(function () {
            ctrl.clearButton();
        });
        $("#clear_route")[0].title = "Clears the route.";

        $("#reverse_route").click(function () {
            ctrl.reverseButton();
        });
        $("#reverse_route").popover({
            title:"Reverses the route. However, it does not reroute. Caution. You may have draw down one way streets."
        });
        $("#revert").click(function () {
            ctrl.revertButton();
        });
        $("#revert")[0].title = "Reverts one back in the modification history.";

        $("#reroute").click(function () {
            ctrl.rerouteButton();
        });
        $("#reroute").popover({
            title:"Discovers new routes for all segments between <strong>Unlocked</strong> Stops."
        });

        $("#copybox_field").change(function () {
            if (ctrl.history.length == 0) {
                // We've never had a complete route
                var features = ctrl.initializeFromKMLString($(this).val());
                if (features !== false) {
                    var kml = ctrl.toKML();
                    ctrl.history.splice(0, 0, kml);
                    // Normalize.
                    ctrl.writeToCopyBox(kml);
                }
            }
            if (ctrl.Route.isComplete()) {
                var kml = ctrl.toKML();
                ctrl.history.splice(0,0,kml);
                var features = ctrl.initializeFromKMLString($(this).val());
                if (features === false) {
                    // It didn't work, so put the old one back.
                    ctrl.writeToCopyBox(this.history.splice(0,1));
                } else {
                    // Normalize.
                    var kml = ctrl.toKML();
                    ctrl.writeToCopyBox(kml);
                }
                // By inserting new elements we may have moved the map
                $("#map").height(Math.max(ctrl.minMapHeight, $("#navigation").height()));
            }
        });

        $("#refresh_kml").click(function () {
            ctrl.routeModified();
        });

        $("#copybox").popover({
            title: "You may input a KML string that was produced by this tool from an earlier file, if you want to modify a route."
        });

        this.show_names();

        this.RouteApi = new BusPass.Route.Api({
            mapProjection : this.Map.projection,
            apiProjection : this.Map.displayProjection
        });

        this.Route = new BusPass.StopPointsRoute({
            Map : this.Map,
            RouteApi : this.RouteApi,
            Controls : this.Controls,
            RouteLayer : this.RouteLayer,
            MarkersLayer : this.MarkersLayer,
            autoroute : true,
            onRouteUpdated : function (route) {
                ctrl.routeUpdated(route);
            }
        });

        // configure the keyboard handler so that we can get Waypoint deletes when
        // mouse is over waypoint and user hits a delete key.
        var keyboardOptions = {
            keydown: this.handleKeypress
        };

        this.handlers = {
            keyboard: new OpenLayers.Handler.Keyboard(this, keyboardOptions)
        };
        this.handlers.keyboard.activate();

        this.initializeFromOptions();
        this.setAutoRoute(true);
        this.setAddStopPoints(true, "dontadd");
        this.updateUI();

        // We want the UI to be aligned at the bottom with the map.
        $("#map").height(Math.max(this.minMapHeight, $("#navigation").height()));
        this.Map.updateSize();
        this.notice("Please click on the location of your first stop!", "info");
    },

    /**
     * This (re)initializes the whole controller with a KML file. If the KML is bad
     * a message is displayed. The string comes from the CopyBox.
     *
     * @param xmlString
     * @return {*}
     */
    initializeFromKMLString : function (xmlString) {
        var parser = new DOMParser();

        var xml = parser.parseFromString(xmlString, "text/xml");
        if (xml.documentElement.nodeName == "kml" && ! (xml.childNodes[0].firstChild.localName == "parsererror")) {
            var kml = new OpenLayers.Format.KML({
                externalProjection : this.Map.displayProjection,
                internalProjection : this.Map.projection
            });
            var features;
            function find(type, n) {
                for(var i = 0; i < features.length; i++) {
                    var feature = features[i];
                    if (feature.fid == (type + "_" + n) ||
                        feature.attributes.name && feature.attributes.name.startsWith(type+"_"+n)) {
                        // From Google Earth Folder
                        // We make the user name the Placemark with "sp_0:Street Name"
                        if (feature.attributes.name) {
                            if (feature.attributes.name.startsWith(type+"_"+n+":")) {
                                feature.attributes.Name = feature.attributes.name.split(":")[1].trim();
                            }
                        }

                        return feature;
                    }
                }
            }
            // Checks to make sure we have links between all stop points.
            function check() {
                var i = 0;
                var feature;
                while(feature = find("sp",i)) {
                    if (feature.geometry.CLASS_NAME != "OpenLayers.Geometry.Point") {
                        return false;
                    }
                    if (i > 0) {
                        feature = find("link", i-1);
                        if (!feature || feature.geometry.CLASS_NAME != "OpenLayers.Geometry.LineString") {
                            return false;
                        }
                    }
                    i++;
                }
                return true;
            }
            // Make sure we have everything, at least try.
            try {
                features = kml.read(xml);
                if (features && check()) {
                    this.Route.clear();
                    this.StopPoints = [];
                    $("#stop_points_list").html("");
                    var i = 0;
                    var feature;
                    while(feature = find("sp", i)) {
                        var lonlat = new OpenLayers.LonLat(feature.geometry.x, feature.geometry.y);
                        var name = feature.attributes.Name;
                        var lineString = undefined;
                        if (i > 0) {
                            var link = find("link", i-1);
                            if (link) {
                                lineString = link; // OpenLayers.Feature.Vector
                            }
                        }
                        // lineString may be undefined (first stop point)
                        this.appendNewStopPoint(name, lonlat, lineString);
                        i += 1;
                    }
                    // We update the UI first. That selects the numbered markers to draw on the map.
                    this.updateUI();
                    this.Route.draw();
                    this.Route.selectWaypoint();
                    console.log("parseKMLToFeatures: got features " + features.length);
                    // We want the UI to be aligned at the bottom with the map.
                    $("#map").height(Math.max(this.minMapHeight, $("#navigation").height()));
                    return features;
                } else {
                    this.notice("Illegal KML", "error", true);
                    return false;
                }
            } catch(e) {
                this.notice("Illegal KML", "error", true);
                alert("Illegal KML: " + e);
                return false;
            }
            return features;
        } else {
            this.notice("Not XML", "error", true);
            var xmls = new XMLSerializer();
            var err = xmls.serializeToString(xml.childNodes[0].lastChild);
            err = err.substring(err.length-100);
            alert("Illegal XML: " +xml.childNodes[0].firstChild.innerText + "\n" + err);
            return false;
        }
    },

    /**
     * This function is the onSelect callback function for the Select Control. We keep the selected
     * feature cached. This is necessary to handle the delete key presses.
     * @param feature
     */
    selectFeature : function (feature) {
        console.log("Selected Feature:");
        this.SelectedFeature = feature;
    },


    /**
     * Method: handleKeypress
     * Called by the feature handler on keypress.  This is used to delete
     *     Waypoints. If the <deleteCode> property is set, waypoints will
     *     be deleted.
     */
    handleKeypress: function(evt) {
        var ctrl = this;
        var code = evt.keyCode;

        if (code == ESCAPE_KEYCODE) {
            this.setAddStopPoints(false);
            this.setDrawLines(false);
        }

        // check for delete key
        if(this.SelectedFeature &&
            OpenLayers.Util.indexOf(this.deleteCodes, code) != -1) {
            var waypointMarker = this.Controls.drag.feature;
            if(waypointMarker && !this.Controls.drag.handlers.drag.dragging) {
                var wp = waypointMarker.attributes.waypoint;
                if (wp) {
                    var sp = wp.StopPoint;
                    if (sp) {
                        if (sp.Locked) {
                            this.notice("Cannot delete locked Stop", "error", "fade");
                        } else {
                            console.log("Delete: Stopoint " + sp.position + ", Waypoint "+ wp.position);
                            this.removeStopPoint(waypointMarker.attributes.waypoint.StopPoint,
                                this.autoroute,
                                function () {
                                    ctrl.notice("Route Updated", "success", "fade");
                                    ctrl.routeUpdated();
                                },
                                function () {
                                    ctrl.notice("Autoroute Failed", "error", "fade");
                                    ctrl.routeUpdated();
                                });
                            this.SelectedFeature = null;
                        }
                    } else {
                        console.log("Delete: Waypoint " + wp.position);
                        this.Route.removeWaypoint(waypointMarker.attributes.waypoint,
                            this.Controller.autoroute,
                            function () {
                                ctrl.notice("Route Updated", "success", "fade");
                                ctrl.routeUpdated();
                            },
                            function () {
                                ctrl.notice("Autoroute Failed", "error", "fade");
                                ctrl.routeUpdated();
                            });
                        this.SelectedFeature = null;
                    }
                }
            }
        }
    },

    /**
     * Selects a Stop Point, which means the Map cursor will be the marker image of the stop point.
     * It's mearly a delegation to the BusPass.Route on the waypoint.
     * @param sp
     */
    selectStopPoint : function (sp) {
        this.Route.selectWaypoint(sp.Waypoint);
    },


    /**
     * We just add two empty StopPoints and select the first one, and activate the ClickControl
     * so that the user can click them down.
     */
    initializeFromOptions : function () {
        this.appendStopPoint();
        this.appendStopPoint();
        this.selectStopPoint(this.StopPoints[0]);
        this.Controls.click.activate();
    },

    /**
     * This function updates the Name/Location UI of the StopPoint, based on its state.
     * @param stop_point
     */
    updateStopPointLocationUI : function (stop_point) {
        var ctrl = this;

        var lonlat = stop_point.getLonLat();
        if (lonlat) {
            lonlat.transform(this.Map.projection, this.Map.displayProjection);
            var sp_li = $(stop_point.viewElement);
            var loclit = "" + lonlat.lon.toFixed(6) + "," + lonlat.lat.toFixed(6);
            sp_li.find("[name='sp_location']").val(loclit);
            // We don't do this if the user set the name, or the location hasn't changed.
            if (!stop_point.hasNameSetByUser && stop_point.nameLocation != loclit) {
                //NOTE: Even though our name requests are asynchronous,
                // We have to send these requests later because they get done
                // too fast and then processing blocks the change of the graphics cursor on
                // setSelectedWaypoint. We delay to allow the browser to hit its display cycle before
                // processing Ajax requests. Seems like we need a second.
                setTimeout(function() {
                    ctrl.nameFinder.getNameFromLocation(lonlat, function (json) {
                        if (!stop_point.hasNameSetByUser) {
                            var name = ctrl.findNameReturn(json);
                            sp_li.find("[name='sp_name']").val(name);
                            stop_point.name = name;
                            stop_point.nameLocation = sp_li.find("[name='sp_location']").val();
                            ctrl.routeModified();
                        }
                    });
                }, 1000);
            }
        }
    },

    /**
     * This method is used by various functions that updates the location of a StopPoint.
     * @param stop_point
     */
    triggerOnLocationUpdated : function (stop_point) {
        console.log("triggerOnLocationUpdated");
        if (stop_point !== undefined) {
            this.onLocationUpdated(stop_point);
        }
    },

    /**
     * This function is exclusively used by the KML parser as we have special UI considerations
     * when we are constructing the StopPoint Route from KML sequentially, such as indicating
     * that the NameFinder need not be invoked for names that are filled in.
     *
     * @param name       Name of StopPoint in the KML
     * @param lonlat     The LonLat (in map projection)
     * @param lineString  The Geometery (not Vector).
     */
    appendNewStopPoint : function(name, lonlat, lineString) {
        var sp = new BusPass.StopPoint(name, lonlat.lon, lonlat.lat);
        if (name != "") {
            sp.hasNameSetByUser = true;
        }
        this.StopPoints.splice(this.StopPoints.length,0,sp);
        var wp = this.Route.appendNewWaypoint(lonlat, lineString);
        sp.setWaypoint(wp);

        var sp_li = this.createStopPointDOMElement(sp);

        var ul = $("#stop_points_list");
        ul.append(sp_li);
    },

    appendStopPoint : function () {
        /*
         * Create a new DOM element to enter waypoint info
         * We always add before the last one.
         */
        var sp = new BusPass.StopPoint("new bus stop",0,0);
        this.StopPoints.splice(this.StopPoints.length,0,sp);
        var wp = this.Route.insertWaypoint("last"); // Will create a new WP, will not auto route.
        sp.setWaypoint(wp);

        var sp_li = this.createStopPointDOMElement(sp);

        var ul = $("#stop_points_list");
        ul.append(sp_li);

        // This call resets sp.position.
        this.updateUI();

        this.selectStopPoint(sp);
        this.Controls.click.activate();

        // By inserting new elements we may have moved the map
        $("#map").height(Math.max(this.minMapHeight, $("#navigation").height()));
        //this.Map.updateSize();
        return sp;
    },

    removeStopPoint : function (stop_point, reroute, onCompleteCB, onErrorCB) {
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
            this.Route.removeWaypoint(stop_point.Waypoint.position, true, onCompleteCB, onErrorCB);
        }

        // Delete waypoint
        $(stop_point.viewElement).remove();
        stop_point.viewElement = undefined;
        this.StopPoints.splice(stop_point.position,1);

        this.updateUI();
        this.Route.draw();

        $("#map").height(Math.max(this.minMapHeight, $("#navigation").height()));
        // Redraw map
        this.Map.updateSize();
    },

    addWaypoint : function (sp) {
        var ctrl = this;
        if (this.Route.isComplete()) {
            var wp = this.Route.newWaypoint({
                markerUrl : function () {
                    return "/assets/yours/markers/yellow.png";
                }
            });
            this.Route.insertWaypoint(sp.Waypoint.position+1, wp,
                this.autoroute,
                function() {
                    ctrl.notice("Route Updated", "success", "fade");
                },
                function() {
                    ctrl.notice("Autoroute failed", "error", "fade");
                });
            if (wp) {
                //this.Route.selectWaypoint(wp.position);
                //this.Controls.click.activate();
            }
        }
    },

    setAutoRoute : function (turnon) {
        this.Route.autoroute = turnon;
        if (turnon) {
         $("#autoroute").addClass("active");
        } else {
         $("#autoroute").removeClass("active");
        }
    },

    setAddStopPoints : function (turnon, dontadd) {
        this.auto_add_stoppoints = turnon;
        if (turnon) {
            $("#add_stops").addClass("active");
            $("#drawlines").attr("disabled", "disabled");
            $("#reroute").attr("disabled", "disabled");
            $("#revert").attr("disabled", "disabled");
            $("#clear_route").attr("disabled", "disabled");
            $("#reverse_route").attr("disabled", "disabled");
            this.auto_add_stoppoints = true;
            if (!dontadd) {
                var sp = this.appendStopPoint();
                this.Route.selectWaypoint(sp.Waypoint);
                this.Controls.click.activate();
            }
        } else {
            // Can't turn this off until there are two set stop points.
            if (this.StopPoints.length > 1 &&
                this.StopPoints[0].Waypoint.isLonLatSet() &&
                this.StopPoints[1].Waypoint.isLonLatSet()) {

                $("#add_stops").removeClass("active");
                $("#drawlines").removeAttr("disabled");
                $("#reroute").removeAttr("disabled");
                $("#revert").removeAttr("disabled");
                $("#clear_route").removeAttr("disabled");
                $("#reverse_route").removeAttr("disabled");
                this.auto_add_stoppoints = false;
                var wp = this.Route.SelectedWaypoint;
                this.Route.selectWaypoint(); // unselect
                this.Controls.click.deactivate();
                if (wp && wp.StopPoint) {
                    if (!wp.isLonLatSet()) {
                        this.removeStopPoint(wp.StopPoint, false);
                    }
                }
                this.routeModified();
            } else {
                $("#add_stops").addClass("active");
                this.auto_add_stoppoints = true;
            }
        }
    },

    setDrawLines : function (turnon) {
        var turnoff = !turnon;
        var drawlines = this.Controls.modify.active;
        // If we are already drawlines and the Route is in auto route mode,
        if (drawlines && turnoff) {
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
            $("#add_stops").removeAttr("disabled");
            // We saved autoroute previous state when we turned it off.
            this.setAutoRoute($("#autoroute")[0].previous_state);
            $("#autoroute").removeAttr("disabled");
            $("#reroute").removeAttr("disabled");
            $(".add_waypoint").removeAttr("disabled");
            this.routeUpdated(this.Route);
            // Stop points may have moved, need to get new names, etc.
            this.updateUI();
            $("#drawlines").removeClass("active");
        } else if (!drawlines && turnon) {
            if (this.Route.isComplete()) {
                $("#reroute").attr("disabled", "disabled");
                $("#autoroute").attr("disabled", "disabled");
                // We save the previous state here, and restore it when we turn DrawLines off.
                $("#autoroute")[0].previous_state = this.Route.autoroute;
                this.setAutoRoute(false);
                $("#add_stops").attr("disabled", "disabled");
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
        var ctrl = this;
        // If the waypoint has a link and the location has changed.
        if (wp.hasLink() && !wp.isCurrentLonLat(lonlat)) {
            function clearNotice(waypoint) {
                if (waypoint.hasValidLinks())  {
                    ctrl.notice("Route Updated", "success");
                } else {
                    ctrl.notice("", "clear");
                }
                // TODO: We may only have to update surrounding updates, or all
                // from this one.
                ctrl.updateUIButtonState();
                ctrl.routeModified(); // Saves new history.
            }
            function errorNotice() {
                ctrl.notice("Autoroute failed", "error", "fade");
                ctrl.updateUIButtonState();
                ctrl.routeModified(); // Saves new history.
            }
            wp.setLonLat(lonlat);
            advance();
            if (wp.StopPoint) {
                ctrl.updateStopPointLocationUI(wp.StopPoint);
            }
            wp.route.redrawWaypoints();
            wp.drawValidLinks();
            ctrl.notice("Calculating route", "waiting");
            wp.updateValidLinks(clearNotice, errorNotice);
        } else {
            advance();
            wp.setLonLat(lonlat);
        }
        function advance() {
            if (wp == ctrl.Route.getWaypoint("selected") && wp.StopPoint) {
                var next_stop_point = ctrl.StopPoints[wp.StopPoint.position+1];
                if (next_stop_point !== undefined) {
                    // We ask the route, just in case the Waypoint got deleted.
                    var next = ctrl.Route.getWaypoint(next_stop_point.Waypoint.position);
                    if (next !== undefined && !next.isLonLatSet()) {
                        if (ctrl.Route.selectWaypoint(next.position) === undefined) {
                           // ctrl.Controls.click.deactivate();
                        }
                    } else {
                        // unselect
                        ctrl.Route.selectWaypoint();
                        ctrl.Controls.click.deactivate();
                    }
                } else {
                    if (ctrl.auto_add_stoppoints) {
                        var sp = ctrl.appendStopPoint();
                        ctrl.Route.selectWaypoint(sp.Waypoint);
                    } else {
                        // unselect
                        ctrl.Route.selectWaypoint();
                        ctrl.Controls.click.deactivate();
                    }
                }
            } else {
                // unselect
                ctrl.Route.selectWaypoint();
                ctrl.Controls.click.deactivate();
            }
        }

    },

    clearRoute : function () {
        this.Route.clear();
        this.StopPoints = [];
        $("#stop_points_list").html("");
        this.Route.selectWaypoint();
    },

    clearButton : function () {
        this.routeModified();
        this.clearRoute();
        this.appendStopPoint();
        this.appendStopPoint();
        this.setAddStopPoints(true, "dontadd");
        this.Route.selectWaypoint(this.StopPoints[0].Waypoint);
        this.updateUI();
        this.notice("Route Cleared");
        $("#copybox").val("");
    },

    routeUpdated : function () {
        this.updateUI();
        this.routeModified();
    },

    history : [],

    revertButton: function () {
        if (this.history.length > 1 && this.Route.isComplete()) {
            this.clearRoute();
            this.notice("Route reverted one step", "success", "fade");
            // The top is always the current if the route is complete.
            var kml = this.history.splice(0, 1);
            // So, get the next one.
            kml = this.history.splice(0, 1);
            this.initializeFromKMLString(kml);  // Causes a routeModified
            this.setAddStopPoints(false)
        } else {
            this.notice("No Modification History", "info", "fade");
        }
    },

    routeModified:function () {
        console.log("Route Modified - " + this.Route.isComplete());
        if (this.Route.isComplete()) {
            var kml = this.toKML();
            if (this.history.length > 0)  {
                if (kml != this.history[0]) {
                    this.history.splice(0, 0, kml);
                }
            } else {
                this.history.splice(0, 0, kml);
            }
            this.writeToCopyBox(kml);
        }
    },

    writeToCopyBox:function (kml) {
        $("#copybox_field").val(kml);
        $("#service_kml_field").val(kml);
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
            var lonlat = stop_point.getLonLat();
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

    rerouteButton : function () {
        var ctrl = this;
        var previous = this.Route.autoroute;
        ctrl.setAutoRoute(true);
        ctrl.notice("Calculating Route", "waiting");
        function completeCB() {
            ctrl.setAutoRoute(previous);
            ctrl.notice("Route Updated", "success");
        }

        function errorCB() {
            ctrl.setAutoRoute(previous);
            ctrl.notice("Reroute Failed", "error", "fade");
        }

        ctrl.Route.reroute(completeCB, errorCB);
    },

    reverseButton : function () {
        if (this.Route.isComplete()) {
            this.StopPoints = this.StopPoints.reverse();
            this.Route.reverse();
            this.updateUI(true);
            this.Route.draw();
            this.routeModified();
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
            lock_button.attr("alt", "Unlock this Stop on the map");
            lock_button.attr("title", "Unlock this Stop on the map");
        } else {
            lock_button.attr("data-locked", "false");
            lock_button.attr("alt", "Lock this Stop on the map");
            lock_button.attr("title", "Lock this Stop on the map");
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

    updateUIButtonState : function () {
        // Enable Add Bus Stop when we have a complete route.
        if (this.Route.isComplete()) {
            $("#submit_for_csv").removeAttr("disabled");
            $(".add_waypoint").removeAttr("disabled");
            $("#route_waiting").hide();
        } else {
            $(".add_waypoint").attr("disabled", "disabled");
            $("#submit_for_csv").attr("disabled", "disabled");
        }
    },

    /*
     * Renumber the UI based on the StopPoint Model.
     */
    updateUI : function (reorder) {
        // Enable Add Bus Stop when we have a complete route.
        if (this.Route.isComplete()) {
            $("#submit_for_csv").removeAttr("disabled");
            $(".add_waypoint").removeAttr("disabled");
            $("#route_waiting").hide();
        } else {
            $(".add_waypoint").attr("disabled", "disabled");
            $("#submit_for_csv").attr("disabled", "disabled");
        }
        if (reorder) {
            $("#stop_points_list").html("");
        }
        for(var index = 0; index < this.StopPoints.length; index++) {

            var sp = this.StopPoints[index];
            sp.position = index;
            var sp_li = $(sp.viewElement);

            if (reorder) {
                // We've cleared the list above, so add it back in order.
                $("#stop_points_list").append(sp_li);
            }

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
            this.updateStopPointLocationUI(sp);
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
        marker_image.attr("title", "Click to position this Stop on the map");
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
        var lonlat = stop_point.getLonLat();
        if (lonlat) {
            lonlat.transform(this.Map.projection, this.Map.displayProjection);
            location.val(lonlat.lon.toFixed(6) + "," + lonlat.lat.toFixed(6));
        }
        location.change(function () {
            this.Controller.inputUpdateStopPointLocation(this.StopPoint, this);
            this.Controller.routeUpdated();
        });
        var name = $(document.createElement("input"));
        name[0].StopPoint = stop_point;
        name[0].Controller = this;
        name.attr("type", "text");
        name.attr("name", "sp_name");
        name.addClass("sp_name");
        name.val(stop_point.name);
        name.change(function () {
            this.StopPoint.name = $(this).val();
            this.StopPoint.hasNameSetByUser = true;
            this.Controller.routeModified();
        });

        var del_button = $(document.createElement("input"));
        del_button[0].Controller = ctrl;
        del_button[0].StopPoint = stop_point;
        del_button.attr("type", "button");
        del_button.attr("name", "via_del_image");
        del_button.attr("alt", "Remove this Stop from the map");
        del_button.attr("title", "Remove this Stop from the map");
        del_button.bind("click", function () {
            this.Controller.removeStopPoint(this.StopPoint,
                this.Controller.autoroute,
                function() {
                    this.Controller.notice("Route Updated", "success", "fade");
                    this.Controller.routeUpdated();
                },
                function() {
                    this.Controller.notice("Autoroute Failed", "error", "fade");
                    this.Controller.routeUpdated();
                });
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
            ctrl.updateUI();
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

    toKML : function() {
        function escapeHTML(str) {
            if (str)  {
                return str.replace(/&/g, '&amp;').replace(/</g, '&lt;').replace(/>/g, '&gt;').replace(/"/g, '&quot;').replace(/'/g, '&apos;');
            }   else {
                return "";
            }
        }
        var ctrl = this;
        function stopPointKML (sp) {
           var lonlat = new OpenLayers.LonLat(sp.Waypoint.geometry.x, sp.Waypoint.geometry.y);
           lonlat.transform(ctrl.Map.projection, ctrl.Map.displayProjection);
           return  "<Placemark id='sp_" + i + "'><name>" + "sp_" + i + ":" + escapeHTML(sp.name) +
                   "</name><Point><coordinates>" + lonlat.lon.toFixed(6) + "," + lonlat.lat.toFixed(6) +
                   "</coordinates></Point></Placemark>";
        }
        function lineStringKML(lineString) {
            var kml = "<coordinates>";
            var points = lineString.geometry.components;
            for (var i = 0; i < points.length; i++) {
                var lonlat = new OpenLayers.LonLat(points[i].x, points[i].y);
                lonlat.transform(ctrl.Map.projection, ctrl.Map.displayProjection);
                kml += lonlat.lon.toFixed(6) + "," + lonlat.lat.toFixed(6) + " ";
            }
            return kml + "</coordinates>";
        }
        function linkKML(i,lineString) {
            return "<Placemark id='link_" + i + "'><name>" + "link_" + i + ":" +"</name><LineString>" + lineStringKML(lineString) +
                "</LineString></Placemark>"
        }
        var kml = "<kml xmlns='http://earth.google.com/kml/2.0'><Folder><name>Busme</name>";
        for(var i = 0; i < this.StopPoints.length-1; i++) {
            var sp = this.StopPoints[i];
            var sp_next = this.StopPoints[i+1];
            var lineString = this.Route.createLineStringFromTo(sp.Waypoint, sp_next.Waypoint);
            kml += stopPointKML(sp) + linkKML(i, lineString);
        }
        kml += stopPointKML(this.StopPoints[this.StopPoints.length-1]);
        return kml + "</Folder></kml>";
    },

    CLASS_NAME : "BusPass.StopPointsController"
});