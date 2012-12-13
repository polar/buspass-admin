// Changes TimeZones.
$.get("/transport.php?url=http://api.geonames.org/timezoneJSON?lng=" + lonlat[0] + "&lat=" + lonlat[1] + "&username=demo",
    {},
    function (data) {
        var resp = JSON.parse(data);
        console.log("answer from GOENAMES " + resp.timezoneId);
        if (resp.timezoneId) {
            $("#master_timezone").val(resp.timezoneId);
        }
    });
