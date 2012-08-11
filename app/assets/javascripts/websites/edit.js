/*
 *= require OpenLayers-2.11/OpenStreetMap
 *= require MapLocationController
 */
/*
 * The init function takes an array [longitude, latitude]. If it is nil,
 * we center the map on the location if available, or at a default point.
 */
function init(coordinates) {

    // This function updates the input fields when icon is clicked or moved.
    function updateLocationCallback(lonlat) {
        $("#master_longitude").val(lonlat[0]);
        $("#master_latitude").val(lonlat[1]);
    }

    this.locationTool = new BusPass.MapLocationController({
        coordinates : coordinates,
        onLocationUpdated : updateLocationCallback
    });
}