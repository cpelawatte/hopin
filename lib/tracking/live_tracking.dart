import 'dart:async';
import 'dart:convert';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_polyline_points/flutter_polyline_points.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:geolocator/geolocator.dart';
import 'package:permission_handler/permission_handler.dart';
import 'dart:convert';

class LiveTrackingPage extends StatefulWidget {
  final String currentUserPhone;
  final String rideId;

  LiveTrackingPage({required this.currentUserPhone, required this.rideId});

  @override
  _LiveTrackingPageState createState() => _LiveTrackingPageState();
}

class _LiveTrackingPageState extends State<LiveTrackingPage> {
  // Map controller
  GoogleMapController? _mapController;
  final Completer<GoogleMapController> _controller = Completer();

  // Initial camera position
  final LatLng _initialPosition = LatLng(7.8731, 80.7718);

  // Marker & polyline collections
  Set<Marker> _markers = {};
  Set<Polyline> _polylines = {};

  // Driver & passengers data
  LatLng? _driverLatLng;
  Map<String, LatLng> _passengersLatLng = {};
  Map<String, String> _passengerStatus = {};
  Map<String, String> _etas = {};
  Map<String, String> _usernames = {}; // Map to store usernames

  // Driver phone and ETA display
  String? _driverPhone;
  String _etaDisplay = '';

  // Google Maps API key
  static const String _googleMapsApiKey = 'AIzaSyCaIEkMGfeHVy0ExgO7OGO9YGwOKFRtB7Y';

  @override
  void initState() {
    super.initState();
    _initialiseTracking();
    Permission.location.request();


  }

  Future<void> _initialiseTracking() async {
    await _fetchDriverPhone();

    _listenToPassengerStatus();
    _listenToDriverLocation();
    await _fetchPassengers();
    if (widget.currentUserPhone != _driverPhone) {
      _listenToCurrentUserLocation();
    }
  }

  Future<void> _fetchDriverPhone() async {
    final ref = FirebaseDatabase.instance.ref('Rides/${widget.rideId}');
    final snap = await ref.get();
    if (snap.exists) {
      _driverPhone = snap.child('phoneNumber').value.toString();
    }
  }

  void _listenToPassengerStatus() {
    final ref = FirebaseDatabase.instance.ref('passenger_ride_status/${widget.rideId}');
    ref.onValue.listen((event) {
      final data = event.snapshot.value as Map<dynamic, dynamic>? ?? {};
      _passengerStatus = data.map((k, v) => MapEntry(k.toString(), v.toString()));
      _updateAll();
    });
  }

  Future<void> _fetchPassengers() async {
    final ref = FirebaseDatabase.instance.ref('passenger_per_ride/${widget.rideId}');
    final snap = await ref.get();
    if (snap.exists) {
      for (var child in snap.children) {
        final phone = child.child('passenger_phone').value.toString();
        if (phone != _driverPhone) {
          _listenToPassengerLocation(phone);
          await _fetchUsername(phone); // Fetch username for each passenger
        }
      }
    }
  }

  Future<void> _fetchUsername(String phone) async {
    final ref = FirebaseDatabase.instance.ref('Users').orderByChild('phone').equalTo(phone);
    final snap = await ref.get();
    if (snap.exists) {
      final user = snap.children.first;
      final username = user.child('username').value.toString();
      setState(() {
        _usernames[phone] = username; // Store the username in the map
      });
    }
  }

  void _listenToDriverLocation() {
    if (_driverPhone == null) return;
    final ref = FirebaseDatabase.instance.ref('Locations/$_driverPhone');
    ref.onValue.listen((event) {
      final m = event.snapshot.value as Map<dynamic, dynamic>? ?? {};
      final lat = m['latitude']?.toDouble();
      final lng = m['longitude']?.toDouble();
      if (lat != null && lng != null) {
        _driverLatLng = LatLng(lat, lng);
        _updateAll();
      }
    });
  }


