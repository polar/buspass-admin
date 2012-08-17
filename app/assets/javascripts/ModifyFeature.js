

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
                    // If the component has the virtual_parent set from below, it belongs to the main
                    // feature. We set the vertex's geometry to the parent, which enables
                    // the keypress handler to delete a vertex in the main feature..
                    if (geometry._virtual_parent !== undefined) {
                        // If it was excluded from making virtual points, it cannot be deleted.
                        // The keypress Hander will not delete the component if it doesn't have a parent..
                        if (component._exclude === undefined && component._excludeNext === undefined) {
                            vertex.geometry.parent = geometry._virtual_parent;
                        } else {
                            vertex.geometry.parent = undefined;
                        }
                    }
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
                            // If the component has the virtual_parent set from below, it belongs to the main
                            // feature. We set the vertex's geometry to the parent, which enables
                            // the keypress handler to delete a vertex in the main feature..
                            if (component._virtual_parent !== undefined) {
                                // If it was excluded from making virtual points, it cannot be deleted.
                                // The keypress Hander will not delete the component if it doesn't have a parent..
                                if (component._excludePrev === undefined && component._excludeNext === undefined) {
                                    vertex.geometry.parent = component._virtual_parent;
                                } else {
                                    vertex.geometry.parent = undefined;
                                }
                            }
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
                                // If both vertices were marked, there is 3 points in between in the feature
                                // that are not in this geometry. We do not create a virtual vertex, because
                                // that would cause a triangle.
                                if (!(prevVertex._excludePrev && nextVertex._excludeNext)) {
                                    var x = (prevVertex.x + nextVertex.x) / 2;
                                    var y = (prevVertex.y + nextVertex.y) / 2;
                                    var point = new OpenLayers.Feature.Vector(
                                        new OpenLayers.Geometry.Point(x, y),
                                        null, control.virtualStyle
                                    );
                                    // Set the virtual parent and intended index
                                    //point.geometry.parent = geometry;
                                    //point._index = i + 1;
                                    // Since we are using a Geometry to filter out points in the main selected
                                    // feature (LineString), we set the new point's parent and index based on the
                                    // feature's geometry. The DragHandler.onDragVertex will add this point to
                                    // this point's geometry.parent at _index.
                                    point.geometry.parent = prevVertex._virtual_parent;
                                    point._index = prevVertex._virtual_parent_index;
                                    point._sketch = true;
                                    control.virtualVertices.push(point);
                                }
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
            var components = this.feature.geometry.components;
            var vertices = [];
            // We only include points if they are NOT a locked vertex
            // and the points that surrounds them.
            // The first and last points should be marked, so we don't look at them.
            for(var i = 2; i < components.length-2; i++) {
                if (components[i-1]._vertex == undefined &&
                    components[i]._vertex   == undefined  &&
                    components[i+1]._vertex == undefined) {
                    components[i]._virtual_parent_index = i + 1;
                    components[i]._virtual_parent = this.feature.geometry;
                    vertices.push(components[i]);
                } else {
                    // We do not include the point. However we need to mark that any surrounding
                    // vertex is supposed to have a virtual vertex between them.
                    if (components[i]._vertex !== undefined) {
                        components[i-2]._excludePrev = true;
                        components[i+2]._excludeNext = true;
                    }
                }
            }
            components[2]._excludeNext = true;
            components[components.length-3]._excludePrev = true;
            collectComponentVertices(new OpenLayers.Geometry.LineString(vertices));

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
