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
        <script src="https://maps.googleapis.com/maps/api/js?key=AIzaSyAw7kc4ra3lql7rWxxDl7wII4WZ8p8Gf_g&sensor=true"></script>
        <style type="text/css">
            #map-canvas { height: 500px; }
            .icon { width: 16px; height: 16px; }
        </style>
        <script type="text/javascript">
            var initialLocation;
            var url = 'http://dev.cyberlightning.com:44446/';
            var map;
            var busMarkers = new Array();
            var wlanMarkers = new Array();
            var parkingMarkers = new Array();
            var trafficMarkers = new Array();
            var camMarkers = new Array();
            var weatherMarkers = new Array();
            
            function initialize(){
                var ouluLocation = new google.maps.LatLng(65.1, 25.28);

                var mapOptions = {
                    zoom: 12
                };
                map = new google.maps.Map(document.getElementById("map-canvas"), mapOptions);
                map.setCenter(ouluLocation);
                
                
                if(navigator.geolocation){
                    browserSupportFlag = true;
                    navigator.geolocation.getCurrentPosition(function(position){
                        initialLocation = new google.maps.LatLng(position.coords.latitude,position.coords.longitude);
                        map.setCenter(initialLocation);

                        var marker = new google.maps.Marker({
                            position: initialLocation,
                            title: 'Your Location',
                            map: map
                        });
                        
                        $.ajax({
                            type: "GET",
                            url: url,
                            dataType: 'json',
                            data: {
                                action: "loadBySpatial",
                                lat: position.coords.latitude,
                                lon: position.coords.longitude,
                                radius: 100000,
                                maxResults: 750
                            }
                        }).success(function(response) {
                            var markers = new Array();
                            var keys = Object.keys(response);
                            
                            for (var i = 0; i < keys.length; i ++){
                                var sensorKey = keys[i];
                                var sensorName = response[keys[i]].attributes.name;
                                var sensorType = response[keys[i]].attributes.type;
                                var sensorIcon;

                                switch (sensorType) {
                                    case ('bus'):
                                        sensorIcon = 'bus.png';
                                        break;
                                    case ('wlanstation'):
                                        sensorIcon = 'wlan.png';
                                        break;
                                    case ('weatherstation'):
                                        sensorIcon = 'weather.png';
                                        break;
                                    case ('parkinghall'):
                                        sensorIcon = 'parking.png';
                                        break;
                                    case ('trafficcamera'):
                                        sensorIcon = 'cam.png';
                                        break;
                                    case ('trafficstation'):
                                        sensorIcon = 'traffic.png';
                                        break;
                                }

                                var sensorLat = response[keys[i]].attributes.gps[0];
                                var sensorLng = response[keys[i]].attributes.gps[1];

                                var sensorPosition = new google.maps.LatLng(sensorLat, sensorLng);

                                markers[i] = new google.maps.Marker({
                                    position: sensorPosition,
                                    title: sensorName,
                                    map: map,
                                    icon: sensorIcon
                                });
                                
                                if (sensorType == "bus"){
                                    busMarkers.push(markers[i]);
                                    addOnBusClick(markers[i], sensorKey);
                                }else if (sensorType == "trafficcamera"){
                                    camMarkers.push(markers[i]);
                                    addOnCamClick(markers[i], sensorKey);
                                }else if (sensorType != "wlanstation"){
                                    addOnInfoClick(markers[i], sensorKey);
                                    if (sensorType == "weatherstation"){
                                        weatherMarkers.push(markers[i]);
                                    }
                                    if (sensorType == "trafficstation"){
                                        trafficMarkers.push(markers[i]);
                                    }
                                    if (sensorType == "parkinghall"){
                                        parkingMarkers.push(markers[i]);
                                    }
                                }else{
                                    wlanMarkers.push(markers[i]);
                                }
                            }
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
                    openImage(sensorKey);
                });
            }
            
            function addOnInfoClick(sensorMarker, sensorKey){
                google.maps.event.addListener(sensorMarker, 'click', function() {
                    showInfo(sensorMarker, sensorKey);
                });
            }
            
            function plotRoute(key){
                $.ajax({
                    type: "GET",
                    url: url,
                    dataType: 'json',
                    data: {
                        action: "loadById",
                        device_id: key,
                        maxResults: 1
                    }
                }).success(function(response) {
                    var sensorRouteCoords = new Array();
                    var sensorRouteLength = response[key].sensors[0].attributes.value_range.length;

                    for (var j = 0; j < (sensorRouteLength/2); j++){
                        var sensorRouteLat = response[key].sensors[0].attributes.value_range[(j * 2)];
                        var sensorRouteLng = response[key].sensors[0].attributes.value_range[(j * 2) + 1];
                        sensorRouteCoords.push(new google.maps.LatLng(sensorRouteLat, sensorRouteLng));
                    }
                    var sensorRoute = new google.maps.Polyline({
                        path: sensorRouteCoords,
                        map: map,
                        geodesic: true,
                        strokeColor: '#FF0000',
                        strokeOpacity: 1.0,
                        strokeWeight: 2
                    });
                });
            }
            
            function openImage(sensorKey){
                $.ajax({
                    type: "GET",
                    url: url,
                    dataType: 'json',
                    data: {
                        action: "loadById",
                        device_id: sensorKey,
                        maxResults: 1
                    }
                }).success(function(response) {
                    var sensorImage = response[sensorKey].sensors[0].values[0].values;
                    window.open(sensorImage);
                });
            }
            
            function showInfo(sensorMarker, sensorKey){
                $.ajax({
                    type: "GET",
                    url: url,
                    dataType: 'json',
                    data: {
                        action: "loadById",
                        device_id: sensorKey,
                        maxResults: 1
                    }
                }).success(function(response) {
                    switch (response[sensorKey].attributes.type){
                        case ('weatherstation'):
                            contentString = "Air temperature: " + response[sensorKey].sensors[0].values[0].values + " C" +
                                    "<br />Road temperature: " + response[sensorKey].sensors[1].values[0].values + " C" +
                                    "<br />Rain intensity: " + response[sensorKey].sensors[2].values[0].values;
                            break;
                        case ('parkinghall'):
                            contentString = "Free places: " + response[sensorKey].sensors[0].values[0].values +
                                    "<br />Total places: " + response[sensorKey].sensors[1].values[0].values;
                            break;
                        case ('trafficstation'):
                            contentString = "Traffic speed in: " + response[sensorKey].sensors[0].values[0].values + " km/h" +
                                    "<br />Traffic speed out: " + response[sensorKey].sensors[1].values[0].values + " km/h";
                            break;
                    }
                    var infoWindow = new google.maps.InfoWindow({
                        content: "<div style='width: 175px; height: 100px;'>" + contentString + "</div>"
                    });
                    infoWindow.open(map,sensorMarker);
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
                var maxResults = prompt("Number of results");
                
                if(maxResults===null){
                    $('#' + sensorType).attr('checked',false);
                }else{
                    $.ajax({
                    type: "GET",
                    url: url,
                    dataType: 'json',
                    data: {
                        action: "loadBySpatialAndType",
                        lat: position.coords.latitude,
                        lon: position.coords.longitude,
                        radius: 100000,
                        maxResults: maxResults,
                        type: sensorType
                    }
                }).success(function(response) {
                    var sensorImage = response[sensorKey].sensors[0].values[0].values;
                    window.open(sensorImage);
                });
                }
            }
        </script>
    </head>
    <body>
        <h1>Hello World!</h1>
        <div id="map-canvas"></div>
        <div style="position: absolute; right: 10%; top: 20%; background-color: white; border: solid 1px black; padding: 5px;">
            <input style="margin-right: 5px;" type="checkbox" id="bus" name="filter" onchange="promptMaxResults('bus');" autocomplete="off"/><label for="bus"><img class="icon" src="bus.png"/>  Oulu Bus</label><br />
            <input style="margin-right: 5px;" type="checkbox" id="wlanstation" name="filter" onchange="promptMaxResults('wlanstation');" autocomplete="off"/><label for="wlan"><img class="icon" src="wlan.png"/>  WLAN Station</label><br />
            <input style="margin-right: 5px;" type="checkbox" id="weatherstation" name="filter" onchange="promptMaxResults('weatherstation');" autocomplete="off"/><label for="weather"><img class="icon" src="weather.png"/>  Weather Station</label><br />
            <input style="margin-right: 5px;" type="checkbox" id="parkinghall" name="filter" onchange="promptMaxResults('parkinghall');" autocomplete="off"/><label for="parking"><img class="icon" src="parking.png"/>  Parking Hall</label><br />
            <input style="margin-right: 5px;" type="checkbox" id="trafficcamera" name="filter" onchange="promptMaxResults('trafficcamera');" autocomplete="off"/><label for="cam"><img class="icon" src="cam.png"/>  Traffic Camera</label><br />
            <input style="margin-right: 5px;" type="checkbox" id="trafficstation" name="filter" onchange="promptMaxResults('trafficstation');" autocomplete="off"/><label for="traffic"><img class="icon" src="traffic.png"/>  Traffic Station</label>
        </div>
    </body>
</html>
