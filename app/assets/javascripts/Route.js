/**
 * Route
 *
 * @param data
 * @constructor
 *
 * = require_self
 */
Route = function(data) {
    this._selected = false;
    this._pathVisible = true;
    this._nameVisible = true;
    $.extend(this,data);
};

Route.prototype = {
    _nw_lon: null,
    _nw_lat : null,
    _se_lon : null,
    _se_lat : null,
    _startOffset : null,
    _duration : null,
    _startTime : null,
    _endTime : null,

    _geoJSONUrl : null,
    getGeoJSONUrl : function() {
        return this._geoJSONUrl;
    },

    _nameId : null,
    getNameId : function() {
        return {
            name : this._name,
            id : this._id
        }
    },

    _id : this.id,
    getId : function() {
        return this._id;
    },

    _name : this.name,
    getName : function() {
        return this._name;
    },

    _code : this.code,
    getCode: function() {
        return this._code;
    },

    _paths : null,
    getPaths : function() {
        return this._paths;
    },

    getPath : function(index) {
        return this._paths[index];
    },

    _lastKnownTimeDiff: null,
    getLastKnownTimeDiff : function () {
        return this._lastKnownTimeDiff;
    },

    _lastKnownTime: null,
    getLastKnownTime : function () {
        return this._lastKnownTime;
    },

    _lastKnownLocation: null,
    getLastKnownLocation : function () {
        return this._lastKnownLocation;
    },

    _lastKnownDirection: null,
    getLastKnownDirection : function () {
        return this._lastKnownDirection;
    },

    _onRoute : null,
    isOnRoute : function() {
        return this._onRoute;
    },

    _type : this.type,
    getType : function() {
        return this._type;
    },

    _version : null,
    getVersion : function () {
        return this._version;
    },

    isJourney : function() {
        return this._type == "journey";
    },

    isActiveJourney : function() {
        return this._type == "journey";
    },

    isRouteDefinition : function() {
        return this._type == "route";
    },

    _locationRefreshRate : null,
    getLocationRefreshRate : function() {
        return this._locationRefreshRate;
    },

    _zoomCenter : null,
    getZoomCenter : function() {
        return this._zoomCenter;
    },

    isNearRoute : function(where, buffer) {
        // TODO: fill in
    },

    pollForCurrentLocation : function() {
        // TODO: fill in.
    },

    getStartTime : function () {
        return this._startTime;
    },

    getEndTime : function () {
        return this._endTime;
    },

    // Display Stuff
    /**
     * Method: setSelected
     * This method sets the isSelected boolean.
     * It is called when one of the vector features
     * is selected by the Map.
     *
     * Parameters
     * select  boolean
     */
    setSelected : function(select) {
        this._selected = select;
    },

    /**
     * Method: isSelected
     * This method returns whether the Route is selected in the Display
     * Area.
     *
     * Returns
     * boolean
     */
    isSelected : function() {
        return this._selected;
    },

    isHighlightable : function() {
        return this._isHighlightable;
    },

    setHighlightable : function(state) {
        this._isHighlightable = state;
    },

    // JourneyDisplay Stuff

    getDisplayName : function () {
        return this.getName();
    },

    setNameVisible : function (state) {
        this._nameVisible = state;
    },

    isNameVisible : function () {
        return this._nameVisible;
    },

    setNameHighlighted : function (state) {
        this._nameHighlighted = state;
    },

    isNameHighlighted : function () {
        return this._nameHighlighted;
    },

    // MapView Controller

    setPathVisible : function (state) {
        this._pathVisible = state;
    },

    isPathVisible : function () {
        return this._pathVisible;
    },

    setTracking : function (state) {
        this._tracking = state;
    },

    isTracking : function () {
        return this._tracking;
    },

    setHasActiveJourneys : function (state) {
        this._hasActiveJourneys = state;
    },

    hasActiveJourneys : function () {
        return this._hasActiveJourneys;
    },

    // Compatability with JourneyDisplay in Java
    getRoute : function () {
        return this;
    },

    onJourneyDisplayLocationUpdateListener : {
        onJourneyDisplayLocationUpdate : function(journeyDisplay, locations) {}
    },

    // JourneyDisplay is a location update listener.
    onLocationUpdate : function(route, locations) {
        this.onJourneyDisplayLocationUpdateListener.onJourneyDisplayLocationUpdate(this, locations);
    },


};