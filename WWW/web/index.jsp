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
            #map-canvas { height: 500px }
        </style>
        <script type="text/javascript">
            var initialLocation;
            
            function initialize(){
                var ouluLocation = new google.maps.LatLng(65.1, 25.28);

                var mapOptions = {
                    zoom: 16
                };
                var map = new google.maps.Map(document.getElementById("map-canvas"), mapOptions);
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
        </script>
    </head>
    <body>
        <h1>Hello World!</h1>
        <div id="map-canvas"></div>
    </body>
</html>
