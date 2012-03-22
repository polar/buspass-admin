RoutesView = function(element) {
  this._element = element;
  this._routes = [];
  this._routes.sort();
};

RoutesView.prototype = {

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
   * TODO: Parameterize this for muncipalities
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
      if (r1.isJourney()) {
         return -1;
      } else {
         return 1;
      }
    }
  },

  /**
   * Method: private _constructRouteElement
   * This method constructs the element for display.
   */
  _constructRouteElement : function(route) {
    var self = this;
    var div = "<div class='item row' data-role='route' data-routeid='"+ route.getId() + "'>" +
                "<div class='span1 route-code' data-role='route-code'>" +
                  route.getCode() +
                "</div>"+
                "<div class='span5' data-role='route-name'>" +
                  route.getDisplayName() +
                "</div>" +
              "</div>";
    // Returns array [<div>]
    div = $(div);
    // Element sorting key is the route..
    div[0].__route = route;
    route.__element = div[0];
    route.__routesView = this;
    // I don't know why this doesn't work on directly on div[0].
    div.click(function() {
        console.log("clicked on " + route.getName() + " - " + this.getAttribute("data-routeid"));
        self.selectRoute(route);
    });
    return div;
  },

  /**
   * Method: _selectRoute
   * This method only selects the route in this View.
   * It doesn't touch the map. This function is usually
   * called by the Map after it hasnselected the route.
   */
  _selectRoute : function(route) {
      route.setSelected(true);
      route.__element.className = "item row route-selected";
  },

  /**
   * Method: _unselectRoute
   * This method only unselects the route in this View.
   * It doesn't touch the map. This function is usually
   * called by the Map after it has unselected the route.
   */
  _unselectRoute : function(route) {
      route.setSelected(false);
      route.__element.className = "item row";
  },

  /**
   * Method: _unselectAllRoutes
   * This method only unselects the routes in this View.
   * It doesn't touch the map. This function is usually
   * called by the Map after it has unselected a route.
   */
  _unselectAllRoutes : function() {
      for(i in this._routes) {
          this._unselectRoute(this._routes[i]);
      }
  },

  /**
   * Method: selectRoute
   * This method is called by things that want to select the
   * route in this View. It will select the route in the map
   * as well.
   */
  selectRoute : function(route) {
      this._unselectAllRoutes();
      // The map will trigger this._selectRoute();
      map._selectRoute(route);
  },

  /**
   * Method: unselectRoute
   * This method is called by things that want to unselect the
   * route. It will unselect the route in the Map as well.
   */
  unselectRoute : function(route) {
      this.unselectAllRoutes();
      // The map will trigger this._unselectRoute();
      map._unselectRoute(route);
  },

  /**
   * Method: unselectAllRoutes
   * This method is called by things that want to clear the
   * selected Route(s). It will unselect the route in the Map as
   * well.
   */
  unselectAllRoutes : function() {
      for(i in this._routes) {
          this.unselectRoute(this._routes[i]);
      }
  },

  _highlightRoute : function(route) {
      if (route.isSelected() {
          route.__element.className = "item row route-selected route-highlighted";
      } else {
          route.__element.className = "item row route-highlighted";
      }
  },

  _unhighlightRoute : function(route) {
      if (route.isSelected() {
          route.__element.className = "item row route-selected";
      } else {
          route.__element.className = "item row";
      }
  },

  highlightRoute : function(route) {
      this.unhighlightAllRoutes();
      this._highlightRoute(route);
  },

  unhighlightRoute : function(route) {
      this.unhighlightAllRoutes();
  },

  unhighlightAllRoutes : function() {
      for(i in this._routes) {
          this._unhighlightRoute(this._routes[i]);
      }
  },

  _compareRouteElement : function(rd1,rd2) {
      return this._compareRoutes(rd1.__route, rd2.__route);
  },

  _sortRouteElements : function() {
      var self = this;
      var children = $(self._element).children("div");
      // TODO: We can just insert at the right place.
      children.detach().sort(
          function(a,b) {
              return self._compareRouteElement(a,b);
          });
      $(self._element).append(children);
  },

    /**
     * Method: private _sortRoutes
     * This method sorts routes according to the _compareRoutes compariator.
     */
    _sortRoutes : function() {
    var rd = this;
    this._routes = this._routes.sort(
        function(a,b) {
            return rd._compareRoutes(a,b);
        });
    },

  /**
   * Method: private _redisplayRoutes
   * This method reconstructs the elememnts under the RouteDisplay Element.
   */
  _redisplayRoutes : function() {
    var rd = this;
    $(rd._element).html("");
    $.each(rd._routes, function(i,x) {
             $(rd._element).append(rd._constructRouteElement(x)); });
  },

  clearRouteList : function() {
    this._routes = [];
    this._redisplayRoutes();
  },

  addRoute : function(route, clickListener, dclickListener) {
    this._routes.push(route);
    $(this._element).append(this._constructRouteElement(route));
    this._sortRouteElements();
    //this._redisplayRoutes();
  },

  removeRoute : function(route) {
    var rs = [];
    for(r in this._routes) {
      if (this._routes[r] != route) {
        rs += this._routes[r];
      };
    }
    this._routes = rs;
    this._redisplayRoutes();
  }
};