  void _listenToCurrentUserLocation() {
    final me = widget.currentUserPhone;
    final ref = FirebaseDatabase.instance.ref('Locations/$me');
    ref.onValue.listen((event) {
      final m = event.snapshot.value as Map<dynamic, dynamic>? ?? {};
      final lat = m['latitude']?.toDouble();
      final lng = m['longitude']?.toDouble();
      if (lat != null && lng != null) {
        _passengersLatLng[me] = LatLng(lat, lng);
        _updateAll();
      }
    });
  }

  void _listenToPassengerLocation(String phone) {
    final ref = FirebaseDatabase.instance.ref('Locations/$phone');
    ref.onValue.listen((event) {
      final m = event.snapshot.value as Map<dynamic, dynamic>? ?? {};
      final lat = m['latitude']?.toDouble();
      final lng = m['longitude']?.toDouble();
      if (lat != null && lng != null) {
        _passengersLatLng[phone] = LatLng(lat, lng);
        _updateAll();
      }
    });
  }

  Future<void> _updateAll() async {
    if (_driverLatLng == null) return;
    final driverLoc = _driverLatLng!;

    // Clear existing
    _markers.clear();
    _polylines.clear();
    _etas.clear();

    // // Add driver marker
    // _markers.add(Marker(
    //   markerId: MarkerId('driver'),
    //   position: driverLoc,
    //   icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed),
    //   infoWindow: InfoWindow(title: 'Driver'),
    // ));

    if (widget.currentUserPhone == _driverPhone) {
      // Show driver marker ONLY for drivers
      _markers.add(Marker(
        markerId: MarkerId('driver'),
        position: driverLoc,
        icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed),
        infoWindow: InfoWindow(title: 'Driver'),
      ));
    }



    if (widget.currentUserPhone == _driverPhone) {
      // Driver sees all active passengers
      final active = _passengersLatLng.entries.where((e) {
        final status = _passengerStatus[e.key]?.toLowerCase() ?? '';
        return status != 'picked up' && status != 'cancelled';
      }).toList();

      // Add passenger markers
      for (var e in active) {
        final username = _usernames[e.key] ?? 'Passenger ${e.key}';
        _markers.add(Marker(
          markerId: MarkerId('passenger_${e.key}'),
          position: e.value,
          icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueAzure),
          infoWindow: InfoWindow(title: username),
        ));
      }

      // If at least one, draw only nearest route + ETA
      if (active.isNotEmpty) {
        active.sort((a, b) =>
            _distance(driverLoc, a.value).compareTo(_distance(driverLoc, b.value)));
        final nearest = active.first;
        await _drawRouteAndEta(nearest.key, driverLoc, nearest.value);
      }

      // Build ETA display sorted by minutes
      final sorted = _etas.entries.toList()
        ..sort((a, b) => _parseEta(a.value).compareTo(_parseEta(b.value)));
      _etaDisplay = sorted
          .map((e) => '${_usernames[e.key] ?? e.key}: ${e.value}')
          .join('\n');

