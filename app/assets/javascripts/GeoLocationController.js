BusPass.GeoLocationController = function (options) {
    $.extend(this,options);
};

BusPass.GeoLocationController.prototype = {
    /**
     * Attribute:
     * This attribute contains the 'default' and 'temporary' styles
     * for drawing the icons on the map.
     */
    styleMap : new OpenLayers.StyleMap({
        'default': new OpenLayers.Style( {
            graphicOpacity : 1,
            graphicWidth : 21,
            graphicHeight : 25,
            pointRadius : 0,
            graphicXOffset : -21/2,
            graphicYOffset : -25,
            externalGraphic : "http://www.openlayers.org/dev/img/marker.png",
        }),
        'temporary': new OpenLayers.Style({
            graphicOpacity : 0.3,
            graphicWidth : 21,
            graphicHeight : 25,
            pointRadius : 0,
            graphicXOffset : -21/2,
            graphicYOffset : -25,
            externalGraphic : "http://www.openlayers.org/dev/img/marker.png",
        }),
    }),

    mapView : function(jquery) {
        this.map = new OpenLayers.Map($(jquery)[0].id);
        this.map.projection = "EPSG:900913"; // Need by OSM
        this.map.displayProjection = new OpenLayers.Projection("EPSG:4326");
        var mapnik = new OpenLayers.Layer.OSM("OpenStreetMap (Mapnik)");
        this.map.addLayers([mapnik]);
        this.map.addControl(new OpenLayers.Control.LayerSwitcher());
        this.map.addControl(new OpenLayers.Control.MousePosition());
        this.map.setCenter(new OpenLayers.LonLat(-76.146669, 43.050952).transform(
            new OpenLayers.Projection("EPSG:4326"), // transform from WGS 1984
            new OpenLayers.Projection("EPSG:900913") // to Spherical Mercator Projection
        )
        , 13 // Zoom level
        );

        this.layer = new OpenLayers.Layer.Vector( "Points", {
            styleMap: this.styleMap
        });
        this.map.addLayer(this.layer);
        var ctrl = this;
        this.drawMarkerControl = new OpenLayers.Control.DrawFeature(
            this.layer, OpenLayers.Handler.Point, {
                featureAdded : function (feature) {
                    ctrl.onFeatureAdded(feature);
                }
            });

        this.map.addControl(this.drawMarkerControl);

        this.dragFeatureC = new OpenLayers.Control.DragFeature(
            this.layer, {
                onComplete: function(feature, pixel){
                    ctrl.onFeatureMoved(feature);
                }
            });

        this.map.addControls([this.dragFeatureC]);

        this.dragFeatureC.activate();
    },

    enableClickControl : function (state) {
        this.drawMarkerControl.activate();
        this.dragFeatureC.deactivate();
    },

    disableClickControl : function () {
        this.drawMarkerControl.deactivate();
        this.dragFeatureC.activate();
    },

    addMarker : function(loc, attributes) {
        if (loc != null) {
            var lonlat = new OpenLayers.LonLat(loc[0],loc[1]).transform(
                new OpenLayers.Projection("EPSG:4326"), // transform from WGS 1984
                new OpenLayers.Projection("EPSG:900913") // to Spherical Mercator Projection
            );
            // Feature will have 'default' style.
            var geometry = new OpenLayers.Geometry.Point(lonlat.lon, lonlat.lat);
            attributes = attributes ? attributes : {};
            var marker = new OpenLayers.Feature.Vector(geometry, attrributes);
            this.layer.addFeatures([marker]);
        }
    },

    getFeatureLonLat : function (feature) {
        var point = { x: feature.geometry.x, y: feature.geometry.y };
        OpenLayers.Projection.transform( point, this.map.getProjectionObject(),
                                         this.map.displayProjection);
        return new OpenLayers.LonLat(point.x, point.y);
    },

    onFeatureAdded : function (feature) {
    },

    onFeatureMoved : function (feature) {
    },
};