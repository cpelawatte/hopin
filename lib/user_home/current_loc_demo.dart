import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

class LocationPage extends StatefulWidget {
  @override
  _LocationPageState createState() => _LocationPageState();
}

class _LocationPageState extends State<LocationPage> {
  String locationText = "Fetching location...";
  late GoogleMapController mapController;
  LatLng _initialPosition = LatLng(0.0, 0.0); // Default initial position

  @override
  void initState() {
    super.initState();
    _fetchLocation(); // Fetch location as soon as the page loads
  }

  void _fetchLocation() async {
    Position? position = await getCurrentLocation();
    if (position != null) {
      setState(() {
        locationText = "Lat: ${position.latitude}, Lng: ${position.longitude}";
        _initialPosition = LatLng(position.latitude, position.longitude);
      });

      // Move the map to the new location if the controller is available
      if (mapController != null) {
        mapController.animateCamera(CameraUpdate.newLatLng(_initialPosition));
      }
    } else {
      setState(() {
        locationText = "Location not available";
      });
    }
  }

  // Function to get current location
  Future<Position?> getCurrentLocation() async {
    bool serviceEnabled;
    LocationPermission permission;

    // Check if location services are enabled
    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      print("Location services are disabled.");
      return null;
    }

    // Request permissions
    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.deniedForever) {
        print("Location permissions are permanently denied.");
        return null;
      }
    }

    // Get the current position
    Position position = await Geolocator.getCurrentPosition(
      desiredAccuracy: LocationAccuracy.high,
    );

    print("Latitude: ${position.latitude}, Longitude: ${position.longitude}");
    return position;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Current Location")),
      body: Column(
        children: [
          // Display Location Text
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Text(locationText, style: GoogleFonts.poppins(fontSize: 16)),
          ),
          // Google Map
          Expanded(
            child: GoogleMap(
              initialCameraPosition: CameraPosition(
                target: _initialPosition,
                zoom: 14,
              ),
              onMapCreated: (GoogleMapController controller) {
                mapController = controller;
                // Ensure the map moves once it's created
                _fetchLocation();
              },
              markers: {
                Marker(
                  markerId: MarkerId('user_location'),
                  position: _initialPosition,
                ),
              },
            ),
          ),
        ],
      ),
    );
  }
}
