BusPass.StopPointModifyFeatureControl = OpenLayers.Class( OpenLayers.Control.ModifyFeature, {

    initialize : function(layer, options) {
        OpenLayers.Control.ModifyFeature.prototype.initialize.apply(this,[layer,options]);
    },

    /**
     * Method: collectVertices
     * Collect the vertices from the modifiable feature's geometry and push
     *     them on to the control's vertices array.
     */
    collectVertices: function() {
        this.vertices = [];
        this.virtualVertices = [];
        var geometry = this.feature.geometry;
        // Assume its the line string.
        for(var i = 0, len = geometry.components.length; i < len; i++) {
            var component = geometry.components[i];
            if (component._vertex !== undefined) {
                // If its a waypoint, we just use the marker.
                vertex =  new OpenLayers.Feature.Vector(component, component._vertex.marker.attributes);
                vertex._sketch = true;
                vertex.renderIntent = this.vertexGraphicRenderIntent;
            } else {
                vertex = new OpenLayers.Feature.Vector(component);
                vertex._sketch = true;
                vertex.renderIntent = this.vertexRenderIntent;
            }
            this.vertices.push(vertex);
        }
        for(i=0, len=geometry.components.length; i<len-1; ++i) {
            var prevVertex = geometry.components[i];
            var nextVertex = geometry.components[i + 1];
            if(prevVertex.CLASS_NAME == "OpenLayers.Geometry.Point" &&
                nextVertex.CLASS_NAME == "OpenLayers.Geometry.Point") {
                var x = (prevVertex.x + nextVertex.x) / 2;
                var y = (prevVertex.y + nextVertex.y) / 2;
                var point = new OpenLayers.Feature.Vector(
                    new OpenLayers.Geometry.Point(x, y),
                    null, this.virtualStyle
                );
                // set the virtual parent and intended index
                point.geometry.parent = geometry;
                point._index = i + 1;
                point._sketch = true;
                this.virtualVertices.push(point);
            }
        }
        this.layer.addFeatures(this.virtualVertices, {silent: true});
        this.layer.addFeatures(this.vertices, {silent: true});
    },

})