/*
 *= require OpenLayers-2.11/OpenStreetMap
 *= require MapLocationController
 *= require slugify
 */
/*
 * The init function takes an array [longitude, latitude]. If it is nil,
 * we center the map on the location if available, or at a default point.
 */
function init(coordinates) {

    new BusPass.Slugify( {
        source : "#master_name",
        dest : "#master_slug"
    });

    // This function updates the input fields when icon is clicked or moved.
    function updateLocationCallback(lonlat) {
        $("#master_longitude").val(lonlat[0]);
        $("#master_latitude").val(lonlat[1]);

        // Changes TimeZones.
        $.get("/transport.php?url=http://api.geonames.org/timezoneJSON?lng="+lonlat[0]+"&lat="+lonlat[1]+"&username=demo",
            {},
            function (data) {
                var resp = JSON.parse(data) ;
                console.log("answer from GOENAMES " + resp.timezoneId);
                if (resp.timezoneId) {
                    $("#master_timezone").val(resp.timezoneId);
                }
            });

    }

    this.locationTool = new BusPass.MapLocationController({
        coordinates : coordinates,
        onLocationUpdated : updateLocationCallback
    });
}