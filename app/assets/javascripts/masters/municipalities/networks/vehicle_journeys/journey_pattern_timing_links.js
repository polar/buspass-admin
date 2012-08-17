/*
 *= require OpenLayers-2.12/OpenStreetMap
 *= require ClickLocationControl
 *= require ModifyFeature
 *= require routing
 *= require PathFinderController
 */

function init(center, startPoint, endPoint, defaultRoute, isConsistent) {
    var controller = new BusPass.PathFinderController({
        center : center,
        startPoint : startPoint,
        endPoint : endPoint,
        defaultRoute : defaultRoute
    });
    if (!isConsistent) {
        controller.setAutoroute(false)
    }
}
