

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
    },
    /**
     * This function is called every time the feature is selected and modified. We remove
     * the first and last vertices from the layer after it super class has done this job.
     */
    collectVertices : function () {
        console.log("ModifyFeatures.collectVertices |- " + this.vertices.length);
        OpenLayers.Control.ModifyFeature.prototype.collectVertices.apply(this, arguments);
        console.log("ModifyFeatures.collectVertices -| " + this.vertices.length);
        console.log("ModifyFeatures.collectVertices -| " + this.layer.name);
        console.log("ModifyFeatures.collectVertices -| " + this.layer.features.length);
        this.layer.removeFeatures(this.vertices[0]);
        if (this.vertices.length > 1) {
            this.layer.removeFeatures(this.vertices[this.vertices.length-1]);
        }
    },
    CLASS_NAME : "BusPass.Controls.ModifyFeature"
});
