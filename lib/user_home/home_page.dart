import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:hopin/post_ride/setup_location.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:hopin/tracking/live_tracking.dart';
import 'package:hopin/my_rides/myrides.dart';
import 'package:hopin/book_a_ride/search_location.dart';
import 'package:hopin/inbox/inbox.dart';
import 'package:hopin/user_home/account_settings.dart';
import 'package:hopin/user_home/post_ride_selection.dart';
import 'package:hopin/support/support_chart.dart';
import 'package:hopin/user_home/user_profile.dart';
import 'package:shared_preferences/shared_preferences.dart';

class HomePage extends StatefulWidget {
  final String phoneNumber;

  HomePage({required this.phoneNumber});

  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  String username = "Loading...";
  String profileImageUrl = "";
  String locationText = "Fetching location...";
  late GoogleMapController mapController;
  LatLng _initialPosition = LatLng(7.8731, 80.7718); // Default Sri Lanka

  Completer<GoogleMapController> _controller = Completer();

  @override
  void initState() {
    super.initState();
    _fetchUserData();
    _fetchLocation();
  }

  void _fetchUserData() async {
    DatabaseReference ref = FirebaseDatabase.instance.ref("Users");
    DatabaseEvent event = await ref.once();
    Map<dynamic, dynamic>? users = event.snapshot.value as Map?;

    if (users != null) {
      users.forEach((key, value) {
        if (value['phone'] == widget.phoneNumber) {
          setState(() {
            username = value['username'] ?? "User";
            profileImageUrl = value['profileImageUrl'] ?? "";
          });
        }
      });
    }
  }

  void _navigateToSupportChat() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => SupportChatScreen(phoneNumber: widget.phoneNumber),
      ),
    );
  }


  void _fetchLocation() async {
    Position? position = await getCurrentLocation();

    if (position != null) {
      setState(() {
        locationText = "Lat: ${position.latitude}, Lng: ${position.longitude}";
        _initialPosition = LatLng(position.latitude, position.longitude);
      });

      Future.delayed(Duration(milliseconds: 500), () {
        if (_controller.isCompleted) {
          _controller.future.then((controller) {
            controller.animateCamera(CameraUpdate.newLatLng(_initialPosition));
          });
        }
      });
    } else {
      setState(() {
        locationText = "Location not available";
      });
    }
  }

  Future<Position?> getCurrentLocation() async {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) return null;

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.deniedForever) return null;
    }

    return await Geolocator.getCurrentPosition(
      desiredAccuracy: LocationAccuracy.high,
    );
  }

  Set<Marker> _createMarkers() {
    return {
      Marker(
        markerId: MarkerId('user_location'),
        position: _initialPosition,
        infoWindow: InfoWindow(
          title: "Click for Navigation Options",
          snippet: "Tap this marker to see Google Maps options.",
        ),
      ),
    };
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xFFEFE5DC),
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
          // if (index == 0) {
          //   Navigator.push(
          //     context,
          //     MaterialPageRoute(
          //       builder: (context) => HomePage(phoneNumber: widget.phoneNumber),
          //     ),
          //   );
          // }
           if (index == 1) {
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
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 25.0, vertical: 20),
              child: Row(
                children: [
                  CircleAvatar(
                    backgroundImage: profileImageUrl.isNotEmpty
                        ? NetworkImage(profileImageUrl)
                        : AssetImage('assets/images/user.png') as ImageProvider,
                    radius: 24,
                  ),
                  SizedBox(width: 10),
                  Text(
                    "Welcome, $username!",
                    style: GoogleFonts.poppins(fontSize: 20, fontWeight: FontWeight.w700, color: Color(0xFF154315)),
                  ),
                ],
              ),
            ),
            SizedBox(height: 15),
            Container(
              margin: EdgeInsets.symmetric(horizontal: 16),
              padding: EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.black,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                children: [
                  Text(
                    "Where do you want to go?",
                    style: GoogleFonts.poppins(fontSize: 16, color: Colors.white, fontWeight: FontWeight.w600),
                  ),
                  SizedBox(height: 25),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: GestureDetector(
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => SearchLocation(phoneNumber: widget.phoneNumber),
                              ),
                            );
                          },
                          child: _locationWidget(Icons.my_location, "Your location", locationText),
                        ),
                      ),
                      SizedBox(width: 13),
                      Expanded(
                        child: GestureDetector(
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => SearchLocation(phoneNumber: widget.phoneNumber),
                              ),
                            );
                          },
                          child: _locationWidget(Icons.location_on, "Destination", "Select a place"),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            SizedBox(height: 18),
            Expanded(
              child: Stack(
                children: [
                  GoogleMap(
                    initialCameraPosition: CameraPosition(target: _initialPosition, zoom: 14),
                    onMapCreated: (GoogleMapController controller) {
                      _controller.complete(controller);
                    },
                    markers: _createMarkers(),
                  ),
                  Positioned(
                    bottom: 40,
                    left: 16,
                    child: FloatingActionButton(
                      backgroundColor: Color(0xFF154314), // Green to match theme
                      child: Icon(Icons.support_agent, color: Colors.white),
                      onPressed: _navigateToSupportChat,
                    ),
                  ),
                ],
              ),
            ),


          ],
        ),
      ),
    );
  }

  Widget _locationWidget(IconData icon, String title, String subtitle) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, color: Color(0xFF4C9C58)),
            SizedBox(width: 8),
            Text(title, style: GoogleFonts.poppins(fontSize: 14, color: Colors.white)),
          ],
        ),
        Text(subtitle, style: GoogleFonts.poppins(fontSize: 12, color: Colors.white70)),
      ],
    );
  }
}