      _moveCameraToFitAll();
    }
    else {
      // Passenger logic
      final me = widget.currentUserPhone;
      final meLoc = _passengersLatLng[me];
      final rideStatus = _passengerStatus[me]?.toLowerCase() ?? '';

      if (rideStatus == 'picked up') {
        final destSnapshot = await FirebaseDatabase.instance
            .ref('passenger_per_ride/${widget.rideId}')
            .get();

        LatLng? destinationLatLng;
        String? etaToDest;

        for (var child in destSnapshot.children) {
          final phone = child.child('passenger_phone').value.toString();
          if (phone == me) {
            final destAddress = child.child('destination_address').value.toString();
            destinationLatLng = await _getLatLngFromAddress(destAddress);

            if (destinationLatLng != null && meLoc != null) {
              // ✅ Green destination marker
              _markers.add(Marker(
                markerId: MarkerId('destination'),
                position: destinationLatLng,
                icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueGreen),
                infoWindow: InfoWindow(title: 'Destination'),
              ));

              // ✅ Blue marker for passenger's current location
              _markers.add(Marker(
                markerId: MarkerId('me'),
                position: meLoc,
                icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueBlue),
                infoWindow: InfoWindow(title: 'You'),
              ));

              // ✅ Route only from passenger to destination
              await _drawRouteAndEta(me, meLoc, destinationLatLng);

              // ✅ Open Google Maps with passenger-to-destination
              //_openGoogleMapsDirections(meLoc, destinationLatLng);

              etaToDest = _etas[me];
            }
            break;
          }
        }

        if (etaToDest != null) {
          _etaDisplay = 'ETA to Destination: $etaToDest';
        }
      }
      else {
        if (meLoc != null) {
          await _drawRouteAndEta(me, driverLoc, meLoc);
          _etaDisplay = _etas[me] ?? '';
        }
      }

      _moveCameraToFitAll();
    }

    setState(() {});
  }

  Future<void> _shareLiveLocationWithContact(String phoneNumber) async {
    final ref = FirebaseDatabase.instance.ref('Locations/${widget.currentUserPhone}');

    bool smsOpened = false;
    String locationUrl = '';
    DateTime? expireTime;

    // ETA + 30 mins logic
    if (_etas.containsKey(widget.currentUserPhone)) {
      final etaText = _etas[widget.currentUserPhone]!; // e.g., '12 mins'
      final minutes = int.tryParse(etaText.split(' ').first) ?? 0;
      expireTime = DateTime.now().add(Duration(minutes: minutes + 30));
    } else {
      expireTime = DateTime.now().add(Duration(minutes: 30));
    }

    // Declare the listener before assigning
    late StreamSubscription<DatabaseEvent> locationListener;
    Timer? updateTimer;

    // Attach Firebase listener
    locationListener = ref.onValue.listen((event) async {
      if (expireTime != null && DateTime.now().isAfter(expireTime)) {
        updateTimer?.cancel();
        locationListener.cancel();
        debugPrint("Location sharing stopped after ETA + 30 mins.");
        return;
      }

      final m = event.snapshot.value as Map<dynamic, dynamic>? ?? {};
      final lat = m['latitude']?.toDouble();
      final lng = m['longitude']?.toDouble();

      if (lat != null && lng != null) {
        locationUrl = "https://www.google.com/maps/search/?api=1&query=$lat,$lng";
        final message = 'Hey! Here’s my live location: $locationUrl';
        final smsUri = 'sms:?body=${Uri.encodeComponent(message)}';

        if (!smsOpened) {
          if (await canLaunchUrl(Uri.parse(smsUri))) {
            await launchUrl(Uri.parse(smsUri));
            smsOpened = true;
            debugPrint('SMS launched with initial location.');
          } else {
            debugPrint('Could not launch SMS app');
          }
        } else {
          debugPrint('Location updated: $lat,$lng');
        }
      }
    });

    // Backup timer just in case listener doesn't cancel
    updateTimer = Timer.periodic(Duration(minutes: 1), (t) {
      if (expireTime != null && DateTime.now().isAfter(expireTime)) {
        t.cancel();
        locationListener.cancel();
        debugPrint("Safety net: timer cancelled after ETA + 30 mins.");
      }
    });
  }

  Future<void> _openGoogleMapsDirections(LatLng origin, LatLng destination) async {
    final String url =
        'https://www.google.com/maps/dir/?api=1&origin=${origin.latitude},${origin.longitude}&destination=${destination.latitude},${destination.longitude}&travelmode=driving';

    if (await canLaunchUrl(Uri.parse(url))) {
      await launchUrl(Uri.parse(url));
    } else {
      debugPrint('Could not open Google Maps.');
    }
  }

  Future<LatLng?> _getLatLngFromAddress(String address) async {
    final url = 'https://maps.googleapis.com/maps/api/geocode/json?address=${Uri.encodeComponent(address)}&key=$_googleMapsApiKey';
    final response = await http.get(Uri.parse(url));
    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      final results = data['results'] as List;
      if (results.isNotEmpty) {
        final location = results[0]['geometry']['location'];
        return LatLng(location['lat'], location['lng']);
      }
    }
    return null;
  }


  Future<void> _drawRouteAndEta(String phone, LatLng origin, LatLng dest) async {
    final originStr = '${origin.latitude},${origin.longitude}';
    final destStr = '${dest.latitude},${dest.longitude}';
    final url =
        'https://maps.googleapis.com/maps/api/directions/json?origin=$originStr&destination=$destStr&key=$_googleMapsApiKey';
    final res = await http.get(Uri.parse(url));
    if (res.statusCode == 200) {
      final routes = json.decode(res.body)['routes'] as List;
      if (routes.isNotEmpty) {
        final route = routes[0];
        final poly = route['overview_polyline']['points'];
        final dur = route['legs'][0]['duration']['text'];
        final pts = PolylinePoints().decodePolyline(poly);
        _polylines.add(Polyline(
          polylineId: PolylineId('route_$phone'),
          points: pts.map((p) => LatLng(p.latitude, p.longitude)).toList(),
          width: 5,
        ));
        _etas[phone] = dur;
      }
    }
  }

  void _moveCameraToFitAll() {
    final all = <LatLng>[if (_driverLatLng != null) _driverLatLng!, ..._passengersLatLng.values];
    if (all.isEmpty || _mapController == null) return;
    var latMin = all.first.latitude,
        latMax = all.first.latitude,
        lngMin = all.first.longitude,
        lngMax = all.first.longitude;
    for (var p in all) {
      latMin = min(latMin, p.latitude);
      latMax = max(latMax, p.latitude);
      lngMin = min(lngMin, p.longitude);
      lngMax = max(lngMax, p.longitude);
    }
    final bounds = LatLngBounds(
      southwest: LatLng(latMin, lngMin),
      northeast: LatLng(latMax, lngMax),
    );
    _mapController?.animateCamera(CameraUpdate.newLatLngBounds(bounds, 80));
  }

  int _parseEta(String text) {
    var mins = 0;
    final parts = text.split(' ');
    for (var i = 0; i < parts.length; i++) {
      if (parts[i].contains('hour')) mins += int.tryParse(parts[i - 1])! * 60;
      if (parts[i].contains('min')) mins += int.tryParse(parts[i - 1])!;
    }
    return mins;
  }

  double _distance(LatLng a, LatLng b) => sqrt(pow(a.latitude - b.latitude, 2) + pow(a.longitude - b.longitude, 2));

  @override
  void dispose() {
    super.dispose();
  }


  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        double screenHeight = constraints.maxHeight;
        double screenWidth = constraints.maxWidth;

        return Scaffold(
          appBar: AppBar(
            backgroundColor: const Color(0xff154314),
            iconTheme: const IconThemeData(color: Colors.white),
            title: Text(
              'Live Tracking',
              style: GoogleFonts.poppins(color: Colors.white, fontSize: screenWidth * 0.05),
            ),
          ),

          body: Stack(
            children: [
              // 🌍 Google Map
              GoogleMap(
                initialCameraPosition: CameraPosition(target: _initialPosition, zoom: 14),
                onMapCreated: (controller) {
                  _controller.complete(controller);
                  _mapController = controller;
                },
                markers: _markers,
                polylines: _polylines,
                  onTap: (LatLng _) async {
                    final me = widget.currentUserPhone;
                    final isDriver = me == _driverPhone;
                    final rideStatus = _passengerStatus[me]?.toLowerCase() ?? '';
                    final meLoc = _passengersLatLng[me];

                    if (isDriver && _driverLatLng != null) {
                      // Get list of active passengers
                      final active = _passengersLatLng.entries.where((e) {
                        final status = _passengerStatus[e.key]?.toLowerCase() ?? '';
                        return status != 'picked up' && status != 'cancelled';
                      }).toList();

                      if (active.isNotEmpty) {
                        // Sort by nearest distance
                        active.sort((a, b) =>
                            _distance(_driverLatLng!, a.value).compareTo(_distance(_driverLatLng!, b.value)));

                        final nearest = active.first;
                        _openGoogleMapsDirections(_driverLatLng!, nearest.value);
                      } else {
                        debugPrint('No active passengers found.');
                      }
                    }
                    else if (!isDriver && rideStatus == 'picked up' && meLoc != null) {
                      // Passenger: get destination
                      final destSnapshot = await FirebaseDatabase.instance
                          .ref('passenger_per_ride/${widget.rideId}')
                          .get();

                      for (var child in destSnapshot.children) {
                        final phone = child.child('passenger_phone').value.toString();
                        if (phone == me) {
                          final destAddress = child.child('destination_address').value.toString();
                          final destinationLatLng = await _getLatLngFromAddress(destAddress);

                          if (destinationLatLng != null) {
                            _openGoogleMapsDirections(meLoc, destinationLatLng);
                          }
                          break;
                        }
                      }
                    } else {
                      debugPrint('Tap ignored: Not picked up or data missing.');
                    }
                  },
              ),

              Positioned(
                bottom: 244,
                right: 24,
                child: FloatingActionButton(
                  backgroundColor: const Color(0xFFFF7800), // Dark green
                  foregroundColor: const Color(0xffefe5dc), // Light beige
                  onPressed: () async {
                    const emergencyNumber = '119';
                    final Uri dialUri = Uri(scheme: 'tel', path: emergencyNumber);

                    if (await canLaunchUrl(dialUri)) {
                      await launchUrl(dialUri);
                      debugPrint('SOS initiated by $widget.currentUserPhone');
                    } else {
                      debugPrint('Could not launch dialer');
                    }
                  },
                  child: const Icon(Icons.sos, size: 30),
                  tooltip: 'Call Emergency',
                ),
              ),

              Positioned(
                bottom: 320, // 66px above SOS button
                right: 24,
                child: FloatingActionButton(
                  backgroundColor: Color(0xff154314),
                  foregroundColor: Colors.white,
                  onPressed: () {
                    _shareLiveLocationWithContact(widget.currentUserPhone); // Example phone number
                  },
                  child: const Icon(Icons.share),
                  tooltip: 'Share Live Location',
                ),
              ),

              _etaDisplay != "0"
                  ? Positioned(
                top: screenHeight * 0.02,
                left: screenWidth * 0.1,
                right: screenWidth * 0.1,
                child: Container(
                  padding: EdgeInsets.symmetric(
                    vertical: screenHeight * 0.015,
                    horizontal: screenWidth * 0.05,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xff154314),
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: const [
                      BoxShadow(
                        color: Colors.black26,
                        blurRadius: 6,
                        offset: Offset(0, 3),
                      ),
                    ],
                  ),
                  child: Text(
                    _etaDisplay,
                    style: GoogleFonts.poppins(
                      color: Colors.white,
                      fontSize: screenWidth * 0.035,
                      fontWeight: FontWeight.w500,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
              )
                  : const SizedBox.shrink(),


              // // SOS button widget
              // ElevatedButton(
              //   style: ElevatedButton.styleFrom(
              //     backgroundColor: Colors.red,
              //     foregroundColor: Colors.white,
              //     padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              //   ),
              //   onPressed: () async {
              //     const emergencyNumber = '119';
              //     final Uri dialUri = Uri(scheme: 'tel', path: emergencyNumber);
              //
              //     if (await canLaunchUrl(dialUri)) {
              //       await launchUrl(dialUri);
              //       debugPrint('SOS initiated by $widget.currentUserPhone');
              //     } else {
              //       debugPrint('Could not launch dialer');
              //     }
              //   },
              //   child: const Text('🚨 SOS'),
              // ),

              if (widget.currentUserPhone == _driverPhone)
                DraggableScrollableSheet(
                  initialChildSize: 0.3,
                  minChildSize: 0.1,
                  maxChildSize: 0.85,
                  builder: (context, scrollController) {
                  return Container(
                    width: screenWidth,
                    padding: EdgeInsets.symmetric(horizontal: screenWidth * 0.05),
                    decoration: BoxDecoration(
                    color: const Color(0xffefe5dc),
                    borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
                    boxShadow: const [
                      BoxShadow(
                          color: Colors.black26, blurRadius: 10),
                      ],
                    ),
                    child: Column(
                      children: [
                        SizedBox(height: screenHeight * 0.01),
                        Container(
                          width: screenWidth * 0.1,
                          height: screenHeight * 0.005,
                          margin: EdgeInsets.only(bottom: screenHeight * 0.015),
                          decoration: BoxDecoration(
                            color: Colors.grey[400],
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                        // 📋 List of Passengers
                        Expanded(
                          child: RidePassengerList(rideId: widget.rideId),
                          ),
                      ],
                      ),
                    );
                  },
                ),
        ],
          ),
        );
      },
    );
  }
}




