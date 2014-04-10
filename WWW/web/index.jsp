<%-- 
    Document   : index
    Created on : Feb 6, 2014, 11:33:57 AM
    Author     : DJ
--%>

<%@page contentType="text/html" pageEncoding="UTF-8"%>
<!DOCTYPE html>
<html>
    <head>
        <meta http-equiv="Content-Type" content="text/html; charset=UTF-8">
        <title>Google map page</title>
        <script src="http://ajax.googleapis.com/ajax/libs/jquery/1.10.2/jquery.min.js"></script>
        <script src="https://maps.googleapis.com/maps/api/js?key=AIzaSyC0xjNl30COEmqU7TkUc3W78dR7oGWBecQ&sensor=true&libraries=visualization"></script>
        <style type="text/css">
            #map-canvas { height: 500px; }
            .icon { width: 16px; height: 16px; }
        </style>
        <script type="text/javascript">
            var initialLocation;
            var ouluLocation = new google.maps.LatLng(65.1, 25.28);
            var serverURL = 'http://dev2.cyberlightning.com:44448';
            var map;
            var position = new Array();
            var sensorMarkers = new Array();
            var busMarkers = new Array(); 
            var busRoutes = new Array();
            var currentStop = new Array();
            var busRoad;
            var wlanMarkers = new Array();
            var wlanPoints = new Array();
            var parkingMarkers = new Array();
            var trafficMarkers = new Array();
            var camMarkers = new Array();
            var weatherMarkers = new Array();
            var lightMarkers = new Array();
            var windMarkers = new Array();
            var directionService;
            var busRoute;
            var routeLoop;
            var heatmapActive = false;
            var infoWindow = new google.maps.InfoWindow({
                content: ""
            });
            
            function initialize(){

                var mapOptions = {
                    zoom: 12
                };
                map = new google.maps.Map(document.getElementById("map-canvas"), mapOptions);
                google.maps.event.addListener(map, 'zoom_changed', function () {
                    if (heatmapActive){
                        setRadius();
                    }
                });
            
                map.setCenter(ouluLocation);
                
                
                if(navigator.geolocation){
                    browserSupportFlag = true;
                    navigator.geolocation.getCurrentPosition(function(currentPosition){
                        position[0] = currentPosition.coords.latitude;
                        position[1] = currentPosition.coords.longitude;
                        
                        initialLocation = new google.maps.LatLng(position[0], position[1]);
                        map.setCenter(initialLocation);

                        var currentMarker = new google.maps.Marker({
                            position: initialLocation,
                            title: 'Your Location',
                            map: map
                        });
                        
                        var searchRadius = new google.maps.Circle({
                            strokeColor: '#FF0000',
                            strokeOpacity: 0.8,
                            strokeWeight: 2,
                            fillOpacity: 0,
                            map: map,
                            center: initialLocation,
                            radius: 100000
                        });
                    }, function() {
                        handleNoGeolocation(browserSupportFlag);
                    });
                } else {
                    browserSupportFlag = false;
                    handleNoGeolocation(browserSupportFlag);
                }

                function handleNoGeolocation(errorFlag){
                    if (errorFlag == true){
                        alert("Geolocation service failed.");
                        initialLocation = ouluLocation;
                    } else {
                        alert("Your browser doesn't support geolocation. We've placed you near Oulu.");
                        initialLocation = ouluLocation;
                    }
                    map.setCenter(initialLocation);
                }
            }
            
            google.maps.event.addDomListener(window, 'load', initialize);
            
            function addOnBusClick(sensorMarker, sensorKey){
                google.maps.event.addListener(sensorMarker, 'click', function() {
                    plotRoute(sensorKey);
                });
            }
            
            function addOnCamClick(sensorMarker, sensorKey){
                google.maps.event.addListener(sensorMarker, 'click', function() {
                    openImage(sensorMarker, sensorKey);
                });
            }
            
            function addOnInfoClick(sensorMarker, sensorKey){
                google.maps.event.addListener(sensorMarker, 'click', function() {
                    showInfo(sensorMarker, sensorKey);
                });
            }
            
            function plotRoute(sensorKey){
                directionService = new google.maps.DirectionsService();
                busRoad = new google.maps.MVCArray();
               
                busRoute = new google.maps.Polyline({
                    map: map,
                    strokeColor: '#FF0000',
                    strokeOpacity: 1.0,
                    strokeWeight: 2
                });
                
                for (var q = 0; q < 2; q++){
                    alert((currentStop[sensorKey]));
                    directionService.route({
                        origin: busRoutes[sensorKey][(currentStop[sensorKey] - q)],
                        destination: busRoutes[sensorKey][(currentStop[sensorKey] - q - 1)],
                        travelMode: google.maps.DirectionsTravelMode.TRANSIT
                    }, function(result, status){
                        $('#text').append(status + "<br />");
                       if (status == google.maps.DirectionsStatus.OK) {
                            for (var j = 0; j < result.routes[0].overview_path.length; j++) {
                                $('#text').append(result.routes[0].overview_path[j] + "<br />");
                                busRoad.push(result.routes[0].overview_path[j]);
                                busRoute.setPath(busRoad);
                            }
                            $('#text').append("<br />");
                       }
                    });
                }   
            }
            
            function openImage(sensorMarker, sensorKey){
                $.ajax({
                    type: "GET",
                    url: serverURL,
                    dataType: 'json',
                    data: {
                        action: "getDeviceById",
                        device_id: sensorKey
                    },
                    success: function(response) {
                        var sensorImage = response[sensorKey].sensors[0].value.values;
                        infoWindow = new google.maps.InfoWindow({ content: "<img src='" + sensorImage + "'/>" });
                        infoWindow.open(map, sensorMarker);
                    }
                });
            }

            function closeImage() { infoWindow.close(); }
            
            function showInfo(sensorMarker, sensorKey){
                infoWindow.close();
                
                $.ajax({
                    type: "GET",
                    url: serverURL,
                    dataType: 'json',
                    data: {
                        action: "getDeviceById",
                        device_id: sensorKey
                    },
                    success: function(response) {
                        var contentString = "";
                        for (var i = 0; i < response[sensorKey].sensors.length; i++){
                            contentString += response[sensorKey].sensors[i].attributes.type + ": " + response[sensorKey].sensors[i].value.values + " " + response[sensorKey].sensors[i].value.unit + "<br />";
                        }
                        if (response[sensorKey].actuators != undefined){
                            contentString += "<form action='" + serverURL + "' method='POST' target='_blank'><input type='hidden' name='action' value='update'/>";
                            contentString += "sensor: ";
                            contentString += "<input type='hidden' name='device_id' value='" + sensorKey + "'/>";
                            contentString += "<select name='sensor_id'>";
                            for (var i = 0; i < response[sensorKey].sensors.length; i++){
                                contentString += "<option value='" + i + "'>" + i + "</option>";
                            }
                            contentString += "</select><br />";
                            contentString += "parameter: ";
                            contentString += "<select name='parameter'>";      
                            
                                for(var x = 0; x < response[sensorKey].actuators[0].actions.length; x++){ 
                                    contentString += "<option value='" + response[sensorKey].actuators[0].actions[x].parameter + "'>" + response[sensorKey].actuators[0].actions[x].parameter + "</option>";
                                    contentString += "</select><br />";
                                    contentString += response[sensorKey].actuators[0].actions[x].parameter + ": ";
                                    contentString += "<select name='value'>";
                                    for(var z = 0; z < response[sensorKey].actuators[0].actions[x].values.length; z++){
                                        contentString += "<option value='" + response[sensorKey].actuators[0].actions[x].values[z] + "'>" + response[sensorKey].actuators[0].actions[x].values[z] + "</option>";
                                    }
                                }
                                contentString += "</select><br/>"
                                contentString += "<input type='submit'/></form>";
                        }

                        infoWindow = new google.maps.InfoWindow({
                            content: "<div style='width: 225px; height: 150px;'>" + contentString + "</div>"
                        });
                        infoWindow.open(map,sensorMarker);
                    }
                });    
            }
            
            function toggleBus(){
                for (var i = 0; i < busMarkers.length; i++){
                    var busMarker = busMarkers[i];
                    if(busMarker.getMap() === null){
                        busMarker.setMap(map);
                    }else{
                        busMarker.setMap(null);
                    }
                }
            }
            
            function toggleWLAN(){
                for (var i = 0; i < wlanMarkers.length; i++){
                    var wlanMarker = wlanMarkers[i];
                    if(wlanMarker.getMap() === null){
                        wlanMarker.setMap(map);
                    }else{
                        wlanMarker.setMap(null);
                    }
                }
            }
            
            function toggleWeather(){
                for (var i = 0; i < weatherMarkers.length; i++){
                    var weatherMarker = weatherMarkers[i];
                    if(weatherMarker.getMap() === null){
                        weatherMarker.setMap(map);
                    }else{
                        weatherMarker.setMap(null);
                    }
                }
            }
            
            function toggleParking(){
                for (var i = 0; i < parkingMarkers.length; i++){
                    var parkingMarker = parkingMarkers[i];
                    if(parkingMarker.getMap() === null){
                        parkingMarker.setMap(map);
                    }else{
                        parkingMarker.setMap(null);
                    }
                }
            }
            
            function toggleCam(){
                for (var i = 0; i < camMarkers.length; i++){
                    var camMarker = camMarkers[i];
                    if(camMarker.getMap() === null){
                        camMarker.setMap(map);
                    }else{
                        camMarker.setMap(null);
                    }
                }
            }
            
            function toggleTraffic(){
                for (var i = 0; i < trafficMarkers.length; i++){
                    var trafficMarker = trafficMarkers[i];
                    if(trafficMarker.getMap() === null){
                        trafficMarker.setMap(map);
                    }else{
                        trafficMarker.setMap(null);
                    }
                }
            }
            
            function promptMaxResults(sensorType){
                if ($('#' + sensorType).is(':checked')){
                    var maxResults = prompt("Number of results");

                    if(maxResults == null){
                        $('#' + sensorType).attr('checked',false);
                    }else{
                        $.ajax({
                        type: "GET",
                        url: serverURL,
                        dataType: 'json',
                        data: {
                            action: "getDevicesByRadiusAndByDeviceType",
                            lat: position[0],
                            lon: position[1],
                            radius: 100000,
                            maxResults: maxResults,
                            type: sensorType
                        },
                        success: function(response) {
                            var keys = Object.keys(response);

                            for (var i = 0; i < keys.length; i ++){
                                var sensorKey = keys[i];

                                var sensorName = response[sensorKey].attributes.name;
                                
                                var sensorLat = response[sensorKey].attributes.gps[0];
                                var sensorLng = response[sensorKey].attributes.gps[1];
                                
                                var sensorPosition = new google.maps.LatLng(sensorLat, sensorLng);

                                sensorMarkers[i] = new google.maps.Marker({
                                    position: sensorPosition,
                                    title: sensorName,
                                    map: map
                                });

                                switch (sensorType) {
                                    case ('bus'):
                                        sensorMarkers[i].setIcon("bus.png");
                                        busMarkers.push(sensorMarkers[i]);
                                        addOnBusClick(sensorMarkers[i], sensorKey);

                                        var sensorRouteCoords = new Array();
                                        var sensorRouteLength = response[sensorKey].sensors[0].attributes.value_range[0].length;
                                        
                                        for (var j = 0; j < (sensorRouteLength/2); j++){
                                            var sensorRouteLat = response[sensorKey].sensors[0].attributes.value_range[0][(j * 2)];
                                            var sensorRouteLng = response[sensorKey].sensors[0].attributes.value_range[0][(j * 2) + 1];
                                            
                                            alert(sensorRouteLat);
                                            
                                            if (sensorRouteLat == sensorLat){
                                                currentStop[sensorKey] = j;
                                            }
                                            sensorRouteCoords.push(new google.maps.LatLng(sensorRouteLat, sensorRouteLng));
                                        }

                                        busRoutes[sensorKey] = sensorRouteCoords;

                                        break;
                                    case ('wlanstation'):
                                        sensorMarkers[i].setIcon("wlan.png");
                                        wlanMarkers.push(sensorMarkers[i]);

                                        wlanPoints.push(sensorPosition);
                                        break;
                                    case ('weatherstation'):
                                        sensorMarkers[i].setIcon("weather.png");
                                        weatherMarkers.push(sensorMarkers[i]);
                                        addOnInfoClick(sensorMarkers[i], sensorKey);
                                        
                                        break;
                                    case ('parkinghall'):
                                        sensorMarkers[i].setIcon("parking.png");
                                        parkingMarkers.push(sensorMarkers[i]);
                                        addOnInfoClick(sensorMarkers[i], sensorKey);
                                        
                                        break;
                                    case ('trafficcamera'):
                                        sensorMarkers[i].setIcon("cam.png");
                                        camMarkers.push(sensorMarkers[i]);
                                        addOnCamClick(sensorMarkers[i], sensorKey);
                                        
                                        break;
                                    case ('trafficstation'):
                                        sensorMarkers[i].setIcon("traffic.png");
                                        trafficMarkers.push(sensorMarkers[i]);
                                        addOnInfoClick(sensorMarkers[i], sensorKey);
                                        
                                        break;
                                    case ('lightsource'):
                                        sensorMarkers[i].setIcon("lightsource.png");
                                        lightMarkers.push(sensorMarkers[i]);
                                        addOnInfoClick(sensorMarkers[i], sensorKey);
                                        
                                        break;
                                    case ('windmill'):
                                        sensorMarkers[i].setIcon("windmill.png");
                                        windMarkers.push(sensorMarkers[i]);
                                        addOnInfoClick(sensorMarkers[i], sensorKey);
                                        
                                        break;
                                }
                            }
                        }
                    });
                    }
                }else{
                    switch (sensorType) {
                        case ('bus'):
                            for (var i = 0; i < busMarkers.length; i++){
                                var busMarker = busMarkers[i];
                                busMarker.setMap(null);
                            }
                            
                            busMarkers = new Array();
                            
                            break;
                        case ('wlanstation'):
                            for (var i = 0; i < wlanMarkers.length; i++){
                                var wlanMarker = wlanMarkers[i];
                                wlanMarker.setMap(null);
                            }
                            
                            wlanMarkers = new Array();
                            
                            break;
                        case ('weatherstation'):
                            for (var i = 0; i < weatherMarkers.length; i++){
                                var weatherMarker = weatherMarkers[i];
                                weatherMarker.setMap(null);
                            }
                            
                            weatherMarkers = new Array();
                            
                            break;
                        case ('parkinghall'):
                            for (var i = 0; i < parkingMarkers.length; i++){
                                var parkingMarker = parkingMarkers[i];
                                parkingMarker.setMap(null);
                            }
                            
                            parkingMarkers = new Array();
                            
                            break;
                        case ('trafficcamera'):
                            for (var i = 0; i < camMarkers.length; i++){
                                var camMarker = camMarkers[i];
                                camMarker.setMap(null);
                            }
                            
                            camMarkers = new Array();
                            
                            break;
                        case ('trafficstation'):
                            for (var i = 0; i < trafficMarkers.length; i++){
                                var trafficMarker = trafficMarkers[i];
                                trafficMarker.setMap(null);
                            }
                            
                            trafficMarkers = new Array();
                            
                            break;
                        case ('lightsource'):
                            for (var i = 0; i < lightMarkers.length; i++){
                                var lightMarker = lightMarkers[i];
                                lightMarker.setMap(null);
                            }
                            
                            lightMarkers = new Array();
                            
                            break;
                        case ('windmill'):
                            for (var i = 0; i < windMarkers.length; i++){
                                var windMarker = windMarkers[i];
                                windMarker.setMap(null);
                            }
                            
                            windMarkers = new Array();
                            
                            break;
                    }
                }
            }
            
            function toggleWlanHeatmap() {
                if (heatmapActive){
                    for (var i = 0; i < wlanMarkers.length; i++){
                        var wlanMarker = wlanMarkers[i];
                        wlanMarker.setMap(map);
                    }
                    
                    wlanHeatmap.setMap(null);
                    
                    heatmapActive = false;
                }else{
                    var wlanRouters = new google.maps.MVCArray(wlanPoints);

                    for (var i = 0; i < wlanMarkers.length; i++){
                        var wlanMarker = wlanMarkers[i];
                        wlanMarker.setMap(null);
                    }

                    wlanHeatmap = new google.maps.visualization.HeatmapLayer({
                        data: wlanRouters,
                        map: map,
                        radius: 50
                    });
                    
                    var gradient = [
                        'rgba(255,0,0,0)',
                        'rgba(255,0,0,1)',
                        'rgba(200,0,0,1)'
                    ];
                                        
                    wlanHeatmap.set('gradient', gradient);

                    setRadius();
                    heatmapActive = true;
                }
            }
            
            var TILE_SIZE = 256;

            function bound(value, opt_min, opt_max) {
              if (opt_min != null) value = Math.max(value, opt_min);
              if (opt_max != null) value = Math.min(value, opt_max);
              return value;
            }

            function degreesToRadians(deg) {
              return deg * (Math.PI / 180);
            }

            function radiansToDegrees(rad) {
              return rad / (Math.PI / 180);
            }

            /** @constructor */
            function MercatorProjection() {
              this.pixelOrigin_ = new google.maps.Point(TILE_SIZE / 2,
                  TILE_SIZE / 2);
              this.pixelsPerLonDegree_ = TILE_SIZE / 360;
              this.pixelsPerLonRadian_ = TILE_SIZE / (2 * Math.PI);
            }

            MercatorProjection.prototype.fromLatLngToPoint = function(latLng, opt_point) {
                var me = this;
                var point = opt_point || new google.maps.Point(0, 0);
                var origin = me.pixelOrigin_;

                point.x = origin.x + latLng.lng() * me.pixelsPerLonDegree_;

                // Truncating to 0.9999 effectively limits latitude to 89.189. This is
                // about a third of a tile past the edge of the world tile.
                var siny = bound(Math.sin(degreesToRadians(latLng.lat())), -0.9999,
                    0.9999);
                point.y = origin.y + 0.5 * Math.log((1 + siny) / (1 - siny)) *
                    -me.pixelsPerLonRadian_;
                return point;
            };

            MercatorProjection.prototype.fromPointToLatLng = function(point) {
                var me = this;
                var origin = me.pixelOrigin_;
                var lng = (point.x - origin.x) / me.pixelsPerLonDegree_;
                var latRadians = (point.y - origin.y) / -me.pixelsPerLonRadian_;
                var lat = radiansToDegrees(2 * Math.atan(Math.exp(latRadians)) -
                    Math.PI / 2);
                return new google.maps.LatLng(lat, lng);
            };
            
            function setRadius() {
                var numTiles = 1 << map.getZoom();
                var projection = new MercatorProjection();
                var worldCoordinate = projection.fromLatLngToPoint(ouluLocation);
                var pixelCoordinate = new google.maps.Point(
                    worldCoordinate.x * numTiles,
                    worldCoordinate.y * numTiles);

                var ouluLocationNorth = google.maps.geometry.spherical.computeOffset(ouluLocation, 100, 0);
                var worldCoordinateNew = projection.fromLatLngToPoint(ouluLocationNorth);
                var pixelCoordinateNew = new google.maps.Point(
                    worldCoordinateNew.x * numTiles,
                    worldCoordinateNew.y * numTiles);

                wlanHeatmap.set("radius", Math.floor(pixelCoordinate.y - pixelCoordinateNew.y));
            }
          
            function sendCommand(deviceID, sensorID, parameterValue, newValue){
                $.ajax({
                    type: "POST",
                    url: serverURL,
                    data: {
                        action: "update",
                        device_id: deviceID,
                        sensor_id: sensorID,
                        parameter: parameterValue,
                        value: newValue
                    },
                    success: function(response) {
                        showInfo(markerID, deviceID);
                    }
                });
            }
            
            function loadLegend(){
                var legendString = "";
                
                $.ajax({
                    type: "GET",
                    url: serverURL,
                    dataType: 'json',
                    data: {
                        action: "getAllDeviceTypes"
                    },
                    success: function(response) {                      
                        for (var n = 0; n < response.length; n++){
                            legendString += '<input style="margin-right: 5px;" type="checkbox" id="' + response[n] + '" name="filter" onchange="promptMaxResults(\'' + response[n] + '\');" autocomplete="off"/><label for="' + response[n] + '"><img class="icon" src="' + response[n] + '.png"/>  Oulu Bus</label><br />';
                        }              
                    }});
                
                $("#legend").html(legendString);
            }
        </script>
    </head>
    <body>
        <h1>Hello World!</h1>
        <div id="map-canvas"></div>
        <div id="legend" style="position: absolute; right: 10%; top: 20%; background-color: white; border: solid 1px black; padding: 5px;">
            <input style="margin-right: 5px;" type="checkbox" id="bus" name="filter" onchange="promptMaxResults('bus');" autocomplete="off"/><label for="bus"><img class="icon" src="bus.png"/>  Oulu Bus</label><br />
            <input style="margin-right: 5px;" type="checkbox" id="wlanstation" name="filter" onchange="promptMaxResults('wlanstation');" autocomplete="off"/><label for="wlanstation"><img class="icon" src="wlan.png"/>  WLAN Station</label><br />
            <input style="margin-right: 5px;" type="checkbox" id="weatherstation" name="filter" onchange="promptMaxResults('weatherstation');" autocomplete="off"/><label for="weatherstation"><img class="icon" src="weather.png"/>  Weather Station</label><br />
            <input style="margin-right: 5px;" type="checkbox" id="parkinghall" name="filter" onchange="promptMaxResults('parkinghall');" autocomplete="off"/><label for="parkinghall"><img class="icon" src="parking.png"/>  Parking Hall</label><br />
            <input style="margin-right: 5px;" type="checkbox" id="trafficcamera" name="filter" onchange="promptMaxResults('trafficcamera');" autocomplete="off"/><label for="trafficcamera"><img class="icon" src="cam.png"/>  Traffic Camera</label><br />
            <input style="margin-right: 5px;" type="checkbox" id="trafficstation" name="filter" onchange="promptMaxResults('trafficstation');" autocomplete="off"/><label for="trafficstation"><img class="icon" src="traffic.png"/>  Traffic Station</label><br />
            <input style="margin-right: 5px;" type="checkbox" id="lightsource" name="filter" onchange="promptMaxResults('lightsource');" autocomplete="off"/><label for="lightsource"><img class="icon" src="lightsource.png"/>  Light Source</label><br />
            <input style="margin-right: 5px;" type="checkbox" id="windmill" name="filter" onchange="promptMaxResults('windmill');" autocomplete="off"/><label for="windmill"><img class="icon" src="windmill.png"/>  Windmill</label>
        </div>
        <div id="text"></div>
    </body>
</html>
