

/**
 * @requires OpenLayers/Control.js
 * @requires OpenLayers/Feature/Vector.js
 * @requires OpenLayers/Handler/Click.js
 * @requires OpenLayers/Layer/Vector/RootContainer.js
 */

/**
 * Class: BusPass.SelectAllFeature
 * The SelectAllFeature control selects all vector features from a given layer on
 * click or hover, not just the top one.
 *
 * Inherits from:
 *  - <OpenLayers.Control>
 */

BusPass.SelectAllFeature = OpenLayers.Class(OpenLayers.Control, {

    /**
     * Constant: EVENT_TYPES
     *
     * Supported event types:
     *  - *beforefeaturehighlighted* Triggered before a feature is highlighted.
     *  - *featurehighlighted* Triggered when a feature is highlighted.
     *  - *featureunhighlighted* Triggered when a feature is unhighlighted.
     *  - *beforefeatureselected* Triggered before a feature is selected.
     *  - *featureselected* Triggered when a feature is selected.
     *  - *featureunselected* Triggered when a feature is selected.
     */
    EVENT_TYPES: ["beforefeaturehighlighted", "featurehighlighted", "featureunhighlighted",
                  "beforefeatureselected", "featureselected", "featureunselected"],

    /**
     * APIProperty: pointRadius
     * {Integer} This is the pixel point radius used to select features.
     *      Default is 3.
     */
    pointRadius : 3,

    /**
     * APIProperty: multiple
     * {Boolean} Allow selection of multiple Features.  Default is false.
     */
    multiple: false,

    /**
     * APIProperty: clickout
     * {Boolean} Unselect and/or unhighlight features when clicking outside any feature.
     *     Default is true.
     */
    clickout: true,

    /**
     * APIProperty: highlightPolicy
     * {String} Highlight Feature Policy.
     * "onMove" -- highlight when mouse moved into features.
     *             Warning this option may be intensive.
     * "onPause" -- only highlight when paused over features.
     * "onClick" -- highlight on a click, or as a result of a click.
     * "none"    -- do not highlight.
     *
     * Default is "onPause"
     */
    highlightPolicy : "onPause",

    /**
     * APIProperty: unhighlightPolicy
     * {String} Unhighlight Feature Policy.
     * "onMove" -- highlight of Fetures ends when mouse moved.
     *             Warning this option may be intensive.
     * "onPause" -- only end highlight when paused.
     * "onClick" -- highlight on a click, or as a result of a click.
     * "none"    -- do not highlight.
     *
     * Default is "onMove"
     */
    unhighlightPolicy : "onMove",

    /**
     * APIProperty: selectPolicy
     * {String} Select Feature Policy.
     * "onMove" -- select when mouse moved into features.
     *             Warning this option may be intensive.
     * "onPause" -- only select when paused over features.
     * "onClick" -- select on a click, or as a result of a click.
     * "onHighlight" -- Select on a Highlight
     * "none"    -- do not highlight.
     *
     * Default is "onPause"
     */
    selectPolicy : "onClick",

    /**
     * APIProperty: unselectPolicy
     * {String} Unselect selected Feature Policy.
     * "onMove"  -- select all Features under mouse when mouse moved.
     * "onPause" -- unselect when paused.
     * "onClick" -- unselect as a result of a click.
     *              If combined with a onClick select policy, only new
     *              ones will be notified, the previously selected that fall
     *              under the selection will remain selected.
     * "none"    -- do not unselect. You can get an automatic
     *              unselect by setting this.clickout.
     *
     * Default is "mone"
     */
    unselectPolicy : "none",

    /**
     * Property: scope
     * {Object} The scope to use with the onBeforeSelect, onBeforeSelectFeature, onSelected, onUnselected
     *     onBeforeHighlight, onBeforeHighlightFeature, onHighlighted, onUnhighlighted callbacks.
     *     If null the scope will be this control.
     */
    scope: null,

    /**
     * Property: onBeforeSelect
     * {Function} Optional function to be called before features are selected.
     *     The function shall be called with an {Array(<OpenLayers.Feature.Vector>)}
     *     about to be selected.
     *
     * Returns a {Array(<OpenLayers.Feature.Vector>)} that should be selected.
     */
    onBeforeSelect: function (features) { return features; },

    /**
     * Property: onBeforeSelectFeature
     * {Function} Optional function to be called before a Feature is to be selected.
     *     The function shall be called with a an {<OpenLayers.Feature.Vector>}.
     *
     * Returns a {Boolean} to indicate if the feature should be included in
     * the features to be selected.
     */
    onBeforeSelectFeature: function (feature) {},

    /**
     * APIProperty: onSelected
     * {Function} Optional function to be called when Features have been selected.
     *     The function shall be called with a list of Features.
     */
    onSelected: function (features) {},

    /**
     * APIProperty: onUnselected
     * {Function} Optional function to be called when Features are unselected.
     *     The function shall be called an {Array(<OpenLayers.Feature.Vector>)}.
     */
    onUnselected: function (features) {},

    /**
     * Property: onBeforeHighlight
     * {Function} Optional function to be called before features are highlighted.
     *     The function shall be called with an {Array(<OpenLayers.Feature.Vector>)}
     *     about to be highlighted.
     *
     * Returns a {Array(<OpenLayers.Feature.Vector>)} that should be highlighted.
     */
    onBeforeHighlight: function (features) { return features; },

    /**
     * Property: onBeforeHightlightFeature
     * {Function} Optional function to be called before a Feature is to be highlighted.
     *     The function shall be called with a an {<OpenLayers.Feature.Vector>}.
     *
     * Returns a {Boolean} to indicate if the feature should be included in
     * the features to be highlighted.
     */
    onBeforeHighlightFeature: function (feature) {},

    /**
     * APIProperty: onHighlighted
     * {Function} Optional function to be called when Features have been highlighted.
     *     The function shall be called with a list of Features.
     */
    onHighlighted: function (features) {},

    /**
     * APIProperty: onUnhighlighted
     * {Function} Optional function to be called when Features are unhighlighted.
     *     The function shall be called an {Array(<OpenLayers.Feature.Vector>)}.
     */
    onUnhighlighted: function (features) {},

    /**
     * APIProperty: blockScope
     * This attribute provides the scope for the onBlockHighlighted, onBlockSelected, and
     * onClickout call backs.
     */
    blockScope : null,

    /**
     * Attribute: onBlockHighlighted
     * This method is called when there is a mouse event that selects
     * features for highlighting and unhighlighting. This function drives highlightAndTriguer
     * and unhighlight calls for individual Features and the above callbacks.
     * Override this to act as a block.
     */
    onBlockHighlighted : function (inFeatures, outFeatures) {
        this.highlightAndTrigger(inFeatures);
        this.unhighlight(outFeatures);
    },

    /**
     * Attribute: onBlockSelected
     * This method is called when there is a mouse event that selects
     * features for selection. This function drives selectAndTriguer
     * and unselect for individual Features and the above callbacks. Override this to act as a
     * block.
     */
    onBlockSelected : function (inFeatures, outFeatures) {
        this.selectAndTrigger(inFeatures);
        this.unselect(outFeatures);
    },

    /**
     * APIProperty: onClickout
     * {Function} If clickout is true, this function shall be called on a clickout.
     */
    onClickout : function () {},

    /**
     * APIProperty: mouseScope
     * This is the scope of mouse clicks for callbacks onMove, onPause, onClick.
     * If null, it defaults to this object;
     */
    mouseScope : null,

    /**
     * APIProperty: onMove
     * {Function} If set, then this callback will be called when a move of the
     * mouse happens.
     * It will be called with the inFeatures, and the outFeatures under the mouse.
     * onMove : function (inFeatures, outFeatures) {}
     * WARNING: This call can result in intensive calculative behavior as it will
     * scan for the feature geometries on every mouse move. If there are a lot of
     * complex features, this could render slowly.
     */
    onMove : null,

    /**
     * APIProperty: onPause
     * {Function} If set, then this callback will be called when a pause of
     * the mouse happens.
     * It will be called with the inFeatures, and the outFeatures under the mouse.
     * onPause : function (inFeatures, outFeatures) {}
     */
    onPause : null,

    /**
     * APIProperty: onClick
     * {Function} If set, then this callback will be called when a click happens.
     * It will be called with the inFeatures, and the outFeatures under the mouse.
     * onClick : function (inFeatures, outFeatures) {}
     */
    onClick : null,

    /**
     * APIProperty: geometryTypes
     * {Array(String)} To restrict selecting to a limited set of geometry types,
     *     send a list of strings corresponding to the geometry class names.
     */
    geometryTypes: null,

    /**
     * Property: layer
     * {<OpenLayers.Layer.Vector>} The vector layer with a common renderer
     * root for all layers this control is configured with (if an array of
     * layers was passed to the constructor), or the vector layer the control
     * was configured with (if a single layer was passed to the constructor).
     */
    layer: null,

    /**
     * Property: layers
     * {Array(<OpenLayers.Layer.Vector>)} The layers this control will work on,
     * or null if the control was configured with a single layer
     */
    layers: null,

    /**
     * APIProperty: callbacks
     * {Object} The functions that are sent to the handlers for callbacks.
     */
    callbacks: null,

    /**
     * Property: selectIntent
     * {String} key used to retrieve the select style from the layer's
     * style map, if selectStyle is not set.
     */
    selectIntent: "select",

    /**
     * Property: highlightIntent
     * {String} key used to retrieve the highlight style from the layer's
     * style map, if highlightStyle is not set. Highlight will use select
     * styles if highlightIntent and highlightStyle is not set.
     */
    highlightIntent: "highlight",

    /**
     * APIProperty: selectStyle
     * {<OpenLayers.Style>} the style to use for the selected features. Overrides
     * the selectIntent property.
     */
    selectStyle: null,

    /**
     * APIProperty: highlightStyle
     * {<OpenLayers.Style>} the style to use for the highlighted features. Overrides
     * the highlightIntent property. Highlight will use select
     * styles if highlightIntent and highlightStyle is not set.
     */
    highlightStyle: null,

    /**
     * Property: handlers
     * {Object} Object with references to multiple <OpenLayers.Handler>
     *     instances.
     */
    handlers: null,

    /**
     * Constructor: OpenLayers.Control.SelectFeature
     * Create a new control for selecting features.
     *
     * Parameters:
     * layers - {<OpenLayers.Layer.Vector>}, or {Array(<OpenLayers.Layer.Vector>)}. The
     *     layer(s) this control will select or highlight features from.
     * options - {Object}
     */
    initialize: function (layers, options) {
        // concatenate events specific to this control with those from the base
        this.EVENT_TYPES =
            BusPass.SelectAllFeature.prototype.EVENT_TYPES.concat(
                OpenLayers.Control.prototype.EVENT_TYPES
            );
        OpenLayers.Control.prototype.initialize.apply(this, [options]);

        if (this.scope === null) {
            this.scope = this;
        }
        if (this.blockScope === null) {
            this.blockScope = this;
        }
        if (this.mouseScope === null) {
            this.mouseScope = this;
        }

        this.initLayer(layers);

        var callbacks = {
            click: this.clickPosition,
            move : this.overPosition,
            pause : this.pausePosition
        };

        this.callbacks = OpenLayers.Util.extend(callbacks, this.callbacks);
        this.handlers = {
            hover: new OpenLayers.Handler.Hover(
                this, this.callbacks
            ),
            click: new OpenLayers.Handler.Click(
                this, this.callbacks
            )
        };

        this.highlighted = [];
        this.selected = [];
    },

    /**
     * Method: initLayer
     * Assign the layer property. If layers is an array, we use
     *     a {<OpenLayers.Layer.Vector.RootContainer>}.
     *
     * Parameters:
     * layers - {<OpenLayers.Layer.Vector>}, or {Array(<OpenLayers.Layer.Vector>)}.
     */
    initLayer: function (layers) {
        if (OpenLayers.Util.isArray(layers)) {
            this.layers = layers;
            this.layer = new OpenLayers.Layer.Vector.RootContainer(
                this.id + "_container",
                {
                    layers: layers
                }
            );
        } else {
            this.layer = layers;
        }
    },

    /**
     * Method: destroy
     */
    destroy: function () {
        if (this.active && this.layers) {
            this.map.removeLayer(this.layer);
        }
        OpenLayers.Control.prototype.destroy.apply(this, arguments);
        if (this.layers) {
            this.layer.destroy();
        }
    },

    /**
     * Method: activate
     * Activates the control.
     *
     * Returns:
     * {Boolean} The control was effectively activated.
     */
    activate: function () {
        if (!this.active) {
            if (this.layers) {
                this.map.addLayer(this.layer);
            }
            if (this.handlers.hover) {
                this.handlers.hover.activate();
            }
            if (this.handlers.click) {
                this.handlers.click.activate();
            }
        }
        return OpenLayers.Control.prototype.activate.apply(
            this, arguments
        );
    },

    /**
     * Method: deactivate
     * Deactivates the control.
     *
     * Returns:
     * {Boolean} The control was effectively deactivated.
     */
    deactivate: function () {
        if (this.active) {
            if (this.handlers.hover) {
                this.handlers.hover.deactivate();
            }
            if (this.handlers.click) {
                this.handlers.click.deactivate();
            }

            if (this.layers) {
                this.map.removeLayer(this.layer);
            }
        }
        return OpenLayers.Control.prototype.deactivate.apply(
            this, arguments
        );
    },

    /**
     * Method: unselectAll
     * Unselect all selected features.  To unselect all except for a single
     *     feature, set the options.except property to the feature. Do not
     *     trigger any events.
     *
     * Parameters:
     * options - {Object} Optional configuration object.
     */
    unselectAll: function (options) {
        // we'll want an option to supress notification here
        var layers = this.layers || [this.layer];
        var layer, feature;
        var unselected = [];
        if (this.highlighted) {
            this.unhighlight(this.highlighted);
        }
        var l;
        for (l = 0; l < layers.length; ++l) {
            layer = layers[l];
            var i;
            for (i = layer.selectedFeatures.length - 1; i >= 0; --i) {
                feature = layer.selectedFeatures[i];
                if (!options || options.except != feature) {
                    unselected.push(feature);
                }
            }
        }
        this.unselect(unselected);
    },

    getAllSelectedFeatures : function () {
        // we'll want an option to suppress notification here
        var layers = this.layers || [this.layer];
        var layer, feature;
        var selected = [];
        var l, len;
        for (l = 0, len = layers.length; l < len; ++l) {
            layer = layers[l];
            var i;
            for (i = layer.selectedFeatures.length - 1; i >= 0; --i) {
                feature = layer.selectedFeatures[i];
                selected.push(feature);
            }
        }
        return selected;
    },

    /**
     * Method: multipleSelect
     * Allow for multiple selected features based on <multiple> property and
     *     <multipleKey> event modifier.
     *
     * Returns:
     * {Boolean} Allow for multiple selected features.
     */
    multipleSelect: function () {
        //TODO figure out multipleKey
        return this.multiple;
//         || (this.handlers.click.evt &&
//               this.handlers.click.evt[this.multipleKey]);
    },

    /**
     * Method: redrawHighlighted
     * This method sets the style on the feature for being highlighted.
     */
    redrawHighlighted : function (feature) {
        var style = this.highlightStyle || this.highlightIntent || this.selectStyle || this.selectIntent;
        feature.layer.drawFeature(feature, style);
    },

    /**
     * Method: redrawSelected
     * This method sets the style on the feature for being selected.
     */
    redrawSelected : function (feature) {
        var style = this.selectStyle || this.selectIntent;
        feature.layer.drawFeature(feature, style);
    },

    /**
     * Method: redrawNormal
     * This method sets the style on the feature to its original style or default.
     */
    redrawNormal : function (feature) {
        feature.layer.drawFeature(feature, feature.style || feature.layer.style ||
            "default");
    },

    /**
     * Method: redraw
     * This method sets the style on the feature to its current to trigger a redraw.
     */
    redraw : function (feature) {
        feature.layer.drawFeature(feature, feature.renderIntent || "default");
    },

    /**
     * Method: highlight
     * Redraw feature with the highlight or select style. Do not trigger any
     *      highlight events.
     *
     * Parameters:
     * features - {<OpenLayers.Feature.Vector>} or {Array(OpenLayers.Feature.Vector)}
     */
    highlight : function (features) {
        if (!OpenLayers.Util.isArray(features)) {
            features = [features];
        }
        var i;
        for (i = 0; i < features.length; i++) {
            var feature = features[i];
            this.redrawHighlighted(feature);
            this.highlighted.push(feature);
            feature.__highlighted = true;
        }
    },

    /**
     * Method: highlightAndTrigger
     * Redraw feature with the highlight or select style and trigger highlight events.
     * This method is usually called by a mouse event.
     *
     * Parameters:
     * features - {<OpenLayers.Feature.Vector>} or {Array(OpenLayers.Feature.Vector)}
     */
    highlightAndTrigger: function (features) {
        if (!OpenLayers.Util.isArray(features)) {
            features = [features];
        }
        var highlighted = [];
        var i;
        for (i = 0; i < features.length; i++) {
            var feature = features[i];
            var layer = feature.layer;
            var cont = this.onBeforeHighlightFeature.call(this.scope, feature);
            if (cont !== false) {
                cont = this.events.triggerEvent("beforefeaturehighlighted", {
                    feature : feature
                });
                if (cont !== false) {
                    this.redrawHighlighted(feature);
                    highlighted.push(feature);
                    feature.__highlighted = true;
                    feature.__highlightedTriggered = true;
                    this.highlighted.push(feature);
                    this.events.triggerEvent("featurehighlighted", {feature : feature});
                }
            }
        }
        if (highlighted.length > 0) {
            this.onHighlighted.call(this.scope, highlighted);
        }
    },

    /**
     * Method: unhighlight
     * This method unhighlights the feature. If the feature was selected, it redraws
     * back to its "select" style. If a feature triggered an *featurehighlighted* event,
     * for consistency, a *featureunhighlighted* event is triggered.
     *
     * Parameters:
     * features - {<OpenLayers.Feature.Vector>} or {Array(OpenLayers.Feature.Vector)}
     */
    unhighlight: function (features) {
        if (!OpenLayers.Util.isArray(features)) {
            features = [features];
        }
        var removed = [];
        var i, feature, layer;
        for (i = 0; i < features.length; i++) {
            feature = features[i];
            layer = feature.layer;
            // Some calls give this.highlighted to this call, so we delay removal.
            removed.push(feature);

            // TODO: Why would this feature not have a layer?
            if (layer && OpenLayers.Util.indexOf(layer.selectedFeatures, feature) != -1) {
                this.redrawSelected(feature);
            } else {
                this.redrawNormal(feature);
            }
        }
        var triggers = [];
        for (i = 0; i < removed.length; i++) {
            feature = removed[i];
            OpenLayers.Util.removeItem(this.highlighted, feature);
            if (feature.__highlightedTriggered) {
                triggers.push(feature);
            }
        }
        if (triggers.length > 0) {
            for(i = 0; i < triggers.length; i++) {
                feature = triggers[i];
                this.events.triggerEvent("featureunhighlighted", {feature : feature});
                feature.__highlightedTriggered = false;
            }
            this.onUnhighlighted.call(this.scope, triggers);
        }
    },

    /**
     * Method: select
     * Add feature to the layer's selectedFeature array, render the feature as
     * selected, and call the onSelected function. This method unhighlights all
     * features, and triggers unhighlight events if they did trigger a
     * highlighted event when highlighted.
     *
     * Parameters:
     * features - {<OpenLayers.Feature.Vector>} or {Array(OpenLayers.Feature.Vector)}
     */
    select: function (features) {
        if (!OpenLayers.Util.isArray(features)) {
            features = [features];
        }
        if (this.highlighted) {
            this.unhighlight(this.highlighted);
        }
        // if multiple is false, first deselect currently selected features
        if (!this.multipleSelect()) {
            this.unselectAll();
        }
        var i, feature, layer;
        for (i = 0; i < features.length; i++) {
            feature = features[i];
            layer = feature.layer;
            // TODO: Why would this feature not have a layer?
            if (layer) {
                layer.selectedFeatures.push(feature);
                feature.__selected = true;
                this.redrawSelected(feature);
            }
        }
    },

    /**
     * Method: selectAndTrigger
     * Add the features to the layer's selectedFeature array, render the feature as
     * selected, and call the onSelected function. Will unhighlight all features highlighted
     * by this control.  This method is usually called by a mouse event.
     *
     * Parameters:
     * features - {<OpenLayers.Feature.Vector>} or {Array(OpenLayers.Feature.Vector)}
     */
    selectAndTrigger: function (features) {
        if (!OpenLayers.Util.isArray(features)) {
            features = [features];
        }
        if (this.highlighted) {
            this.unhighlight(this.highlighted);
        }
        // if multiple is false, first deselect currently selected features
        if (!this.multipleSelect()) {
            this.unselectAll();
        }

        features = this.onBeforeSelect.call(this.scope, features);
        var selected = [];
        var i, feature, layer;
        for (i = 0; i < features.length; i++) {
            feature = features[i];
            layer = feature.layer;
            var cont = this.onBeforeSelectFeature.call(this.scope, features);
            // TODO: Why would this feature not have a layer?
            if (cont !== false && layer) {
                cont = layer.events.triggerEvent("beforefeatureselected", {
                    feature: feature
                });
                if (cont !== false) {
                    selected.push(feature);
                    layer.selectedFeatures.push(feature);
                    feature.__selected = true;
                    feature.__selectedTriggered = true;
                    this.redrawSelected(feature);
                    layer.events.triggerEvent("featureselected", {feature: feature});
                }
            }
        }
        if (selected.length > 0) {
            this.onSelected.call(this.scope, selected);
        }
    },

    /**
     * Method: unselect
     * Remove feature from the layer's selectedFeature array, render the feature as
     * normal, and call the onUnselected function. If selection triggered a featureselected
     * event by this control, then to maintain consitency it will trigger a
     * featureunselected event.
     *
     * Parameters:
     * features - {<OpenLayers.Feature.Vector>} or {Array(OpenLayers.Feature.Vector)}
     */

    unselect : function (features) {
        if (!OpenLayers.Util.isArray(features)) {
            features = [features];
        }
        if (this.highlighted) {
            this.unhighlight(this.highlighted);
        }
        var unselected = [];
        var i, feature, layer;
        for (i = 0; i < features.length; i++) {
            feature = features[i];
            layer = feature.layer;
            // Store feature style for restoration later
            if (layer) {
                this.redrawNormal(feature);
                unselected.push(feature);
            }
        }
        var triggered = [];
        for (i = 0; i < unselected.length; i++) {
            feature = unselected[i];
            layer = feature.layer;
            if (layer) {
                OpenLayers.Util.removeItem(layer.selectedFeatures, feature);
                feature.__selected = false;
                if (feature.__selectedTriggered) {
                    triggered.push(feature);
                }
            }
        }
        for (i = 0; i < triggered.length; i++) {
            feature = triggered[i];
            layer = feature.layer;
            if (layer) {
                feature.__selectedTriggered = false;
                layer.events.triggerEvent("featureunselected", {feature: feature});
            }
        }
        if (triggered.length > 0) {
            this.onUnselected.call(this.scope, triggered);
        }
    },

    /**
     * Method: featuresUnder
     * Returns the features underneath the position.
     *
     * Parameters:
     * position - {<OpenLayers.Bounds> || <OpenLayers.Pixel> }
     */
    featuresUnder: function (position) {
        var inFeatures = [];
        var outFeatures = [];
        var lonlat = this.map.getLonLatFromPixel(position);
        var boundsGeometry = new OpenLayers.Geometry.Polygon.createRegularPolygon(
            new OpenLayers.Pixel(lonlat.lon, lonlat.lat),
            this.pointRadius * this.map.resolution, 20);
        // because we're using a box, we consider we want multiple selection
        var prevMultiple = this.multiple;
        this.multiple = true;
        var layers = this.layers || [this.layer];
        var layer;
        var l;
        for (l = 0; l < layers.length; ++l) {
            layer = layers[l];
            var i, len;
            for (i = 0, len = layer.features.length; i < len; ++i) {
                var feature = layer.features[i];
                // check if the feature is displayed
                if (!feature.getVisibility()) {
                    outFeatures.push(feature);
                    continue;
                }

                if (this.geometryTypes == null || OpenLayers.Util.indexOf(
                        this.geometryTypes, feature.geometry.CLASS_NAME) > -1) {
                    if (boundsGeometry.intersects(feature.geometry)) {
                        inFeatures.push(feature);
                    } else {
                        outFeatures.push(feature);
                    }
                } else {
                    outFeatures.push(feature);
                }
            }
        }
        this.multiple = prevMultiple;
        return { in: inFeatures, out: outFeatures };
    },

    overPosition : function (evt) {
        var i;
        var position = evt.xy;
        var highlightFeatures = null, selectFeatures = null;
        console.log("SelectAllFeature.overPosition: " + position.x + " " + position.y + " " + this.highlightPolicy);
        if (this.highlightPolicy === "onMove") {
            highlightFeatures = this.featuresUnder(position);
        }
        if (this.selectPolicy === "onMove" || highlightFeatures != null && this.selectPolicy === "onHighlight") {
            selectFeatures = highlightFeatures ? highlightFeatures : this.featuresUnder(position);
        }
        if (this.onMove) {
            var features = selectFeatures ? selectFeatures :
               (highlightFeatures ? highlightFeatures : this.featuresUnder(position));
            this.onClick.call(this.mouseScope, [features.in, features.out]);
        }
        if (this.unhighlightPolicy === "onMove") {
            if (highlightFeatures != null) {
                this.onBlockHighlighted.call(this.blockScope, highlightFeatures.in, highlightFeatures.out);
            } else {
                this.onBlockHighlighted.call(this.blockScope, [], this.highlighted);
            }
        } else {
            if (highlightFeatures != null) {
                this.onBlockHighlighted.call(this.blockScope, highlightFeatures.in, highlightFeatures.out);
            }
        }
        if (this.unselectPolicy === "onMove") {
            if (selectFeatures != null) {
                this.onBlockSelected.call(this.blockScope, selectFeatures.in, selectFeatures.out);
            } else {
                this.onBlockSelected.call(this.blockScope, [], this.selected);
            }
        } else {
            if (selectFeatures != null) {
                this.onBlockSelected.call(this.blockScope, selectFeatures.in, selectFeatures.out);
            }
        }
        return true;
    },

    pausePosition : function (evt) {
        var i;
        var position = evt.xy;
        var highlightFeatures = null, selectFeatures = null;
        console.log("SelectAllFeature.pausePosition: " + position.x + " " + position.y + " " + this.highlightPolicy);
        if (this.highlightPolicy === "onPause") {
            highlightFeatures = this.featuresUnder(position);
        }
        if (this.selectPolicy === "onPause" || highlightFeatures != null && this.selectPolicy === "onHighlight") {
            selectFeatures = highlightFeatures ? highlightFeatures : this.featuresUnder(position);
        }
        if (this.onPause) {
            var features = selectFeatures ? selectFeatures :
               (highlightFeatures ? highlightFeatures : this.featuresUnder(position));
            this.onClick.call(this.mouseScope, [features.in, features.out]);
        }
        if (this.unhighlightPolicy === "onPause") {
            if (highlightFeatures != null) {
                this.onBlockHighlighted.call(this.blockScope, highlightFeatures.in, highlightFeatures.out);
            } else {
                this.onBlockHighlighted.call(this.blockScope, [], this.highlighted);
            }
        } else {
            if (highlightFeatures != null) {
                this.onBlockHighlighted.call(this.blockScope, highlightFeatures.in, highlightFeatures.out);
            }
        }
        if (this.unselectPolicy === "onPause") {
            if (selectFeatures != null) {
                this.onBlockSelected.call(this.blockScope, selectFeatures.in, selectFeatures.out);
            } else {
                this.onBlockSelected.call(this.blockScope, [], this.selected);
            }
        } else {
            if (selectFeatures != null) {
                this.onBlockSelected.call(this.blockScope, selectFeatures.in, selectFeatures.out);
            }
        }
        return true;
    },

    clickPosition : function (evt) {
        var i;
        var position = evt.xy;
        var highlightFeatures = null, selectFeatures = null;
        console.log("SelectAllFeature.clickPosition: " + position.x + " " + position.y + " " + this.highlightPolicy);
        if (this.highlightPolicy === "onClick") {
            highlightFeatures = this.featuresUnder(position);
        }
        if (this.selectPolicy === "onClick" || highlightFeatures != null && this.selectPolicy === "onHighlight") {
            selectFeatures = highlightFeatures ? highlightFeatures : this.featuresUnder(position);
        }
        if (this.onClick) {
            var features = selectFeatures ? selectFeatures :
               (highlightFeatures ? highlightFeatures : this.featuresUnder(position));
            this.onClick.call(this.mouseScope, [features.in, features.out]);
        }
        if (this.unhighlightPolicy === "onClick") {
            if (highlightFeatures != null) {
                this.onBlockHighlighted.call(this.blockScope, highlightFeatures.in, highlightFeatures.out);
            } else {
                this.onBlockHighlighted.call(this.blockScope, [], this.highlighted);
            }
        } else {
            if (highlightFeatures != null) {
                this.onBlockHighlighted.call(this.blockScope, highlightFeatures.in, highlightFeatures.out);
            }
        }
        if (this.unselectPolicy === "onClick") {
            if (selectFeatures != null) {
                this.handleClickout(selectFeatures);
            } else {
                // This will clickout if set.
                this.handleClickout({ in: [], out : this.selected });
            }
        } else {
            if (selectFeatures != null) {
                this.handleClickout(selectFeatures);
            }
        }
        return true;
    },

    /**
     * Method: handleClickout
     * This method is called from clickPosition to handle a clickout on the selection.
     */
    handleClickout : function (features) {
        if (features.in.length == 0) {
            if (this.clickout) {
                console.log("SelectAllFeature.clickPosition: Clickout" );
                var selected = this.getAllSelectedFeatures();
                this.onBlockSelected.call(this.blockScope, [], selected);
                this.onClickout.call(this.blockScope);
            } else {
                this.onBlockSelected.call(this.blockScope, features.in, features.out);
            }
        } else {
            this.onBlockSelected.call(this.blockScope, features.in, features.out);
        }
    },

/*
    pausePosition : function (evt) {
        var i;
        var position = evt.xy;
        console.log("SelectAllFeature.pausePosition: " + this.CLASS_NAME);
        console.log("SelectAllFeature.pausePosition: " + position.x + " " + position.y + " " + this.highlightPolicy);
        console.log("SelectAllFeature.pausePosition: " + (this.highlightPolicy === "onPause"));
        if (this.highlightPolicy === "onPause") {
            var features = { in: [], out:[] };
            features = this.featuresUnder(position);
            console.log("   features selected " + features.in.length + " features unselected " + features.out.length);
            this.onBlockHighlighted.call(this.blockScope, features.in, features.out);
            this.paused = features.in;
        }
        return true;
    },

    clickPosition : function (evt) {
        var i;
        var position = evt.xy;
        console.log("SelectAllFeature.clickPosition: " + position.x + " " + position.y);
        // if multiple is false, first deselect currently selected features
        if (!this.multipleSelect()) {
            var selected = this.getAllSelectedFeatures();
            this.onBlockSelected.call(this.blockScope, [], selected);
        }
        var features = this.featuresUnder(position);
        if (features.in.length == 0) {
            if (this.clickout) {
                console.log("SelectAllFeature.clickPosition: ClickOUT " + position.x + " " + position.y);
                var selected = this.getAllSelectedFeatures();
                this.onBlockSelected.call(this.blockScope, [], selected);
                this.onClickout.call(this.blockScope);
            } else {
                this.onBlockSelected.call(this.blockScope, features.in, features.out);
            }
        } else {
            this.onBlockSelected.call(this.blockScope, features.in, features.out);
        }
        return true;
    },*/

    /**
     * Method: setMap
     * Set the map property for the control.
     *
     * Parameters:
     * map - {<OpenLayers.Map>}
     */
    setMap: function (map) {
        this.handlers.hover.setMap(map);
        this.handlers.click.setMap(map);
        OpenLayers.Control.prototype.setMap.apply(this, arguments);
    },

    /**
     * APIMethod: setLayer
     * Attach a new layer to the control, overriding any existing layers.
     *
     * Parameters:
     * layers - Array of {<OpenLayers.Layer.Vector>} or a single
     *     {<OpenLayers.Layer.Vector>}
     */
    setLayer: function (layers) {
        var isActive = this.active;
        this.unselectAll();
        this.deactivate();
        if (this.layers) {
            this.layer.destroy();
            this.layers = null;
        }
        this.initLayer(layers);
        if (isActive) {
            this.activate();
        }
    },

    CLASS_NAME: "BusPass.SelectAllFeature"
});
