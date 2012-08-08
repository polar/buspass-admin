/**
 * Class: ListViewController
 *
 * This class controls a view of list items that represent a
 * route. It has a sorting function. There is also a concept
 * of selection, highlighting, and visibility.
 */
BusPass.ListViewController = function(options) {
    this._routes = [];
    this._selectedRoutes = [];

    $.extend(this,options);
    if (this.scope == null) {
        this.scope = this;
    }
};

BusPass.ListViewController.prototype = {
    scope : null,

    onRouteSelected : function () {},

    onRouteUnselected : function () {},

    onRouteHighlighted : function () {},

    onRouteUnhighlighted : function () {},

    /**
     * Method: onRouteClicked
     * This method is called when the list item is clicked on.
     * Its default operation is to trigger the onRouteSelected callback
     * if the route was not selected.
     */
    onRouteClicked : function(ctrl, route) {
        console.log("onRouteClicked " + route.getName() + " - " + route.isSelected());
        // if its in our selected routes.
        if (this._selectedRoutes.indexOf(route) != -1) {
            ctrl.unselectRouteNoTrigger(route);
            ctrl._triggerCallback(ctrl.onRouteUnselected, route);
        } else {
            ctrl.selectRouteNoTrigger(route);
            ctrl._triggerCallback(ctrl.onRouteSelected, route);
        }
    },

    onRouteMouseOver : function(ctrl, route) {
        console.log("_onRouteMouseOver " + route.getName() + " selected " + route.isSelected());
        if (route.isHighlightable()) {
            ctrl.highlightRouteNoTrigger(route);
            ctrl._triggerCallback(ctrl.onRouteHighlighted, route);
        }
    },

    onRouteMouseOut : function(ctrl, route) {
        console.log("_onRouteMouseOut " + route.getName() + " selected " + route.isSelected());
        ctrl.unhighlightRouteNoTrigger(route);
        ctrl._triggerCallback(ctrl.onRouteUnhighlighted, route);
    },

    listView : function(element) {
        this._element = element;
        $(this._element).jScrollPane({ autoReinitialise : true, showArrows: true, horizontalGutter: 10  });
        this._scrollApi = this._element.data('jsp');
        this._contentPane =  this._scrollApi.getContentPane();
        this._contentPane.html("<table><tbody></tbody></table>");
        this._itemsPane = this._contentPane.find("tbody");
    },

    /**
     * Method: addRoute
     * This method adds a route to the ListView.
     */
    addRoute : function(route) {
        this._routes.push(route);
        $(this._itemsPane).append(this._constructRouteElement(route));
        this._sortRouteElements();
    },

    /**
     * Method: removeRoute
     * This method removes a route from the ListView
     */
    removeRoute : function(route) {
        var rs = [];
        for(var i = 0; i < this._routes.length; i++) {
            if (this._routes[i] != route) {
                rs.push(this._routes[i]);
            };
        }
        this._routes = rs;
        // This maybe should be $(route.__element.parentNode).remove(route.__element);
        route.__element.parentNode.removeChild(route.__element);
        route.__element = null;
    },

    /**
     * Method: setVisibility
     * This method sets the visibility of the route in the
     * ListView.
     */
    setVisibility : function(route, state) {
        // We store an attribute on the route for our own use.
        route.setNameVisible(state);
        if (route.isNameVisible()) {
            route.__element.className = this._removeClass(route.__element.className, "route-invisible");
        } else {
            route.__element.className = this._addClass(route.__element.className, "route-invisible");
        }
    },
    /**
     * Method: setHightability
     * This method sets whether the list item of the route in the
     * can be highlighted.
     */
    setHighlightability : function(route, state) {
        // We store an attribute on the route for our own use.
        route.setHighlightable(state);
    },

    /**
     * Method: setHasActiveJourneys
     * This method sets whether the list item of the route should
     * indicate that it has ActiveJourneys.
     */
    setHasActiveJourneys : function(route, state) {
        if (state) {
            if (route.hasActiveJourneys()) {
                route.__element.className = this._addClass(route.__element.className, "route-hasactivejourneys");
            } else {
                route.__element.className = this._removeClass(route.__element.className, "route-hasactivejourneys");
            }
        }
    },

    /**
     * Method: clearRoutes
     * This method removes all routes from the ListView
     */
    clearRoutesList : function() {
        this._routes = [];
        this._redisplayRoutes();
    },

    /**
     * Method: selectRouteNoTrigger
     * This method only selects the route in this View.
     * It doesn't trigger a callback.
     */
    selectRouteNoTrigger : function(route) {
        console.log("list.selectRoutesNoTrigger: selecting " + route.getName() + ":" + route.getId());
        this.unselectAllRoutesNoTrigger();
        this._selectedRoutes.push(route);
        route.__element.className = this._addClass(route.__element.className, "route-selected");
    },

    _remove : function (a,x) {
        var b = [];
        for(var i = 0; i < a.length; i++) {
            if (a[i] != x) {
                b.push(a[i]);
            }
        }
        return b;
    },

    _addClass : function(className, clazz) {
        var classes = className.split(' ');
        var add = true;
        if (classes.indexOf(clazz) == -1) {
            classes.push(clazz);
        }
        return classes.join(' ');
    },

    _removeClass : function(className, clazz) {
        var classes = this._remove(className.split(' '), clazz);
        var name = classes.join(' ');
        return name;
    },

    redraw : function () {
        for (var i=0; i < this._routes.length; i++) {
          var route = this._routes[i];
          if (route.hasActiveJourneys()) {
            route.__element.className = this._addClass(route.__element.className, "route-hasactivejourneys");
          } else {
            route.__element.className = this._removeClass(route.__element.className, "route-hasactivejourneys");
          }
          if (route.isNameVisible()) {
            route.__element.className = this._removeClass(route.__element.className, "route-invisible");
          } else {
            route.__element.className = this._addClass(route.__element.className, "route-invisible");
          }
        }
    },

    /**
     * Method: unselectRouteNoTrigger
     * This method only unselects the route in this View.
     * It doesn't trigger a callback.
     */
    unselectRouteNoTrigger : function(route) {
        console.log("list.unselectRoutesNoTrigger: unselecting " + route.getName() + ":" + route.getId());
        this._selectedRoutes = this._remove(this._selectedRoutes,route);
        route.__element.className = this._removeClass(route.__element.className, "route-selected");
    },

    /**
     * Method: unselectAllRoutesNoTrigger
     * This method only unselects the routes in this View.
     * It doesn't trigger callbacks.
     */
    unselectAllRoutesNoTrigger : function() {
        console.log("list.unselectAllRoutes: unselecting ");
        var sroutes = this._selectedRoutes;
        for(var i = 0; i < sroutes.length; i++) {
            console.log("list.unselectAllRoutes.route: unselecting " + sroutes[i].getName() + ":" + sroutes[i].getId());
            sroutes[i].__element.className = this._removeClass(sroutes[i].__element.className, "route-selected");
        }
        this._selectedRoutes = [];
    },

    /**
     * Method: highlightRouteNoTrigger
     * This method only highlights the routes in this View.
     * It doesn't trigger callbacks.
     */
    highlightRouteNoTrigger : function(route) {
        console.log("list.highlightRouteNoTrigger " + route.getName() + " - " + route.isSelected());
        route.__element.className = this._addClass(route.__element.className, "route-highlighted");
    },

    /**
     * Method: unhighlightRouteNoTrigger
     * This method only unhighlights the routes in this View.
     * It doesn't trigger callbacks.
     */
    unhighlightRouteNoTrigger : function(route) {
        console.log("list.unhighlightRouteNoTrigger " + route.getName() + " - " + route.isSelected());
        route.__element.className = this._removeClass(route.__element.className, "route-highlighted");
    },

    /**
     * Method: unhighlightAllRoutesNoTrigger
     * This method only unselects the routes in this View.
     * It doesn't trigger callbacks.
     */
    unhighlightAllRoutesNoTrigger : function() {
        for(var i = 0; i < this._routes.length; i++) {
            this.unhighlightRouteNoTrigger(this._routes[i]);
        }
    },

    /**
     * Method: private _redisplayRoutes
     * This method reconstructs the elements under the RouteDisplay Element.
     */
    _redisplayRoutes : function() {
        var ctrl = this;
        $(ctrl._itemsPane).html("");
        $.each(ctrl._routes, function(i,x) {
            $(ctrl._itemsPane).append(ctrl._constructRouteElement(x)); });
    },

    /**
     * Method: private _compare
     * This method compares two elements.
     *
     * Returns:
     * {Integer} - -1, 0, 1
     */
    _compare : function (s1,s2) {
        return s1<s2?-1:s1==s2?0:1;
    },

    /**
     * Method: private _compareCodes
     * This method compares Route codes.
     * TODO: Parameterize this for municipalities
     * Codes are compared on their route base, which is their
     * last 2 digits. The 43 has routes 143, 243, 443, 543.
     */
    _compareCodes : function (code1,code2) {
        var c1 = "   " + code1;
        var c2 = "   " + code2;
        var base1 = c1.substring(c1.length-2);
        var base2 = c2.substring(c2.length-2);
        var cmp = this._compare(base1,base2);
        if (cmp == 0) {
            // ' ' < '0'
            var s1 = c1.substring(c1.length-3,c1.length-2);
            var s2 = c2.substring(c2.length-3,c2.length-2);
            return this._compare(s1,s2);
        }
        return cmp;
    },

    /**
     * Method: private _compareRoutes
     * This method compares Routes. We always put the Route
     * atop of its Journeys. The rest are sorted by codes.
     */
    _compareRoutes : function (r1,r2) {
        if (r1.isJourney() && r2.isJourney() ||
            !r1.isJourney() && !r2.isJourney()) {
            cmp = this._compareCodes(r1.getCode(),r2.getCode());
            if (cmp == 0) {
                return this._compare(r1.getDisplayName(),r2.getDisplayName());
            } else {
                return cmp;
            }
        } else {
            if (r1.isRouteDefinition()) {
                return -1;
            } else {
                return 1;
            }
        }
    },
    /**
     * Method: private _compareRouteElements
     * This method is used to sort through the DOM elements for Routes.
     */
    _compareRouteElements : function(rd1,rd2) {
        return this._compareRoutes(rd1.__route, rd2.__route);
    },


    /**
     * Method: private _constructRouteElement
     * This method constructs the element for display.
     */
    _constructRouteElement : function(route) {
        var ctrl = this;
        var visibility = route.isNameVisible() ? "" : " route-invisible";
        var type = " rtype-" + route.getType();
        var div =
            "<tr class='item" + visibility + type + "' data-role='" + route.getType() + "' data-routeid='"+ route.getId() + "'>" +

                "<td class='route-code' data-role='route-code'>" + "<div class='route-icon'/>" +
                route.getCode() +
                "</td>"+
                "<td class='route-name' data-role='route-name'>" +
                    route.getDisplayName() +
                "</td>" +
                "<td class='route-times'>" +
                    "<div class='route-time'>" +
                      (route.isJourney() ?
                        route.getStartTime() : "") +
                    "</div>" +
                    "<div class='route-time'>" +
                      (route.isJourney() ?
                        route.getEndTime() : "") +
                    "</div>" +
                "</td>" +
            "</tr>";
        // Returns array [<div>]
        div = $(div);
        // Element sorting key is the route..
        div[0].__route = route;
        route.__element = div[0];
        route.__routesView = this;
        // I don't know why this doesn't work on directly on div[0].
        div.click(function() {
            console.log("clicked on " + route.getName() + " - " + this.getAttribute("data-routeid"));
            ctrl.onRouteClicked(ctrl,route);
        });
        div.mouseover(function() {
            console.log("moveover on " + route.getName() + " - " + this.getAttribute("data-routeid"));
            ctrl.onRouteMouseOver(ctrl,route);
        });
        div.mouseout(function() {
            console.log("mouseout on " + route.getName() + " - " + this.getAttribute("data-routeid"));
            ctrl.onRouteMouseOut(ctrl,route);
        });
        return div;
    },

    _sortRouteElements : function() {
        var ctrl = this;
        var children = $(ctrl._itemsPane).children(".item");
        // TODO: We can just insert at the right place.
        children.detach().sort(
            function(a,b) {
                return ctrl._compareRouteElements(a,b);
            });
        $(ctrl._itemsPane).append(children);
    },

    _triggerCallback : function(cb, route) {
        cb.apply(this.scope, [route]);
    },
};
