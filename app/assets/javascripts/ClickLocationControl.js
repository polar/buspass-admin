
// Create OpenLayers Control Click handler
BusPass.ClickLocationControl = OpenLayers.Class(OpenLayers.Control, {

        onLocationClick : function(lonlat) {},

        defaultHandlerOptions: {
            'single': true,
            'double': false,
            'pixelTolerance': 0,
            'stopSingle': false,
            'stopDouble': false
        },

        /*
         * Initialize is called when the Click control is activated
         * It sets the behavior of a click on the map
         */
        initialize: function() {
            this.handlerOptions = OpenLayers.Util.extend(
                {}, this.defaultHandlerOptions
            );
            OpenLayers.Control.prototype.initialize.apply(
                this, arguments
            );
            this.handler = new OpenLayers.Handler.Click(
                this, {
                    'click': this.triggerOnLocationClick
                }, this.handlerOptions
            );
        },

        /*
         * How OpenLayers should react to a user click on the map.
         * Get the LonLat from the user click and position
         */
        triggerOnLocationClick: function(e) {
            var lonlat = this.map.getLonLatFromViewPortPx(e.xy);
            this.onLocationClick(lonlat);
        }
    }
);