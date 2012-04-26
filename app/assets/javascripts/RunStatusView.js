BusPass.RunStatusView = function (options) {
    $.extend(this, options);

    // We start off with polling.
    this.polling =  true;

    // We need closures so data from this object is available as the calling context.
    // We do this here so we do not cause a memory leak creating many function objects
    // with closures for each call.
    var scope = this;

    // This function gets called in setTimeout();
    this.poll = function() {
        scope.pollFunction.call(scope);
    };

    // This function gets called as the function of an AJAX call inside pollFunction.
    this.updateData = function(data) {
        scope.updateDataFunction.call(scope, data);
    };
};

BusPass.RunStatusView.prototype = {

    /**
     * This attribute holds the update URL that will be polled. It will have "?log=n" appended where n is the number
     * of lines already in the log. The update URL should return a number of new log lines after that. If
     * none or empty string is supplied, there is the http call is not made. However, the polling function
     * will still continue to run.
     */
    updateUrl : "",

    /**
     * The element that contains the log. This will become a scrollPane
     * with jScrollPane. If it is not specified in the options to statusView
     * it will be found as the first element with the class of ".log" underneath
     * the main element.
     */
    log : "#processing_log",

    /**
     * The element that contains the completed_at time. If it is not specified in the options to statusView
     * it will be found as the first element with the class of ".completed_at" underneath
     * the main element.
     */
    completed_at : "#completed_at",

    /**
     * The element that contains the started_at time. If it is not specified in the options to statusView
     * it will be found as the first element with the class of ".started_at" underneath
     * the main element.
     */
    started_at : "#started_at",

    /**
     * The element that contains the clock multiplier time. If it is not specified in the options to statusView
     * it will be found as the first element with the class of ".clock_mult" underneath
     * the main element.
     */
    clock_mult : "#clock_mult",

    /**
     * The element that contains the current simulation time. If it is not specified in the options to statusView
     * it will be found as the first element with the class of ".sim_time" underneath
     * the main element.
     */
    sim_time : "#sim_time",

    /**
     * The element that contains the processing status. If it is not specified in the options to statusView
     * it will be found as the first element with the class of ".status" underneath
     * the main element.
     */
    status : "#status",

    /**
     * This attribute contains the polling time in miliseconds.
     */
    pollTime : 5000, // miliseconds

    /**
     * This attribute is a function that gets called after the all the data has been updated when
     * a successful AJAX call to the updateUrl returns.
     * @param data  The data returned from the call to the updateUrl.
     */
    onUpdateStatus : function (data) {},

    /**
     * This attribute is a function that selects the <div> that contains the status log.
     * Its descendants should contain at most one of the following elements with the
     * class:
     * .log  This element will be come a jScrollPane and get items appended to it from the update.
     * .completed_at  This element will be updated with the data['completed_at'].
     * .started_at    This element will be updated with data['started_at']
     * .clock_mult    This element will be updated with data['clock_mult']
     * .sim_time      This element will be updated with data['sim_time']
     * .status        This element will be updated with data['status']
     *
     * The .log element is the only required element. Any one of these can be changed with
     * options.
     *
     * @param jq      The selector for the main element.
     * @param options Options that may change any attributes of this RunStatusView object.
     */
    statusView : function(jq, options) {
        this._element = jq;
        $.extend(this, options);

        if (!options['log']) { this.log = $(jq).find(".log"); }
        if (!options['completed_at']) { this.completed_at = $(jq).find(".completed_at"); }
        if (!options['started_at']) { this.started_at = $(jq).find(".started_at"); }
        if (!options['clock_mult']) { this.clock_mult = $(jq).find(".clock_mult"); }
        if (!options['sim_time']) { this.sim_time = $(jq).find(".sim_time"); }
        if (!options['status']) { this.status = $(jq).find(".status"); }

        if (this.log) { this.log = $(this.log); }
        if (this.completed_at) { this.completed_at = $(this.completed_at); }
        if (this.started_at) { this.started_at = $(this.started_at); }
        if (this.clock_mult) { this.clock_mult = $(this.clock_mult); }
        if (this.sim_time) { this.sim_time = $(this.sim_time); }
        if (this.status) { this.status = $(this.status); }

        this.log.jScrollPane({ autoReinitialise : true });
        this.logScrollPane = this.log.data('jsp').getContentPane();

        if (this.updateUrl != "") {
            setTimeout(this.poll, this.pollTime);
        }
    },

    /**
     * This function stops the continuation of polling.
     */
    stopPolling : function () {
        this.polling = false;
    },

    /**
     * This function will clear out the scrollPane where the log resides.
     */
    clearLog : function () {
        this.logScrollPane.html("");
    },

    /**
     * This function clears out the log and all other status elements, if they exist.
     */
    clearAll : function () {
        this.clearLog();
        if (this.completed_at) { this.completed_at.html(""); }
        if (this.started_at) { this.started_at.html(""); }
        if (this.clock_mult) { this.clock_mult.html(""); }
        if (this.sim_time) { this.sim_time.html(""); }
        if (this.status) { this.status.html(""); }
    },

    /**
     * This function gets called by a closure to update the status elements. It is called
     * from the function of a successful AJAX call to the updateUrl. See constructor.
     * @param data   The data returned from the updateUrl.
     */
    updateDataFunction :  function(data) {
        console.log("Update: data " + data);
        if (data != null) {
            var ctrl = this;
            $.each(data['logs'], function(i, item) {
                console.log("Adding " + item);
                ctrl.logScrollPane.append('<div class="item">'+item+'</div>');
            });
            if (data['completed_at'] && this.completed_at) {
                this.completed_at.html(data['completed_at']);
            }
            if (data['started_at'] && this.started_at) {
                this.started_at.html(data['started_at']);
            }
            if (data['clock_mult'] && this.clock_mult) {
                this.clock_mult.html(data['clock_mult'] + 0);
            }
            if (data['sim_time'] && this.sim_time) {
                this.sim_time.html(data['sim_time']);
            }
            if (data['status'] && this.status) {
                this.status.html(data['status']);
            }
        }
        this.onUpdateStatus(data);
    },

    /**
     * This function gets called by a closure to poll the updateUrl. It is effectively called by
     * setTimeout().  It makes an AJAX call to the updateUrl and upon a successful return it calls
     * the closure "updateData" (see constructor).
     */
    pollFunction: function() {
        if (this.updateUrl && this.updateUrl != "") {
            var log = $(this.logScrollPane).children(".item").length;
            $.ajax({
                type: "GET",
                url: this.updateUrl + "?log="+log,
                dataType: "json",
                success: this.updateData
            });
        }
        if (this.polling) {
            setTimeout(this.poll, this.pollTime);
        }
    }
};