

SelectControl = OpenLayers.Class(OpenLayers.Control.SelectFeature, {
    /**
        * APIProperty: onSelect
        * {Function} Optional function to be called when a feature is selected.
        *     The function should expect to be called with a feature.
        */
    onClickout: function() {},

    // Override
    clickoutFeature : function(feature) {
        if(!this.hover && this.clickout) {
            this.unselectAll();
            this.onClickout.call(this.scope);
        }
    },

    /**
    * Constructor: OpenLayers.Control.SelectFeature
    * Create a new control for selecting features.
    *
    * Parameters:
    * layers - {<OpenLayers.Layer.Vector>}, or an array of vector layers. The
    *     layer(s) this control will select features from.
    * options - {Object}
    */
    initialize: function(layers, options) {
        OpenLayers.Control.SelectFeature.prototype.initialize.apply(this, [layers, options]);
        console.log("arg layers: " + layers);
        console.log("layer: " + this.layer);
    }
});

RouteMap = function() {
};

RouteMap.prototype = {

      init : function() {
          this._map = new OpenLayers.Map('map');
          this._map.projection = "EPSG:23030";
          this._map.displayProjection = new OpenLayers.Projection("EPSG:4326");
          var mapnik = new OpenLayers.Layer.OSM("OpenStreetMap (Mapnik)");

          this._map.addLayers([mapnik]);
          this._map.addControl(new OpenLayers.Control.LayerSwitcher());
          this._map.addControl(new OpenLayers.Control.MousePosition());
          this._map.setCenter(new OpenLayers.LonLat(-76.146669, 43.050952).transform(
            new OpenLayers.Projection("EPSG:4326"), // transform from WGS 1984
            new OpenLayers.Projection("EPSG:900913") // to Spherical Mercator Projection
            ), 13 // Zoom level
          );

          this._routeVectors = this.newVectorLayer();
          console.log("created vector layer");
          this._map.addLayers([this._routeVectors]);
          console.log("added vector layer");
      },

      addLayer : function(layer) {
        this._map.addLayers([layer]);
      },

      getLayerFromRoute : function(route) {
        return this.getLayer(route.getId());
      },

      addRoute : function(route) {
        var layer = this.getLayerFromRoute(route);
        this.addLayer(layer);
      },

      newVectorLayer : function() {
        var self = this;
        var ruleLow = new OpenLayers.Rule({
          context : function(feature) { return feature; },
          filter: new OpenLayers.Filter({
            evaluate: function(context) {
              console.log("select: "+self._routeVectors.selectedFeatures.length+" - " + context.__route.isSelected());
              return self._routeVectors.selectedFeatures.length > 0 &&
                !context.__route.isSelected();
            }
            }),
          symbolizer: {
            display: "none"
          }
        });
        var defaultStyle = new OpenLayers.Style(
          {
            strokeColor: "blue",
            strokeWidth: 5,
            strokeOpacity: 0.5,
            cursor: "pointer"
          });
        defaultStyle.addRules([ruleLow,
                              new OpenLayers.Rule({
                                elseFilter: true
                              })
                            ]);
        var notSelectStyle = new OpenLayers.Style(
          {
            strokeColor: "white",
            strokeWidth: 0,
            strokeOpacity: 0.0,
            cursor: "none"
          });
        var selectStyle =  new OpenLayers.Style(
            {
                strokeColor: "red",
                strokeWidth: 5,
                strokeOpacity: 1.0,
                cursor: "pointer"
            });
        var temporaryStyle =  new OpenLayers.Style(
            {
                strokeColor: "#00ff00",
                strokeWidth: 9,
                strokeOpacity: 1.0,
                graphicZIndex: 999, // this doesn't work dynamically, only when features is added, I guess.
                cursor: "pointer"
            });
        var styleMap = new OpenLayers.StyleMap({
          'default': defaultStyle,
          'notSelect' : notSelectStyle,
          'select': selectStyle,
          'temporary' : temporaryStyle
        });

        var layer = new OpenLayers.Layer.Vector("Routes", {
            // We want to bring hightlights up to the top. We need zIndexing
            // which works by a graphicZIndex style option.
            rendererOptions: {
                zIndexing : true
            },
            styleMap : styleMap
        });

        function report(ev) {
          console.log(ev);
        };

        function onHighlight(ev) {
            report(ev);
            var feature = ev.feature;
            var route = feature.__route;
            self._routesView.highlightRoute(route);
        };

        function onUnhighlight(ev) {
            report(ev);
            var feature = ev.feature;
            var route = feature.__route;
            self._routesView.unhighlightRoute(route);
        };


        var highlightCtrl = new OpenLayers.Control.SelectFeature(layer, {
          hover: true,
          highlightOnly: true,
          multiple: true,
          renderIntent: "temporary",
          eventListeners: {
            beforefeaturehighlighted: report,
            featurehighlighted: onHighlight,
            //featureunhighlghted does not get called if selected. Ugg.
            // Probably due to the other Selection Controller calling
            // highlight when the feature is selected?
            featureunhighlighted: onUnhighlight
          },
        });

        function clickAlert(ev) {
          alert("Clicked" + ev);
        };

        function onSelectRoute(feature) {
          // feature has been selected, Just tell the RouteView of the selection.
          this._routesView._selectRoute(feature.__route);
          this._routeVectors.redraw();
        };

        // This gets called via selectRoute and also by
        // MouseEvent, which unselectsAll.
        function onUnselectRoute(feature) {
            // feature has been selected, Just tell the RouteView of the selection.
          this._routesView._unselectRoute(feature.__route);
        };


        function onClickout() {
            // This will have hit the onUnselectedRoute for every one selected?
            // Which will have cleared its select on the routesView.
            this._routeVectors.redraw();
        };

        this._selectCtrl = new SelectControl(layer, {
                                        scope: this,
                                        onSelect: onSelectRoute,
                                        onUnselect: onUnselectRoute,
                                        onClickout : onClickout,
                                        clickout: true,
                                        multiple: false
                                        }
                                    );

        this._map.addControl(highlightCtrl);
        this._map.addControl(this._selectCtrl);

        highlightCtrl.activate();
        this._selectCtrl.activate();
        return layer;
      },

      setRoutesView : function(rv) {
          this._routesView = rv;
      },

      _selectRoute : function(route) {
          this.selectFeatures(route.getMapFeatures());
      },

      _unselectRoute : function(route) {
          this.unselectFeatures(route.getMapFeatures());
      },

      selectFeatures : function(features) {
        var self = this;
        self._selectCtrl.unselectAll();
        $.each(features, function(i,a) {
                self._selectCtrl.select(a);
            });
      },

      unselectFeatures : function(features) {
        var self = this;
        $.each(features, function(i,a) { self._selectCtrl.unselect(a)});
        self._routeVectors.redraw();
      },

      addFeatureFromRoute : function(route) {
        route.setMap(this);
        return this.addFeature(route);
      },

      addFeature : function(route, cb) {
        var map = this;
        protocol = new OpenLayers.Protocol.HTTP({
          url: "/webmap/route/"+route.getId()+".json",
          format: new OpenLayers.Format.GeoJSON({
            ignoreExtraDims: true,
            internalProjection: new OpenLayers.Projection("EPSG:900913"),
            externalProjection: new OpenLayers.Projection("EPSG:4326")
          }),
          callback : function(response) {
            route.setMapFeatures(response.features);
            map._routeVectors.addFeatures(response.features);
          }
        });
        protocol.read();
      },

}