/**
 * JourneyBasket
 *
 * This class manages the storage and retrieval of Routes
 * from the web. It replaces journeys with new versions
 * if need be.
 *
 *= require Route
 *= require_self
 */

/**
 * Constructor
 *
 * Attributes:
 *   buAPI  -  <BusPassAPI>  The Web API
 *   journeyStore - <JourneyStore>
 *           Keeps a semi persistent storage for the
 *           Journeys that are no longer in the basket.
 */
BusPass.JourneyBasket = function (options) {
    $.extend(this, options);
    this._pollTime = 10000;

    // Internal list of journey definitions.
    this._journeys = [];

    // Set up Worker.
    this._worker = new Worker(this.webWorkerUrl);
    var basket = this;
    this._worker.addEventListener('message', function(e) {
        var data = e.data;
        switch (data.cmd) {
            case 'loadJourneyIds':
                basket._loadJourneyIdsReturn(data);
                break;
            case 'fetchRoute':
                basket._onFetchRouteReturn(data);
                break;
            default:
                console.log("JourneyBasket: Unknown command from worker: " + data.msg);
        }
    }, false);

    this._worker.addEventListener( 'error', function (event) {
        console.log("JourneyBasket.worker: " + event.message, event);
    }, false);
};

BusPass.JourneyBasket.prototype = {
    /**
     * Attribute: webWorkerUrl
     * This attribute contains the URL for the web worker that
     * has two functions 'loadJourneyIds" and "fetchRoute". In
     * conjunction with differnt API maps, we may have various
     * configurations of the basket.
     */
    webWorkerUrl : "/assets/RouteWebWorker.js",

    /**
     * Attribute: busAPI
     *
     * This is the api for getting things from the web. We just
     * need to know if its logged in and have access to the API Map
     * which the Workers need to know.
     */
    busAPI : {
        apiMap : {
            getRouteDefinition : "", // RouteWebWorker.fetchRoute
            getJourneyIds : "",      // RouteWebWorker.loadJourneyIds
        },
        isLoggedIn : function () {}
    },

    /**
     * Attribute: journeyStore
     *
     * This object holds the secondary storage for Routes.
     */
    journeyStore : {
        storeJourney : function(route) {},
        getJourney : function(nameid) {}
    },

    /**
     * Attribute: OnJourneyAddedListener
     * Gets notified by onJourneyAdded(basket, route) if
     * a Journey is Added to the Basket.
     */
    onJourneyAddedListener :  {
        onJourneyAdded : function (basket, r) {}
    },

    /**
     * Attribute: onJourneyRemovedListener
     * Gets notified by onJourneyRemoved(basket, route) if
     * a Journey is removed from the Basket.
     */
    onJourneyRemovedListener : {
       onJourneyRemoved : function (basket, r) {}
    },

    /**
     * Attribute: onBasketUpdatedListener
     * Gets notified by onBasketUpdated(basket, route)
     * after a sync.
     */
    onBasketUpdatedListener : {
        onBasketUpdated : function (basket) {}
    },

    /**
     * Attribute: onIOErrorListener
     * Gets notified by onIOError(basket, route)
     * for any io error when trying to sync the
     * basket. It does not report not being able
     * to retrieve a particular route.
     */
    onIOErrorListener  : {
        onIOError : function (basket, ioe) {}
    },

    /**
     * Attribute: progressListener
     * This object gets notified at various points
     * in the sync.
     */
    progressListener : {
        onSyncStart : function () {},
        onSyncEnd : function (nRoutes) {},
        onRouteStart : function (iRoute,nRoutes) {},
        onRouteEnd : function (iRoute,nRoutes) {},
        onDone : function () {},
    },

    getJourneys : function () {
        return this._journeys;
    },

    /**
     * Method: sync
     * This method starts the sync process of the basket.
     */
    sync : function() {
        if (!this.busAPI.isLoggedIn()) {
            console.log("JourneyBasket.init: We are not logged on. Returning!");
            this._journeys = [];
            this.progressListener.onDone();
            return;
        }
        this._updateInProgress = true;
        this.progressListener.onSyncStart();
        // This is a relatively quick call.
        this._loadJourneyIds();
    },

    /**
     * Method: private _loadJourneyIds
     *
     * This method starts the Worker to load the list of
     * current journey ids from the API.
     */
    _loadJourneyIds : function() {
        this._worker.postMessage( {
            cmd: "loadJourneyIds",
            routeids : this.getForRouteIds(),
            apiMap: this.busAPI.apiMap,
        });
    },

    /**
     * Method: private _loadJourneyIdsReturn
     *
     * This method gets called upon return of data from the
     * worker on a _loadJourneyIds call.
     */
    _loadJourneyIdsReturn : function(data) {
        console.log("JourneyBasket._loadJourneyIdsReturn:" + $.toJSON(data));
        var status = data.status;
        switch (status) {
            case 'Start' :
                this.progressListener.onSyncStart();
                break;
            case 'Success':
                var journeyids = data.journeyids;
                this._onJourneyIdsLoaded(journeyids);
                break;
            case 'IOError':
                this._onJourneyIdsLoadError(data.message);
                break;
            default:
                console.log("JourneyBasket: Unknown response from worker - " + data.status);
        }
    },

    /**
     * Method: private _onJourneyIdsLoaded
     *
     * This method is called upon successful return of the current journeyids
     * from the website. It then starts the sync process on the particular
     * journeys.
     *
     * Parameters
     * journeyids - <NameId>  The current list from the web site.
     */
    _onJourneyIdsLoaded : function(journeyids) {
        this.progressListener.onSyncEnd(journeyids.length);
        this._sync(journeyids);
    },

    /**
     * Method: private _onJourneyIdsLoadError
     *
     * This method is called upon an error return of the current journeyids.
     * Notifies the progress listeners, and the onIOErrorListener.
     *
     * Parameters:
     * ioe  <String> Error message.
     */
    _onJourneyIdsLoadError : function(ioe) {
        console.log(ioe.message);
        this.onIOErrorListener.onIOError(this, ioe);
        this.progressListener.onSyncEnd(0);
        this.progressListener.onDone();
        this._updateInProgress = false;
        console.log("JourneyBasket: Error Loading JourneyIds :" + ioe.message);
    },

    /**
     * Method: _fetchRoute
     *
     * This method starts the process of getting a route definition from
     * the Worker.
     *
     * Parameters:
     * journeyid <NameId>  The Journey Nameid.
     * progress_index  <int>  The index for the purpose of the progressListener
     * end_progress_index <int> The amount of routes being retrieved.
     */
    _fetchRoute : function(journeyid, progress_index, end_progress_index) {
        console.log("JourneyBasket: Fetch Route "+ journeyid.name + ":" + journeyid.id + " version: " + journeyid.version);
        this._worker.postMessage( {
            cmd: "fetchRoute",
            apiMap: this.busAPI.apiMap,
            journeyid : journeyid,
            progress_index: progress_index,
            end_progress_index: end_progress_index
        });
    },

    /**
     * Method: _onFetchRouteReturn
     *
     * This method is called upon getting data back from the worker on a
     * _fetchRoute call. It notifies the progressListener and onBasketUpdatedListener
     * if the last route is returned.
     */
    _onFetchRouteReturn : function(data) {
        var status = data.status;
        switch (status) {
            case 'Start' :
                this.progressListener.onRouteStart(data.progress_index, data.end_progress_index);
                break;
            case 'Success':
                this.progressListener.onRouteEnd(data.progress_index, data.end_progress_index);
                if (data.progress_index == data.end_progress_index) {
                    this.progressListener.onDone();
                    this._updateInProgress = false;
                }
                var route = new Route(data.route);
                this.journeyStore.storeJourney(route);
                this._journeys.push(route);
                this.onJourneyAddedListener.onJourneyAdded(this, route);
                if (data.progress_index == data.end_progress_index) {
                    this.onBasketUpdatedListener.onBasketUpdated(this);
                }
                break;
            case 'IOError':
                this.progressListener.onRouteEnd(data.progress_index, data.end_progress_index);
                if (data.progress_index == data.end_progress_index) {
                    this.progressListener.onDone();
                    this.onBasketUpdatedListener.onBasketUpdated(this);
                    this._updateInProgress = false;
                }
                break;
            default:
                console.log("JourneyBasket: Unknown response from worker - " + data.status);
        }
    },

    /**
     * Method: private _sync
     *
     * This method goes through the list of journeys, and updates it from the
     * given list of journeyids, adds, removes, or fetches new routes accordingly.
     */
    _sync : function(journeyids) {
        function addAll(as,xs) {
            for(var i = 0; i < xs.length; i++) {
                as.push(xs[i]);
            }
            return as;
        }

        console.log("JourneyBasket: Syncing with "+journeyids.length+" journey ids");
        var copy_journeys = this._journeys.slice(0);
        var addedJourneys = [];
        var removedJourneys = [];
        var keepJourneys = [];
        var newJourneys = [];
        var journeyidsNeeded = [];
        for (var i = 0; i < journeyids.length; i++) {
            journeyid = journeyids[i];
            if (journeyid != null) {
                var addJourney = true;
                // If we don't find it in the displayed journeys then we have to add it, or
                // if we find it, but it's outdated.
                for(var j = 0; j < copy_journeys.length; j++) {
                    r = copy_journeys[j];
                    if(r.getId() == journeyid.id) {
                        console.log("JourneyBasket: Route " + r.getId() + " " + r.getName() + " " + r.getVersion() + " ?=? " + journeyid.version);
                        if (r.getVersion() < journeyid.version) {
                            console.log("JourneyBasket: Replacing Route "+ journeyid.name + ":" + journeyid.id + " version: " + r.getVersion() + " --> " + journeyid.version);
                            addJourney = true;
                            // Remove old route from the store. It will be replaced below.
                            this.journeyStore.removeJourney(r);
                        } else {
                            addJourney = false;
                        }
                        break;
                    }
                }
                if(addJourney) {
                    var route = this.journeyStore.getJourney(journeyid.id);
                    if (route == null) {
                        console.log("JourneyBasket: Need Route "+ journeyid.name + ":" + journeyid.id + " " + journeyid.version + " = " + route);
                        journeyidsNeeded.push(journeyid);
                    } else {
                        console.log("JourneyBasket: Adding Route "+ journeyid.name + ":" + journeyid.id + " " + journeyid.version + " = " + route);
                        addedJourneys.push(route);
                    }
                }
            }
        }
        // We look through the displayed journeys, and if we don't find its id, or
        // we do and its outdated, then we remove it from the display, because
        // we've already added its replacement.
        for(var j = 0; j < copy_journeys.length; j++) {
            var r = copy_journeys[j];
            var removeJourney = true;
            for(var k = 0; k < journeyids.length; k++) {
                var journeyid = journeyids[k];
                if(r.getId() == journeyid.id) {
                    if (r.getVersion() < journeyid.version) {
                        console.log("JourneyBasket: Removing Old Route "+ journeyid.name + ":" + journeyid.id + " version: " + r.getVersion() + " --> " + journeyid.version);
                        removeJourney = true;
                        // It's already been removed from the store above.
                    } else {
                        removeJourney = false;
                    }
                    break;
                }
            }
            if (removeJourney) {
                removedJourneys.push(r);
            } else {
                console.log("JourneyBasket: Keeping Route "+ r.getName() + " version: " + r.getVersion());
                keepJourneys.push(r);
            }
        }
        addAll(newJourneys, keepJourneys);
        addAll(newJourneys, addedJourneys);
        this._journeys = newJourneys;

        for(var i = 0; i < removedJourneys.length; i++) {
            var r = removedJourneys[i];
            this.onJourneyRemovedListener.onJourneyRemoved(this,r);
        }
        for(var i = 0; i < addedJourneys.length; i++) {
            var r = addedJourneys[i];
            this.onJourneyAddedListener.onJourneyAdded(this,r);
        }
        if (journeyidsNeeded.length > 0) {
            for(var i = 0; i < journeyidsNeeded.length; i++) {
                var r = journeyidsNeeded[i];
                this._fetchRoute(r, i+1, journeyidsNeeded.length);
            }
        } else {
            this.progressListener.onDone();
            this._updateInProgress = false;
            this.onBasketUpdatedListener.onBasketUpdated(this);
        }
    },

    /**
     * Method: empty
     *
     * This method empties the basket informing all listeners along the way.
     */
    empty : function () {
        var copy_journeys = this._journeys.splice(0);
        this._journeys = [];
        for(var i = 0; i < copy_journeys.length; i++) {
            var r = copy_journeys[i];
            this.onJourneyRemovedListener.onJourneyRemoved(this,r);
        }
        this.onBasketUpdatedListener.onBasketUpdated(this);
    },

    onCreate : function() {
        console.log("JourneyBasket: onCreate  prevState " + this._state + " updateInProgress" + this._updateInProgress);
        this._state = "CREATE";
    },

    onStart : function() {
        console.log("JourneyBasket: onStart  prevState " + this._state + " updateInProgress" + this._updateInProgress);
        this._state = "START";
        // If we are starting and there is already an update
        // in progress, let it continue. Only do the sync()
        // if it is not needed.
        if (!this._updateInProgress) {
            this.sync();
        }
    },

    _run : function () {
        var self = this;
        // Only call if there isn't one still working.
        // and don't call if we've been asked to stop.
        if (!this._updateInProgress) {
            if (!this._please_stop) {
                // TODO: We should run with different progress listeners
                this.sync();
                setTimeout(function () {
                    self._run()
                }, this._pollTime);
            }
        } else {
            if (!this._please_stop) {
                setTimeout(function () {
                    self._run()
                }, this._pollTime);
            }
        }
    },

    onResume : function () {
        console.log("JourneyBasket: onResume  prevState " + this._state + " updateInProgress " + this._updateInProgress);
        this._state = "RESUME";
        this._please_stop = false;
        var self = this;
        setTimeout(function () {
            self._run()
        }, this._pollTime);
    },

    onPause : function() {
        console.log("JourneyBasket: onPause  prevState " + this._state + " updateInProgress " + this._updateInProgress);
        this._state = "PAUSE";
        this._please_stop = true;
    },

    onStop : function() {
        console.log("JourneyBasket: onStop  prevState " + this._state + " updateInProgress " + this._updateInProgress);
        this._state = "STOP";
        this._please_stop = true;
    },

    onRestart : function () {
        console.log("JourneyBasket: onRestart  prevState " + this._state + " updateInProgress " + this._updateInProgress);
        this._state = "RESTART";
        // The user might have stopped the app and
        // restarted it so soon that the updates
        // didn't have a chance to quiesse. Therefore,
        // if there is an update in progress, we do
        // nothing and let it continue.  Otherwise, some
        // time may have gone by, so we just empty the
        // basket in preparation for another init.
        if (!this._updateInProgress) {
            this.empty();
            console.log("JourneyBasket: empty() ended");
        }
    },

    onDestroy : function () {
        console.log("JourneyBasket: onDestroy  prevState " + this._state + " updateInProgress " + this._updateInProgress);
        this._state = "DESTROY";

        // We really should empty here, but we'll let the update
        // continue. It will be destructively shut down anyway.
        if (!this._updateInProgress) {
            this.empty();
            console.log("JourneyBasket: empty() ended");
        }
    },

    forceSync : function(progressListener, onIOErrorListener) {
        if (this._updateInProgress) {
            this._worker.terminate();
            // TODO: Remove the Timeout for a Run here.
            this._please_stop = true;
        }
        this.progressListener = progressListener;
        this.onIOErrorListener = onIOErrorListener;
        this._init();
    },

    setForRoute : function(routeid) {
        this._forRouteIds = [];
        this._forRouteIds.push(routeid);
    },

    setForRoutes : function(routeids) {
        this._forRouteIds = routeids;
    },

    setNearbyDistance : function(distance) {
        this._neabyDistance = distance;
    },

    setLocation : function(geoPoint) {
        this._location = geoPoint;
    },

    getNearbyDistance : function() {
        return this._neabyDistance;
    },

    getForRouteId : function () {
        return this._forRouteIds[0];
    },

    getForRouteIds : function() {
        if (this._forRouteIds != null) {
            // This maybe full fledged routes, which we don't want to
            // marshal to the web worker.
            var nameids = $.map(this._forRouteIds,
                                function(x) {
                                    return { id : x._id, name: x._name, type: x._type };
                                });
            return nameids;
        } else {
            return null;
        }
    },

    getLocation : function () {
        return this._location;
    },

    getPollTime : function () {
        return this._pollTime;
    },

    setPollTime : function (pollTime) {
        console.log("Basket: PollTime set to " + pollTime);
        this._pollTime = pollTime;
    },

};

