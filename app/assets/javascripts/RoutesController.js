/**
 * Class: RoutesController
 * 
 * This class is mainly set up for a test between the
 * MapViewController and the ListViewController.
 */
BusPass.RoutesController = function(options) {
    this._routes = [];
    $.extend(this,options);
    this._mapViewC = new BusPass.MapViewController({
        scope : this,
        onRouteSelected : this._onMapRouteSelect,
        onRouteUnselected : this._onMapRouteUnselect,
        onRouteHighlighted : this._onMapRouteHighlight,
        onRouteUnhighlighted : this._onMapRouteunhighlight
    });
    this._listViewC = new BusPass.ListViewController({
        scope : this,
        onRouteSelected : this._onListRouteSelect,
        onRouteUnselected : this._onListRouteUnselect,
        onRouteHighlighted : this._onListRouteHighlight,
        onRouteUnhighlighted : this._onListRouteUnhighlight
    });
};

BusPass.RoutesController.prototype = {
    /**
     * Attribute: scope
     * This attribute is the context for the onRouteSelect,
     * onRouteUnselect, onRouteHighlight, and onRouteUnhighlight
     * callbacks.
     */
    scope : null,

    onRouteSelected : function () {},

    onRouteUnselected : function () {},

    onRouteHighlighted : function () {},

    onRouteUnhighlighted : function () {},

    mapView : function (jq) {
        this._mapViewC.mapView(jq);
    },

    listView : function (jq) {
        this._listViewC.listView(jq);
    },

    addRoute : function(route) {
        this._routes.push(route);
        this._listViewC.addRoute(route);
        this._mapViewC.addRoute(route);
        this._mapViewC.redraw();
        this._listViewC.redraw();
    },

    removeRoute : function(route) {
        var rs = [];
        for(r in this._routes) {
        if (this._routes[r] != route) {
            rs.push(this._routes[r]);
        };
        }
        this._listViewC.removeRoute(route);
        this._mapViewC.removeRoute(route);
    },

    _onMapRouteSelect : function(route) {
        // The map doesn't trigger an unhighlight when selected.
        this._listViewC.unhighlightRouteNoTrigger(route);
        this._listViewC.selectRouteNoTrigger(route);
        this.onRouteSelected(route);
    },

    _onListRouteSelect : function(route) {
        // The mouseout doesn't happen, so we force an unhighlight
        this._listViewC.unhighlightRouteNoTrigger(route);
        this._mapViewC.selectRouteNoTrigger(route);
        this.onRouteSelected(route);
    },

    _onMapRouteUnselect : function(route) {
        this._listViewC.unselectRouteNoTrigger(route);
        this.onRouteUnselected(route);
    },

    _onListRouteUnselect : function(route) {
        this._mapViewC.unselectRouteNoTrigger(route);
        this.onRouteUnselected(route);
    },

    _onMapRouteHighlight : function(route) {
        this._listViewC.highlightRouteNoTrigger(route);
        this.onRouteHighlighted(route);
    },

    _onListRouteHighlight : function(route) {
        this._mapViewC.highlightRouteNoTrigger(route);
        this.onRouteHighlighted(route);
    },

    _onMapRouteunhighlight : function(route) {
        this._listViewC.unhighlightRouteNoTrigger(route);
        this.onRouteUnhighlighted(route);
    },

    _onListRouteUnhighlight : function(route) {
        this._mapViewC.unhighlightRouteNoTrigger(route);
        this.onRouteUnhighlighted(route);
    },

    // for testing
    setVisibility : function(route, state) {
        this._mapViewC.setVisibility(route, state);
        this._listViewC.setVisibility(route, state);
    },
    
    redraw : function () {
        this._mapViewC.redraw();
        this._listViewC.redraw();
    },
        
};
