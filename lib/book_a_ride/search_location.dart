import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import 'package:http/http.dart' as http;
import 'package:firebase_database/firebase_database.dart';
import 'package:hopin/book_a_ride/search_ride.dart';
import 'package:hopin/inbox/inbox.dart';
import 'package:hopin/user_home/account_settings.dart';
import 'package:hopin/user_home/post_ride_selection.dart';
import 'package:hopin/user_home/home_page.dart';

import '../my_rides/myrides.dart';
import '../user_home/user_profile.dart';

class SearchLocation extends StatefulWidget {
  final String phoneNumber;

  SearchLocation({required this.phoneNumber});

  @override
  _SearchLocationState createState() => _SearchLocationState();
}

class _SearchLocationState extends State<SearchLocation> {
  GoogleMapController? mapController;
  LatLng? pickupLocation;
  LatLng? destinationLocation;
  Set<Marker> markers = {};
  Set<Polyline> polylines = {};
  final TextEditingController destinationController = TextEditingController();
  final TextEditingController pickupController = TextEditingController();
  bool canNavigate = false;
  bool showInfoBar = false;

  bool hasVehicle = false;
  bool isPageLocked = false;

  @override
  void initState() {
    super.initState();
    _getCurrentLocation();
  }

  Future<void> _getCurrentLocation() async {
    bool serviceEnabled;
    LocationPermission permission;

    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) return;

    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission != LocationPermission.whileInUse &&
          permission != LocationPermission.always) return;
    }

    Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high);

    setState(() {
      pickupLocation = LatLng(position.latitude, position.longitude);
      pickupController.text =
      "${pickupLocation!.latitude}, ${pickupLocation!.longitude}";
    });

    if (mapController != null) {
      mapController!.animateCamera(CameraUpdate.newLatLng(pickupLocation!));
    }
  }

  Future<void> _selectDestination(String query) async {
    if (query.isEmpty) return;

    try {
      List<Location> locations = await locationFromAddress(query);

      if (locations.isNotEmpty) {
        setState(() {
          destinationLocation =
              LatLng(locations[0].latitude, locations[0].longitude);
          canNavigate = true;
        });

        if (destinationLocation != null && pickupLocation != null) {
          _fetchRoute(pickupLocation!, destinationLocation!);
        }

        if (mapController != null && destinationLocation != null) {
          mapController!.animateCamera(
              CameraUpdate.newLatLngZoom(destinationLocation!, 15));
        }

        Future.delayed(Duration(seconds: 3), () {
          setState(() {
            showInfoBar = false;
          });
        });
        setState(() {
          showInfoBar = true;
        });
      }
    } catch (e) {
      print("Error: $e");
    }
  }

  Future<void> _fetchRoute(LatLng origin, LatLng destination) async {
    String googleApiKey = "AIzaSyCaIEkMGfeHVy0ExgO7OGO9YGwOKFRtB7Y";

    final String url =
        "https://maps.googleapis.com/maps/api/directions/json?origin=${origin.latitude},${origin.longitude}&destination=${destination.latitude},${destination.longitude}&key=$googleApiKey";

    final response = await http.get(Uri.parse(url));

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);

      if (data['status'] == 'OK') {
        var points = data['routes'][0]['overview_polyline']['points'];
        List<LatLng> routeCoords = _decodePolyline(points);

        setState(() {
          polylines.add(Polyline(
            polylineId: PolylineId("route"),
            points: routeCoords,
            color: Colors.blue,
            width: 5,
          ));
        });
      }
    }
  }

  List<LatLng> _decodePolyline(String encoded) {
    List<LatLng> polylinePoints = [];
    int index = 0;
    int len = encoded.length;
    int lat = 0;
    int lng = 0;

    while (index < len) {
      int b, shift = 0, result = 0;
      do {
        b = encoded.codeUnitAt(index++) - 63;
        result |= (b & 0x1f) << shift;
        shift += 5;
      } while (b >= 0x20);
      int dLat = ((result & 1) != 0 ? ~(result >> 1) : (result >> 1));
      lat += dLat;

      shift = 0;
      result = 0;
      do {
        b = encoded.codeUnitAt(index++) - 63;
        result |= (b & 0x1f) << shift;
        shift += 5;
      } while (b >= 0x20);
      int dLng = ((result & 1) != 0 ? ~(result >> 1) : (result >> 1));
      lng += dLng;

      polylinePoints.add(LatLng(lat / 1E5, lng / 1E5));
    }

    return polylinePoints;
  }

  Set<Marker> _createMarkers() {
    return {
      if (pickupLocation != null)
        Marker(
          markerId: MarkerId('pickup'),
          position: pickupLocation!,
          infoWindow: InfoWindow(
            title: "Your Location",
            snippet: "Tap this marker to set your pickup location.",
          ),
        ),
      if (destinationLocation != null)
        Marker(
          markerId: MarkerId('destination'),
          position: destinationLocation!,
          infoWindow: InfoWindow(
            title: "Click for Navigation Options",
            snippet: "Tap this marker to see Google Maps options.",
          ),
          icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed),
        ),
    };
  }

  Future<void> _updatePickupLocation(String address) async {
    try {
      List<Location> locations = await locationFromAddress(address);

      if (locations.isNotEmpty) {
        setState(() {
          pickupLocation = LatLng(locations[0].latitude, locations[0].longitude);
          pickupController.text = address;
        });

        if (mapController != null && pickupLocation != null) {
          mapController!.animateCamera(CameraUpdate.newLatLng(pickupLocation!));
        }
      }
    } catch (e) {
      print("Error: $e");
    }
  }


  Future<double> _calculateDistance() async {
    if (pickupLocation != null && destinationLocation != null) {
      double distanceInMeters = await Geolocator.distanceBetween(
        pickupLocation!.latitude,
        pickupLocation!.longitude,
        destinationLocation!.latitude,
        destinationLocation!.longitude,
      );
      return distanceInMeters / 1000; // Convert meters to kilometers
    }
    return 0.0; // Return 0 if locations are not valid
  }


  void setLocation() async {
    if (pickupLocation != null && destinationLocation != null) {
      double distance = await _calculateDistance();

      // Check if the distance is below the threshold
      if (distance < 3) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("The distance must be at least 3 km."),
            backgroundColor: Colors.redAccent,
          ),
        );
        return;
      }

      // Debug log for confirmation
      print("Proceeding with navigation:");
      print("pickupLocation: $pickupLocation");
      print("destinationLocation: $destinationLocation");
      print("distance: $distance");

      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => SearchRide(
            params: SearchRideParams(
              currentUserPhone: widget.phoneNumber,
              pickupLatitude: pickupLocation!.latitude,
              pickupLongitude: pickupLocation!.longitude,
              destinationLatitude: destinationLocation!.latitude,
              destinationLongitude: destinationLocation!.longitude,
              pickupAddress: pickupController.text,
              destinationAddress: destinationController.text,
              distanceInKm: distance,
            ),
          ),
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Please select both pickup and destination locations.")),
      );
    }
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
        bottomNavigationBar: BottomNavigationBar(
          type: BottomNavigationBarType.fixed,
          backgroundColor: Color(0xFFEFE5DC),
          selectedItemColor: Color(0xFF154314),
          unselectedItemColor: Color(0xFF154314).withOpacity(0.7),
          iconSize: 30,
          selectedFontSize: 14,
          unselectedFontSize: 12,
          items: [
            BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Book Ride'),
            BottomNavigationBarItem(icon: Icon(Icons.add_circle_outline), label: 'Post Ride'),
            BottomNavigationBarItem(icon: Icon(Icons.directions_car), label: 'Your Rides'),
            BottomNavigationBarItem(icon: Icon(Icons.message), label: 'Inbox'),
            BottomNavigationBarItem(icon: Icon(Icons.account_circle), label: 'Account'),
          ],
          onTap: (index) {
            if (index == 0) {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => HomePage(phoneNumber: widget.phoneNumber),
                ),
              );
            }
            else if (index == 1) {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => PostRideSelectionPage(phoneNumber: widget.phoneNumber),
                ),
              );
            } else if (index == 2) {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => MyRidesPage(phoneNumber: widget.phoneNumber),
                ),
              );
            } else if (index == 3) {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => InboxPage(phoneNumber: widget.phoneNumber),
                ),
              );
            } else if (index == 4) {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => UserProfileViewPage(phoneNumber: widget.phoneNumber),
                ),
              );
            }
          },
        ),
      appBar: AppBar(
        backgroundColor: Color(0xFF154315),
        centerTitle: true,
        title: Row(
          children: [
            IconButton(
              icon: Icon(Icons.arrow_back),
              color: Colors.white,
              onPressed: () {
                Navigator.pop(context);
              },
            ),
            SizedBox(width: 8),
            Text(
              "Search location details",
              style: GoogleFonts.poppins(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
          ],
        ),
        automaticallyImplyLeading: false,
      ),
      body: Stack(
        children: [
          Container(
            color: Color(0xFFEFE5DC),
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                children: [
                  TextField(
                    controller: pickupController,
                    style: GoogleFonts.poppins(),
                    decoration: InputDecoration(
                      labelText: 'Enter Pickup Location',
                      labelStyle: GoogleFonts.poppins(
                        fontWeight: FontWeight.w500,
                        color: Colors.black87,
                      ),
                      hintText:
                      'Current Location: ${pickupLocation?.latitude}, ${pickupLocation?.longitude}',
                      hintStyle: GoogleFonts.poppins(
                        fontWeight: FontWeight.w400,
                        color: Colors.grey,
                      ),
                    ),
                    onChanged: (value) {
                      _updatePickupLocation(value);
                    },
                  ),
                  SizedBox(height: 20),
                  TextField(
                    controller: destinationController,
                    style: GoogleFonts.poppins(),
                    decoration: InputDecoration(
                      labelText: 'Enter Destination Location',
                      labelStyle: GoogleFonts.poppins(
                        fontWeight: FontWeight.w500,
                        color: Colors.black87,
                      ),
                      hintStyle: GoogleFonts.poppins(
                        fontWeight: FontWeight.w400,
                        color: Colors.grey,
                      ),
                    ),
                    onChanged: (value) {
                      _selectDestination(value);
                    },
                  ),
                  SizedBox(height: 25),
                  Expanded(
                    child: GoogleMap(
                      initialCameraPosition: CameraPosition(
                        target: LatLng(0, 0),
                        zoom: 14.0,
                      ),
                      onMapCreated: (controller) {
                        mapController = controller;
                      },
                      markers: _createMarkers(),
                      polylines: polylines,
                      myLocationEnabled: true,
                      myLocationButtonEnabled: true,
                    ),
                  ),
                  SizedBox(height: 30),
                  ElevatedButton(
                    onPressed: () {
                      print("Set Location button pressed");
                      setLocation();
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Color(0xFF154315),
                      padding: EdgeInsets.symmetric(vertical: 20, horizontal: 30), // Increase padding
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),

                    child: Text(
                      'Set Location',
                      style: GoogleFonts.poppins(
                        fontWeight: FontWeight.bold, // Make the font bold
                        color: Colors.white, // White color for text
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          if (showInfoBar)
            Positioned(
              top: 16,
              left: 0,
              right: 0,
              child: Container(
                padding: EdgeInsets.all(10),
                color: Colors.green,
                child: Text(
                  "You can proceed now!",
                  style: TextStyle(color: Colors.white),
                  textAlign: TextAlign.center,
                ),
              ),
            ),
        ],
      ),
    );
  }
}
