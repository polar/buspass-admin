BusPass.JourneyBasketController = function (api,journeyBasket,routesController) {
    this._busAPI = api;
    this._journeyBasket = journeyBasket;
    this._routesC = routesController;
};

BusPass.JourneyBasketController.prototype = {

    onVisibilityChangedListener : {
        onVisibilityChanged : function(journeyBasketController) {}
    },

    onIOErrorListener : {
        onIOError : function(journeyBasketController, err) {}
    },

    onRouteDisplayAddedListner : {
        onRouteDisplayAddedPre : function(journeyBasketController, basket, journeyDisplay) {},
        onRouteDisplayAddedPost : function(journeyBasketController, basket, journeyDisplay) {}
    },

    onRouteDisplayRemovedListner : {
        onRouteDisplayRemovedPre : function(journeyBasketController, basket, journeyDisplay) {},
        onRouteDisplayRemovedPost : function(journeyBasketController, basket, journeyDisplay) {}
    },

    onJourneyAddedListener : {
        onJourneyAdded : function(basket, added) {
            console.log("JourneyBasketController: onJourneyAdded: " + added.getName());
            this.onRouteDisplayAddedListener.onRouteDisplayAddedPre(this,basket,added);
            // And this adds a whole lot of display stuff to the Route.
            this._routesC.addRoute(added);
            if(added.getRoute().isJourney()) {
                added.updater = new JourneyLocationUpdater(added);
                // The route is a listener
                added.updater.onJourneyLocationUpdateListener = added;
                if (this._updateInProgress && !this._please_stop) {
                    added.updater.startUpdate();
                }
            }
            this._journeyDisplays.push(added);
            this.onRouteDisplayAddedListener.onRouteDisplayAddedPost(this,basket,added);
        }
    },

    onJourneyRemovedListener : {
        onJourneyRemoved : function(basket, removed) {
            console.log("JourneyBasketController: onJourneyRemoved: " + removed.getName());
            this.onRouteDisplayRemovedListener.onRouteDisplayRemovedPre(this, this._journeyBasket, removed);
            if (removed != null && removed.updater != null) {
                removed.updater.stopUpdate();
                removed.updater = null;
            }
            this._routesC.removeRoute(removed);
            console.log("JourneyBasketController: removing RouteDisplay: Route " + removed.getName() + " version " + removed.getVersion();
            var i = this._journeyDisplays.indexOf(removed);
            if (i >= 0) {
                this._journeyDisplays.splice(i,1);
            }
            onRouteDisplayRemovedListener.onRouteDisplayRemovedPost(this,this._journeyBasket,removed);
        }
    },

    onUpdateListener : {
        onUpdate : function (journeyBasketController) {}
    },

    onJourneyBasketUpdateListener : {
        onUpdateBasket : function (basket) {
            this.onUpdateListener.onUpdate(this);
        }
    },

    onCreate : function () {
        console.log("JourneyBasketController: onCreate");
        this._state = "CREATE";
        this._journeyDisplays = [];
        this._journeyBasket.onJourneyAddedListener = this.onJourneyAddedListener;
        this._journeyBasket.onJourneyRemovedListener = this.onJourneyRemovedListener;
        this._journeyBasket.onJourneyBasketUpdatedListener = this.onJourneyBasketUpdatedListener;
        this._journeyBasket.onIOErrorListener = this.onIOErrorListener;
    },

    onStart : function() {
        console.log("JourneyBasketController: onStart");
        this._state = "START";
        this._journeyBasket.sync();
    },

    onResume : function () {
        console.log("JourneyBasketController: onResume");
        this._state = "RESUME";
        this._updateInProgress = true;
        this._please_stop = false;
        for( var i = 0; i < this._journeyDisplays.length; i++) {
            var r = this._journeyDisplays[i];
            if (r.updater != null) {
                r.updater.resumeUpdate();
            }
        }
    },

    onPause : function() {
        console.log("JourneyBasketController: onPause");
        this._state = "PAUSE";

        this._journeyBasket.onPause();
        this._please_stop = true;

        for( var i = 0; i < this._journeyDisplays.length; i++) {
            var r = this._journeyDisplays[i];
            if (r.updater != null) {
                r.updater.suspendUpdate();
            }
        }
        this._updateInProgress = false;
    },

    onStop : function () {
        console.log("JourneyBasketController: onStop");
        state = "STOP";

        this._journeyBasket.onStop();

        this._please_stop = true;
        for( var i = 0; i < this._journeyDisplays.length; i++) {
            var r = this._journeyDisplays[i];
            if (r.updater != null) {
                r.updater.stopUpdate();
                r.updater = null;
            }
        }
    },

    onRestart : function() {
        console.log("JourneyBasketController: onRestart");
        if (this._state != "STOP") {
            console.log("JourneyBasketController: Not in STOP State. Are we in FORCE SYNC?" + ("FORCE_SYNC" == this._state));
        }
        this._state = "RESTART";
        this._journeyBasket.onRestart();
    },

    onDestroy : function() {
        console.log("JourneyBasketController: onDestroy");
        this._state = "DESTROY";
        this._onUpdateListener = null;
        this._onRouteDisplayRemovedListener = null;
        this._onRouteDisplayAddedListener = null;
        this._onVisibilityChangedListener = null;
        this._journeyBasket.onDestroy();
    },

    forceSync : function(progressListener, ioerrorListener) {
        console.log("JourneyBasketController: forceSync");
        this._journeyBasket.forceSync(progressListener,ioerrorListener);
    },

    forceReload: function () {}
};