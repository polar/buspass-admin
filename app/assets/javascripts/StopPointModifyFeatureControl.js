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
                console.log("We have a _vertext at " + i);
                // If its a waypoint, we just use the marker.
                vertex =  new OpenLayers.Feature.Vector(component, component._vertex.marker.attributes);
                vertex._locked = component._vertex.StopPoint.isLocked();
                vertex._waypoint = component._vertex;
                vertex._sketch = true;
                vertex.renderIntent = this.vertexGraphicRenderIntent;
            } else {
                vertex = new OpenLayers.Feature.Vector(component);
                vertex._sketch = true;
                vertex.renderIntent = this.vertexRenderIntent;
                // This allows it to be deleted by selectFeature and key press.
                vertex.geometry.parent = geometry;
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
        this.layer.addFeatures(this.virtualVertices, {silent:true});
        this.layer.addFeatures(this.vertices, {silent: true});
    },

    /**
     * Method: dragStart
     * Called by the drag feature control with before a feature is dragged.
     *     This method is used to differentiate between points and vertices
     *     of higher order geometries.  This respects the <geometryTypes>
     *     property and forces a select of points when the drag control is
     *     already active (and stops events from propagating to the select
     *     control).
     *
     * Parameters:
     * feature - {<OpenLayers.Feature.Vector>} The point or vertex about to be
     *     dragged.
     * pixel - {<OpenLayers.Pixel>} Pixel location of the mouse event.
     */
    dragStart:function (feature, pixel) {
        if (feature._locked) {
            console.log("Drag Start on locked feature");
            return false;
        } else {
            OpenLayers.Control.ModifyFeature.prototype.dragStart.apply(this, arguments);
        }
    },
    /**
     * Method: dragVertex
     * Called by the drag feature control with each drag move of a vertex.
     *
     * Parameters:
     * vertex - {<OpenLayers.Feature.Vector>} The vertex being dragged.
     * pixel - {<OpenLayers.Pixel>} Pixel location of the mouse event.
     */
    dragVertex:function (vertex, pixel) {
        console.log("DragVertex....." + vertex + " locked " + vertex._locked + " feature " + this.feature);
        if (vertex._locked) {
            return;
        } else {
            OpenLayers.Control.ModifyFeature.prototype.dragVertex.apply(this, arguments);
        }
    },

    /**
     * Method: dragComplete
     * Called by the drag feature control when the feature dragging is complete.
     *
     * Parameters:
     * vertex - {<OpenLayers.Feature.Vector>} The vertex being dragged.
     */
    dragComplete:function (vertex) {
        console.log("DragComplete...." + vertex + " locked " + vertex._locked + " feature " + this.feature);
        var wp = vertex;
        if (vertex._locked) {
            vertex._waypoint.resetGeometry();
            this.layer.drawFeature(vertex);
        } else {
            OpenLayers.Control.ModifyFeature.prototype.dragComplete.apply(this, arguments);
        }
    },

    /**
     * Method: handleKeypress
     * Called by the feature handler on keypress.  This is used to delete
     *     vertices. If the <deleteCode> property is set, vertices will
     *     be deleted when a feature is selected for modification and
     *     the mouse is over a vertex.
     *
     * Parameters:
     * evt - {Event} Keypress event.
     */
    handleKeypress:function (evt) {
        var code = evt.keyCode;

        // check for delete key
        if (this.feature &&
            OpenLayers.Util.indexOf(this.deleteCodes, code) != -1) {
            var vertex = this.dragControl.feature;
            if (vertex &&
                OpenLayers.Util.indexOf(this.vertices, vertex) != -1 &&
                !this.dragControl.handlers.drag.dragging &&
                vertex.geometry.parent) {
                // remove the vertex
                vertex.geometry.parent.removeComponent(vertex.geometry);
                this.layer.events.triggerEvent("vertexremoved", {
                    vertex:vertex.geometry,
                    feature:this.feature,
                    pixel:evt.xy
                });
                this.layer.drawFeature(this.feature, this.standalone ?
                    undefined :
                    this.selectControl.renderIntent);
                this.modified = true;
                this.resetVertices();
                this.setFeatureState();
                this.onModification(this.feature);
                this.layer.events.triggerEvent("featuremodified",
                    {feature:this.feature});
            }
        }
    },

})