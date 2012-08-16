

BusPass.Controls = function () {

}

/**
 * This type is a OpenLayers Control for modifying a feature that will only let
 * us modify all vertices except the very end points. We do this by removing
 * the endpoint vertex from the layer. That is because the features that have been
 * removed from the layer cannot be selected by this Control's DragControl.
 * @type {*}
 */
BusPass.Controls.ModifyFeature = OpenLayers.Class(OpenLayers.Control.ModifyFeature, {
    initialize : function(layer, options) {
        OpenLayers.Control.ModifyFeature.prototype.initialize.apply(this,[layer,options]);
        console.log("ModifyFeature.The Route is " + this.Route);
    },
    /**
     * This function is called every time the feature is selected and modified. We remove
     * the first and last vertices from the layer after it super class has done this job.
     */
    collectVertices : function () {
        if (this.Route) {
            this.vertices = [];
            this.virtualVertices = [];
            var control = this;
            function collectComponentVertices(geometry) {
                var i, vertex, component, len;
                if(geometry.CLASS_NAME == "OpenLayers.Geometry.Point") {
                    vertex = new OpenLayers.Feature.Vector(geometry);
                    vertex._sketch = true;
                    vertex.renderIntent = control.vertexRenderIntent;
                    control.vertices.push(vertex);
                } else {
                    var numVert = geometry.components.length;
                    if(geometry.CLASS_NAME == "OpenLayers.Geometry.LinearRing") {
                        numVert -= 1;
                    }
                    for(i=0; i<numVert; ++i) {
                        component = geometry.components[i];
                        if(component.CLASS_NAME == "OpenLayers.Geometry.Point") {
                            vertex = new OpenLayers.Feature.Vector(component);
                            vertex._sketch = true;
                            vertex.renderIntent = control.vertexRenderIntent;
                            control.vertices.push(vertex);
                        } else {
                            collectComponentVertices(component);
                        }
                    }

                    // add virtual vertices in the middle of each edge
                    if(geometry.CLASS_NAME != "OpenLayers.Geometry.MultiPoint") {
                        for(i=0, len=geometry.components.length; i<len-1; ++i) {
                            var prevVertex = geometry.components[i];
                            var nextVertex = geometry.components[i + 1];
                            if(prevVertex.CLASS_NAME == "OpenLayers.Geometry.Point" &&
                                nextVertex.CLASS_NAME == "OpenLayers.Geometry.Point") {
                                var x = (prevVertex.x + nextVertex.x) / 2;
                                var y = (prevVertex.y + nextVertex.y) / 2;
                                var point = new OpenLayers.Feature.Vector(
                                    new OpenLayers.Geometry.Point(x, y),
                                    null, control.virtualStyle
                                );
                                // set the virtual parent and intended index
                                //point.geometry.parent = geometry;
                                //point._index = i + 1;
                                // Since we are using a Geometry to filter out points in the main feature (LineString)
                                // we set the new point's parent and index based on the feature and not this
                                // geometry. The DragHandler.onDragVertex will add this point to this point's
                                // geometry.parent at _index.
                                point.geometry.parent = components[i]._virtual_parent;
                                point._index = components[i]._virtual_parent.
                                point._sketch = true;
                                control.virtualVertices.push(point);
                            }
                        }
                    }
                }
            }
            // We have been given a LineString with points in it.
            // We create vertices for each point that is not a vertex (waypoint),
            // which is marked by _vertex, and the points surrounding each. This
            // allows us only to modify all points besides the vertex, which is
            // a locked waypoint.
            // TODO: We need a way to create vertices, look above.
            if (false) {
            for (var i = 0; i < this.Route.Links.length; i++) {
                var link = this.Route.Links[i];
                var from = link.startWaypoint;
                var to = link.endWaypoint;
                var components = link.lineString.geometry.components.slice(0);
                if (from.Locked) {
                    components.splice(0,1);
                } else {
                    components.splice(0,0,from.marker.geometry.components[0]);
                }
                if (to.Locked) {
                    components.splice(-1,1);
                } else if (i == this.Route.Links.length -1) {
                    components.push(to.marker.geometry.components[0]);
                }
                collectComponentVertices(new OpenLayers.Geometry.LineString(components));
            }
            } else {
                var components = this.feature.geometry.components;
                var vertices = [];
                // We only include points if they are NOT a locked vertex
                // and the points that surrounds them.
                // The first and last points should be marked, so we don't look at them.
                for(var i = 1; i < components.length-1; i++) {
                    if (components[i-1]._vertex == undefined &&
                        components[i]._vertex   == undefined  &&
                        components[i+1]._vertex == undefined) {
                        components[i]._virtual_parent_index = i + 1;
                        components[i]._virtual_parent = this.feature.geometry;
                        vertices.push(components[i]);
                    }
                }
                collectComponentVertices(new OpenLayers.Geometry.LineString(vertices));
            }
            this.layer.addFeatures(this.virtualVertices, {silent: true});
            this.layer.addFeatures(this.vertices, {silent: true});
        } else {
            console.log("ModifyFeatures.collectVertices |- " + this.vertices.length);
            OpenLayers.Control.ModifyFeature.prototype.collectVertices.apply(this, arguments);
            console.log("ModifyFeatures.collectVertices -| " + this.vertices.length);
            console.log("ModifyFeatures.collectVertices -| " + this.layer.name);
            console.log("ModifyFeatures.collectVertices -| " + this.layer.features.length);
            this.layer.removeFeatures(this.vertices[0]);
            if (this.vertices.length > 1) {
                this.layer.removeFeatures(this.vertices[this.vertices.length-1]);
            }
        }
    },
    CLASS_NAME : "BusPass.Controls.ModifyFeature"
});
