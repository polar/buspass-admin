
BusPass.RouteFeatureCluster = OpenLayers.Class(OpenLayers.Strategy.Cluster, {
    // Override
    shouldCluster : function (cluster, feature) {
        // assert cluster.__route != undefined
        return cluster.__route == feature.__route;
    },
    // Override
    createCluster : function (feature) {
        var cluster = OpenLayers.Strategy.Cluster.prototype.createCluster.call(feature);
        cluster.geometry = new OpenLayers.Geometry.Collection();
        if (feature.geometry.components) {
            cluster.geometry.addComponents(feature.geometry.components);
        } else {
            cluster.geometry.addComponents(feature.geometry);
        }
        return cluster;
    },
    // Override
    addToCluster : function (cluster, feature) {
        OpenLayers.Strategy.Cluster.prototype.addToCluster.call(cluster, feature);
        cluster.__route = feature.__route;
        if (feature.geometry.components) {
            cluster.geometry.addComponents(feature.geometry.components);
        } else {
            cluster.geometry.addComponents(feature.geometry);
        }
    },
    CLASS_NAME: "BusPass.RouteFeatureCluster"
});