class RidePassengerList extends StatefulWidget {
  final String rideId;

  const RidePassengerList({super.key, required this.rideId});

  @override
  State<RidePassengerList> createState() => _RidePassengerListState();
}

class _RidePassengerListState extends State<RidePassengerList> {
  final database = FirebaseDatabase.instance;

  Future<void> markPassengerAsPickedUp(String passengerPhone) async {
    try {
      await database
          .ref()
          .child('passenger_ride_status')
          .child(widget.rideId)
          .child(passengerPhone)
          .set('Picked Up');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Marked $passengerPhone as Picked Up')),
      );
      setState(() {});
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error updating status: $e')),
      );
    }
  }

  Future<String> getUsernameByPhone(String phone) async {
    try {
      final usersSnapshot = await database.ref().child('Users').get();
      final usersData = usersSnapshot.value as Map<dynamic, dynamic>?;
      if (usersData != null) {
        for (var entry in usersData.entries) {
          if (entry.value['phone'] == phone) {
            return entry.value['username'] ?? phone;
          }
        }
      }
      return phone;
    } catch (_) {
      return phone;
    }
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<DataSnapshot>(
      future: database.ref().child('passenger_per_ride').child(widget.rideId).get(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator(color: Color(0xff15431)));
        }
        if (snapshot.hasError) {
          return Center(child: Text('Error: ${snapshot.error}'));
        }

        final passengersData = snapshot.data!.value;
        if (passengersData == null) {
          return const Center(child: Text('No passengers found.'));
        }

        final passengers = (passengersData as Map<dynamic, dynamic>).values.toList();

        return ListView.builder(
          itemCount: passengers.length,
          itemBuilder: (context, index) {
            final passenger = passengers[index] as Map<dynamic, dynamic>;
            final phone = passenger['passenger_phone'] ?? '';
            final pickup = passenger['pickup_address'] ?? '';
            final drop = passenger['destination_address'] ?? '';

            return FutureBuilder<String>(
              future: getUsernameByPhone(phone),
              builder: (context, nameSnap) {
                final name = nameSnap.data ?? phone;

                return FutureBuilder<DataSnapshot>(
                  future: database.ref().child('passenger_ride_status').child(widget.rideId).child(phone).get(),
                  builder: (context, statusSnap) {
                    final status = statusSnap.data?.value?.toString() ?? '';

                    return Card(
                      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      elevation: 3,
                      child: Padding(
                        padding: const EdgeInsets.all(12),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(children: [
                              const Icon(Icons.person, color: Color(0xff154314)),
                              const SizedBox(width: 8),
                              Text(name, style: GoogleFonts.poppins(fontWeight: FontWeight.w600)),
                            ]),
                            const SizedBox(height: 6),
                            Text('Pickup: $pickup'),
                            Text('Destination: $drop'),
                            const SizedBox(height: 8),
                            Align(
                              alignment: Alignment.centerRight,
                              child: status != 'Picked Up'
                                  ? ElevatedButton(
                                onPressed: () => markPassengerAsPickedUp(phone),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: const Color(0xff154315),
                                ),
                                child: const Text('Pick Up', style: TextStyle( color: Colors.white, fontWeight: FontWeight.w600)),
                              )
                                  : Text('Picked Up', style: TextStyle(color: Colors.green)),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                );
              },
            );
          },
        );
      },
    );
  }
}
