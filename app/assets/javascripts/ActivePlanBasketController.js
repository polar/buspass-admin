/**
 * ActivePlanBasketController
 *
 *= require BusPassAPI
 *= require JourneyBasket
 *= require ActivePlanController
 *= require JourneyStore
 *= require_self
 */
BusPass.ActivePlanBasketController = function(options) {
    options = $.extend({}, options);
    $.extend(this, options);

    var ctrl = this;

    if (options['loginUrl']) {
        this.initialize();
    }

    // Closure Functions
    this.onBackClick = function () {
        ctrl.onBackClickFunction.call(ctrl);
    };

    this.onLogin = function() {
        ctrl.onLoginFunction.call(ctrl);
    };
};

BusPass.ActivePlanBasketController.prototype = {
    debug : false,

    /**
     * This is the login URL for the BusPass API.
     */
    loginUrl : null,

    /**
     * The element that contains the Routes View List. If it is not specified in the options to activePlanView
     * it will be found as the first element with the class of ".activePlanRoutesView" underneath
     * the main element.
     */
    activePlanRoutesView : "#activePlanRoutesView",

    /**
     * The element that contains the Map. If it is not specified in the options to activePlanView
     * it will be found as the first element with the class of ".activePlanMapView" underneath
     * the main element.
     */
    activePlanMapView : "#activePlanMapView",

    /**
     * The element that contains the Back button. If it is not specified in the options to activePlanView
     * it will be found as the first element with the class of ".activePlanBackButton" underneath
     * the main element.
     */
    activePlanBackButton : "#activePlanBackButton",

    /**
     * The element that contains the Radio Button for Only Buses.
     * @param jq
     * @param options
     */
    activePlanOnlyBusesButton : "#activePlanOnlyBusesButton",

    /**
     * The element that contains the Radio Button for All Routes option.
     * @param jq
     * @param options
     */
    activePlanAllRoutesButton : "#activePlanAllRoutesButton",

    /**
     * This function initializes the ActivePlanBasketController short of starting it. It is meant to have
     * several visual UI components.
     *   .activePlanRoutesView        The specialized list view for routes.
     *   .activePlanMapView           The Map.
     *   .activePlanBackButton        The Back Button.
     * You may assign these with the options. If not assigned from the options, this function will find
     * them with the given class names.
     *
     * @param jq      The selector or element of the main UI component.
     * @param options Options that are merged with this ActivePlanBasketController object.
     */
    activePlanView : function (jq, options) {
        this._element = $(jq);
        options = $.extend({}, options);
        $.extend(this, options);

        if (this.activePlanRoutesView) { this.activePlanRoutesView = $(this.activePlanRoutesView); }
        if (this.activePlanMapView) { this.activePlanMapView = $(this.activePlanMapView); }
        if (this.activePlanBackButton) { this.activePlanBackButton = $(this.activePlanBackButton); }
        if (this.activePlanOnlyBusesButton) { this.activePlanOnlyBusesButton = $(this.activePlanOnlyBusesButton); }
        if (this.activePlanAllRoutesButton) { this.activePlanAllRoutesButton = $(this.activePlanAllRoutesButton); }

        if (options['loginUrl']) {
            this.initialize();
        }
        var ctrl = this;

        this.activePlanAllRoutesButton[0].checked = true;
        this.activePlanOnlyBusesButton.click(function() {
            if (this.checked) {
                ctrl.activePlanController.setOnlyActive(true);
            }
        });
        this.activePlanAllRoutesButton.click(function() {
            if (this.checked) {
                ctrl.activePlanController.setOnlyActive(false);
            }
        });
    },

    /**
     * This function gets called from the onBackClick closure. See Constructor.
     */
    onBackClickFunction : function () {
        this.activePlanController.back();
        if (this.activePlanController.getOnlyActive()) {
            this.activePlanOnlyBusesButton[0].checked = true;
        } else {
            this.activePlanAllRoutesButton[0].checked = true;
        }
    },

    /**
     * This function gets called from the onLogin closure. See Constructor.
     */
    onLoginFunction : function () {
        this.basket.onCreate();
        this.basket.onStart();
        this.basket.onResume();
        this.activePlanBackButton.click(this.onBackClick);
    },


    /**
     * This function initializes this object after all options have been merged.
     */
    initialize : function () {
        this.api = new BusPassAPI( {
            loginUrl : this.loginUrl
        });
        this.activePlanController = new BusPass.ActivePlanController({
            scope:  this,    // This allows us to use "this" in the ba
            busAPI: this.api
        });

        this.activePlanController.mapView($(this.activePlanMapView));
        this.activePlanController.listView(this.activePlanRoutesView);

        this.basket = new BusPass.JourneyBasket();
        this.basket.busAPI = this.api;
        this.basket.journeyStore = new BusPass.JourneyStore();

        var ctrl = this;

        // Hook the basket to the ActivePlanController with these listeners.
        this.basket.onJourneyAddedListener = {
            onJourneyAdded:function (basket, r) {
                if (debug) console.log("Route Added: " + r.getName() + " : " + r.getId());
                ctrl.activePlanController.addRoute(r);
            }
        };

        this.basket.onJourneyRemovedListener = {
            onJourneyRemoved:function (basket, r) {
                if (debug) console.log("Route Removed: " + r.getName() + " : " + r.getId());
                ctrl.activePlanController.removeRoute(r);
            }
        };

        this.basket.onBasketUpdatedListener = {
            onBasketUpdated:function (basket) {
                if (debug) console.log("Basket Updated");
            }
        };

        this.basket.onIOErrorListener = {
            onIOError:function (basket, ioe) {
                if (debug) console.log("Basket IO Error: " + ioe.message);
            }
        };

        // Add a progress listener for debugging
        if (this.debug) {
            this.basket.progressListener = {
                onSyncStart:function () {
                    console.log("Basket: SyncStart");
                },
                onSyncEnd:function (nRoutes) {
                    console.log("Basket: SyncEnd");
                },
                onRouteStart:function (iRoute) {
                    console.log("Basket: StartRoute " + iRoute);
                },
                onRouteEnd:function (iRoute) {
                    console.log("Basket: EndRoute " + iRoute);
                },
                onDone:function () {
                    console.log("Basket: Done.");
                }
            };
        }
    },

    /**
     * This function is part of the lifecycle.
     */
    onCreate : function () {},

    /**
     * This function is part of the lifecycle.
     */
    onStart : function () {},

    /**
     * This function logs into the Busme sight and retrieves the API. Upon successful login it starts
     * the basket lifecycle.
     */
    onResume: function () {
        this.api.login(this.onLogin);
    },

    /**
     * This function is part of the lifecycle.  It pauses the basket.
     */
    onPause : function() {
        this.basket.onPause();
    },

    /**
     * This function is part of the lifecycle. It stops the basket.
     */
    onStop : function () {
        this.basket.onStop();
    },

    /**
     * This function is part of the lifecycle.  It restarts the basket.
     */
    onRestart : function () {
        this.basket.onRestart();
    },

    /**
     * This variable holds the API used to logging to the Busme sight. This API is created by this
     * ActivePlanBasketController constructor and should not be modified.
     */
    api : null,

    /**
     * This variable holds the ActivePlanController. This controller is created by this
     * ActivePlanBasketController constructor and should not be modified.
     */
    activePlanController : null,

    /**
     * This variable holds the Journey Basket. This basket is created by this ActivePlanBasketController
     * and should not be modified.
     */
    basket: null
};
