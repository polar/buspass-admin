
//= require jquery.json-2.3
//= require jqClock
//= require date
//= require OpenLayers-2.11/OpenLayers
//= require BusPass
//= require ActivePlanBasketController
//= require_self

// Compiling the assets into a single file makes OpenLayers._getScriptLocation to be wrong
// and therefore cannot find the images. We configure the OpenLayers image prefix here.
OpenLayers.ImgPath = "/assets/OpenLayers-2.11/img/"