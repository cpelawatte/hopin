
import 'package:hopin/inbox/inbox.dart';
import 'package:hopin/user_home/account_settings.dart';
import 'package:hopin/user_home/post_ride_selection.dart';
import 'package:hopin/user_home/home_page.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:google_fonts/google_fonts.dart';
import '../user_home/user_profile.dart';
import 'myrides.dart';
import 'ride_passengers.dart';
import 'package:hopin/tracking/live_tracking.dart';

class OfferedRidesTab extends StatefulWidget {
  final String phoneNumber;

  const OfferedRidesTab({Key? key, required this.phoneNumber}) : super(key: key);

  @override
  _OfferedRidesTabState createState() => _OfferedRidesTabState();
}

class _OfferedRidesTabState extends State<OfferedRidesTab> {
  Map<String, String> rideStatusMap = {};

  String getCurrentTimestamp() {
    return DateFormat('yyyy-MM-dd HH:mm:ss.SSSSSS').format(DateTime.now());
  }

  Future<void> sendNotificationToPassengers(String rideId, String status) async {
    final passengerSnapshot = await FirebaseDatabase.instance
        .ref()
        .child('passenger_per_ride')
        .child(rideId)
        .get();

    if (passengerSnapshot.exists) {
      final passengers = passengerSnapshot.value as Map<dynamic, dynamic>;

      for (var passenger in passengers.values) {
        final passengerPhone = passenger['passenger_phone'];
        final pickupAddress = passenger['pickup_address'];
        final destinationAddress = passenger['destination_address'];

        await FirebaseDatabase.instance.ref().child('notifications').push().set({
          'pickup_address': pickupAddress,
          'destination_address': destinationAddress,
          'requested_rider_phone': passengerPhone,
          'ride_id': rideId,
          'status': status,
          'isRead': false,
          'notification_date': getCurrentTimestamp(),
        });
      }
    }
  }

  Future<void> cancelRide(String rideId) async {
    final rideSnapshot = await FirebaseDatabase.instance.ref().child('Rides').child(rideId).get();

    if (rideSnapshot.exists) {
      final rideData = rideSnapshot.value;
      await FirebaseDatabase.instance.ref().child('cancelled_rides').child(rideId).set(rideData);
      await sendNotificationToPassengers(rideId, 'cancelled');
      await FirebaseDatabase.instance.ref().child('ride_status').child(rideId).set({
        'status': 'cancelled',
        'ride_id': rideId,
        'timestamp': getCurrentTimestamp(),
      });
      setState(() {
        rideStatusMap[rideId] = 'You have cancelled this ride';
      });
    }
  }

  Future<void> startRide(String rideId) async {
    await sendNotificationToPassengers(rideId, 'started');
    await FirebaseDatabase.instance.ref().child('ride_status').child(rideId).set({
      'status': 'started',
      'ride_id': rideId,
      'timestamp': getCurrentTimestamp(),
    });
    setState(() {
      rideStatusMap[rideId] = 'Ongoing ride';
    });
  }

  Future<void> endRide(String rideId) async {
    await sendNotificationToPassengers(rideId, 'ended');
    await FirebaseDatabase.instance.ref().child('ride_status').child(rideId).set({
      'status': 'ended',
      'ride_id': rideId,
      'timestamp': getCurrentTimestamp(),
    });
    setState(() {
      rideStatusMap[rideId] = 'This ride has been ended';
    });
  }

  Future<String> getAddressFromLatLng(double latitude, double longitude) async {
    const apiKey = 'AIzaSyCaIEkMGfeHVy0ExgO7OGO9YGwOKFRtB7Y'; // Replace with your API key.
    final url = Uri.parse(
        'https://maps.googleapis.com/maps/api/geocode/json?latlng=$latitude,$longitude&key=$apiKey');

    final response = await http.get(url);
    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      if (data['results'] != null && data['results'].isNotEmpty) {
        return data['results'][0]['formatted_address'] ?? 'Unknown Address';
      }
    }
    return 'Unknown Address';
  }

  Future<List<Map<String, dynamic>>> fetchOfferedRides() async {
    final snapshot = await FirebaseDatabase.instance
        .ref()
        .child('Rides')
        .orderByChild('phoneNumber')
        .equalTo(widget.phoneNumber)
        .get();

    if (!snapshot.exists || snapshot.value == null) {
      return [];
    }

    final ridesMap = snapshot.value as Map<dynamic, dynamic>;
    final rides = ridesMap.entries.toList();

    // Sort rides by startDate from newest to oldest.
    rides.sort((a, b) =>
        DateTime.parse(b.value['startDate'])
            .compareTo(DateTime.parse(a.value['startDate'])));

    // Group rides by date.
    final Map<String, List<MapEntry<dynamic, dynamic>>> groupedRides = {};
    for (var ride in rides) {
      final rideDate = DateFormat('yyyy-MM-dd')
          .format(DateTime.parse(ride.value['startDate']));
      groupedRides.putIfAbsent(rideDate, () => []).add(ride);
    }

    // For each ride, add additional details.
    List<Map<String, dynamic>> offeredRides = [];

    for (var group in groupedRides.values) {
      for (var rideEntry in group) {
        final rideData = rideEntry.value as Map<dynamic, dynamic>;
        final rideId = rideEntry.key;
        // Get the status from ride_status node.
        final statusSnapshot = await FirebaseDatabase.instance
            .ref()
            .child('ride_status')
            .child(rideId)
            .get();
        String rideStatus = '';
        if (statusSnapshot.exists &&
            statusSnapshot.value is Map<dynamic, dynamic>) {
          rideStatus = (statusSnapshot.value as Map<dynamic, dynamic>)['status'] ?? '';
        }
        if (rideStatus == 'started') {
          rideStatusMap[rideId] = 'Ongoing ride';
        } else if (rideStatus == 'cancelled') {
          rideStatusMap[rideId] = 'You have cancelled this ride';
        } else if (rideStatus == 'ended') {
          rideStatusMap[rideId] = 'This ride has been ended';
        }

        offeredRides.add({
          'rideId': rideId,
          'startDate': rideData['startDate'],
          'destination': rideData['destinationAddress'],
          'pickup': rideData['pickupAddress'],
          'selectedTime': rideData['selectedTime'],
          'vehicleType': rideData['vehicleType'],
          'seats_available': rideData['seats_available'],
          'pricePerPassenger': (rideData['pricePerPassenger'] as num).toStringAsFixed(2),
          'rideStatus': rideStatus,
          'showCancelButton': rideStatus != 'cancelled' &&
              rideStatus != 'ended' &&
              rideStatus != 'completed',
          'showEndRideButton': rideStatus != 'cancelled' &&
              rideStatus != 'ended' &&
              rideStatus != 'completed',
        });
      }
    }
    return offeredRides;
  }

  Future<void> _showEarningsCalculator() async {
    final DateTimeRange? picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2023),
      lastDate: DateTime.now(),
      builder: (context, child) {
        return Theme(
          data: ThemeData.light().copyWith(
            primaryColor: const Color(0xff154314),
            colorScheme: const ColorScheme.light(
              primary: Color(0xff154314),
              onPrimary: Colors.white,
              surface: Color(0xffefe5dc),
              onSurface: Colors.black,
            ),
            textTheme: GoogleFonts.poppinsTextTheme(),
          ),
          child: child!,
        );
      },
    );

    if (picked == null) return;

    final dbRef = FirebaseDatabase.instance.ref();
    double totalEarnings = 0.0;

    // 🔍 Get all rides offered by the current user (driver)
    final ridesSnapshot = await dbRef.child('Rides')
        .orderByChild('phoneNumber')
        .equalTo(widget.phoneNumber)
        .get();

    if (!ridesSnapshot.exists) return;

    for (final ride in ridesSnapshot.children) {
      final rideId = ride.key!;
      final rideData = ride.value as Map<dynamic, dynamic>;

      final startDateStr = rideData['startDate'];
      if (startDateStr == null) continue;

      final rideDate = DateTime.tryParse(startDateStr);
      if (rideDate == null ||
          rideDate.isBefore(picked.start) ||
          rideDate.isAfter(picked.end)) continue;

      final price = double.tryParse(rideData['pricePerPassenger'].toString()) ?? 0.0;

      // 👥 Get passenger count for this ride
      final passengerSnapshot = await dbRef.child('passenger_per_ride/$rideId').get();
      final passengerCount = passengerSnapshot.children.length;

      // 💰 Add to total earnings
      totalEarnings += price * passengerCount;
    }

    print("💰 Showing dialog with total earnings: Rs. $totalEarnings");

    // 🎯 Show total earnings dialog
    Future.delayed(Duration.zero, () {
      if (!mounted) return;
      showGeneralDialog(
        context: context,
        barrierDismissible: true,  // Keep this as true
        barrierLabel: MaterialLocalizations.of(context).modalBarrierDismissLabel,  // Add the barrierLabel here
        barrierColor: Colors.black54,
        transitionDuration: const Duration(milliseconds: 200),
        pageBuilder: (context, a1, a2) {
          return Center(
            child: Material(
              color: Colors.transparent,
              child: SingleChildScrollView(
                child: Container(
                  margin: const EdgeInsets.symmetric(horizontal: 30),
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: const Color(0xffefe5dc),
                    borderRadius: BorderRadius.circular(15),
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        "Total Earnings",
                        style: GoogleFonts.poppins(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.black,
                        ),
                      ),
                      const SizedBox(height: 10),
                      Text(
                        "Rs. ${totalEarnings.toStringAsFixed(2)} earned from\n${DateFormat('yyyy-MM-dd').format(picked.start)} to ${DateFormat('yyyy-MM-dd').format(picked.end)}",
                        style: GoogleFonts.poppins(fontSize: 14),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 20),
                      ElevatedButton(
                        onPressed: () => Navigator.pop(context),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xff154314),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                        child: Text(
                          "OK",
                          style: GoogleFonts.poppins(
                            color: Colors.white,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          );
        },
      );
    });
  }


  @override
  Widget build(BuildContext context) {
    return FutureBuilder<DataSnapshot>(
      future: FirebaseDatabase.instance
          .ref()
          .child('Rides')
          .orderByChild('phoneNumber')
          .equalTo(widget.phoneNumber)
          .get(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError) {
          return Center(child: Text('Error: ${snapshot.error}'));
        }
        final ridesData = snapshot.data!.value;
        if (ridesData == null) {
          return const Center(child: Text('No rides offered.'));
        }

        final ridesMap = ridesData as Map<dynamic, dynamic>;
        final rides = ridesMap.entries.toList();

        // Sort rides by startDate from newest to oldest.
        rides.sort((a, b) => DateTime.parse(b.value['startDate'])
            .compareTo(DateTime.parse(a.value['startDate'])));

        final Map<String, List<MapEntry<dynamic, dynamic>>> groupedRides = {};
        for (var ride in rides) {
          final rideDate = DateFormat('yyyy-MM-dd')
              .format(DateTime.parse(ride.value['startDate']));
          groupedRides.putIfAbsent(rideDate, () => []).add(ride);
        }

        return Scaffold(
          backgroundColor: const Color(0xffefe5dc),

          // ✅ BottomNavigationBar should be set here
          bottomNavigationBar: BottomNavigationBar(
            type: BottomNavigationBarType.fixed,
            backgroundColor: const Color(0xFFEFE5DC),
            selectedItemColor: const Color(0xFF154314),
            unselectedItemColor: const Color(0xFF154314).withOpacity(0.7),
            iconSize: 30,
            selectedFontSize: 14,
            unselectedFontSize: 12,
            items: const [
              BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Book Ride'),
              BottomNavigationBarItem(icon: Icon(Icons.add_circle_outline), label: 'Post Ride'),
              BottomNavigationBarItem(icon: Icon(Icons.directions_car), label: 'Your Rides'),
              BottomNavigationBarItem(icon: Icon(Icons.message), label: 'Inbox'),
              BottomNavigationBarItem(icon: Icon(Icons.account_circle), label: 'Account'),
            ],
            onTap: (index) {
              switch (index) {
                case 0:
                  Navigator.push(context, MaterialPageRoute(
                    builder: (context) => HomePage(phoneNumber: widget.phoneNumber),
                  ));
                  break;
                case 1:
                  Navigator.push(context, MaterialPageRoute(
                    builder: (context) => PostRideSelectionPage(phoneNumber: widget.phoneNumber),
                  ));
                  break;
                case 2:
                  Navigator.push(context, MaterialPageRoute(
                    builder: (context) => MyRidesPage(phoneNumber: widget.phoneNumber),
                  ));
                  break;
                case 3:
                  Navigator.push(context, MaterialPageRoute(
                    builder: (context) => InboxPage(phoneNumber: widget.phoneNumber),
                  ));
                  break;
                case 4:
                  Navigator.push(context, MaterialPageRoute(
                    builder: (context) => UserProfileViewPage(phoneNumber: widget.phoneNumber),
                  ));
                  break;
              }
            },
          ),

          // ✅ All scrollable content goes inside the body
          body: ListView(
            padding: const EdgeInsets.symmetric(vertical: 12),
            children: [
              // 💰 Earnings Button
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: ElevatedButton.icon(
                  onPressed: _showEarningsCalculator,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xff154314),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                  ),
                  icon: const Icon(Icons.attach_money, color: Colors.white),
                  label: Text(
                    "View My Earnings",
                    style: GoogleFonts.poppins(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),

              // Grouped Ride Cards
              ...groupedRides.entries.map((group) {
                return Card(
                  margin: const EdgeInsets.all(10),
                  elevation: 4,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  color: const Color(0xffefe5dc),
                  child: Padding(
                    padding: const EdgeInsets.all(10),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Rides on ${group.key}',
                          style: GoogleFonts.poppins(
                            fontWeight: FontWeight.bold,
                            fontSize: 18,
                            color: const Color(0xff154314),
                          ),
                        ),
                        const Divider(thickness: 1.5),

                        ...group.value.map((rideEntry) {
                          final rideData = rideEntry.value;
                          final rideId = rideEntry.key;
                          final pickupLat = rideData['pickupLatitude'] ?? 0.0;
                          final pickupLng = rideData['pickupLongitude'] ?? 0.0;

                          return FutureBuilder<String>(
                            future: getAddressFromLatLng(pickupLat, pickupLng),
                            builder: (context, addressSnapshot) {
                              if (addressSnapshot.connectionState == ConnectionState.waiting) {
                                return const Center(child: CircularProgressIndicator());
                              }
                              final pickupAddress = addressSnapshot.data ?? 'Unknown Address';

                              return FutureBuilder<DataSnapshot>(
                                future: FirebaseDatabase.instance
                                    .ref()
                                    .child('ride_status')
                                    .child(rideId)
                                    .get(),
                                builder: (context, statusSnapshot) {
                                  final rideStatusData = statusSnapshot.data?.value;
                                  String rideStatus = '';
                                  if (rideStatusData != null && rideStatusData is Map) {
                                    rideStatus = rideStatusData['status'] ?? '';
                                  }

                                  if (rideStatus == 'started') {
                                    rideStatusMap[rideId] = 'Ongoing ride';
                                  } else if (rideStatus == 'cancelled') {
                                    rideStatusMap[rideId] = 'You have cancelled this ride';
                                  } else if (rideStatus == 'ended') {
                                    rideStatusMap[rideId] = 'This ride has been ended';
                                  }

                                  return GestureDetector(
                                    onTap: () {
                                      if (rideStatus == 'started') {
                                        Navigator.push(
                                          context,
                                          MaterialPageRoute(
                                            builder: (context) => LiveTrackingPage(
                                              currentUserPhone: widget.phoneNumber,
                                              rideId: rideId,
                                            ),
                                          ),
                                        );
                                      }
                                    },
                                    child: Card(
                                      margin: const EdgeInsets.symmetric(vertical: 8),
                                      color: const Color(0xfff8f4f1),
                                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                      child: Padding(
                                        padding: const EdgeInsets.all(10),
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Text('Pickup: $pickupAddress', style: GoogleFonts.poppins(fontWeight: FontWeight.w600, fontSize: 15)),
                                            Text('Destination: ${rideData['destinationAddress']}', style: GoogleFonts.poppins(fontSize: 14)),
                                            Text('Time: ${rideData['selectedTime']}', style: GoogleFonts.poppins(fontSize: 14)),
                                            Text('Vehicle: ${rideData['vehicleType']}', style: GoogleFonts.poppins(fontSize: 14)),
                                            Text('Seats Available: ${rideData['seats_available']}', style: GoogleFonts.poppins(fontSize: 14)),
                                            Text('Price per Passenger: Rs. ${(rideData['pricePerPassenger'] as num).toStringAsFixed(2)}', style: GoogleFonts.poppins(fontSize: 14)),
                                            const SizedBox(height: 10),

                                            if (rideStatus == 'ended') ...[
                                              Text('This ride has been ended.', style: GoogleFonts.poppins(color: Colors.grey, fontWeight: FontWeight.bold)),
                                              //_buildRatePassengersSection(rideId),
                                            ]
                                            else if (rideStatusMap[rideId]?.isNotEmpty ?? false)
                                              Row(
                                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                                children: [
                                                  Text(
                                                    rideStatusMap[rideId]!,
                                                    style: GoogleFonts.poppins(
                                                      fontWeight: FontWeight.w600,
                                                      fontSize: 14,
                                                      color: rideStatus == 'started' ? Colors.green : Colors.red,
                                                    ),
                                                  ),
                                                  if (rideStatus == 'started')
                                                    ElevatedButton(
                                                      onPressed: () => endRide(rideId),
                                                      style: ElevatedButton.styleFrom(backgroundColor: const Color(0xff154314)),
                                                      child: Text('End Ride', style: GoogleFonts.poppins(color: Colors.white)),
                                                    ),
                                                ],
                                              )
                                            else
                                              Row(
                                                mainAxisAlignment: MainAxisAlignment.spaceAround,
                                                children: [
                                                  ElevatedButton(
                                                    onPressed: () => startRide(rideId),
                                                    style: ElevatedButton.styleFrom(backgroundColor: const Color(0xff154314)),
                                                    child: Text('Start Ride', style: GoogleFonts.poppins(color: Colors.white)),
                                                  ),
                                                  ElevatedButton(
                                                    onPressed: () => cancelRide(rideId),
                                                    style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                                                    child: Text('Cancel Ride', style: GoogleFonts.poppins(color: Colors.white)),
                                                  ),
                                                ],
                                              ),

                                            if (rideStatus == 'started')
                                              GestureDetector(
                                                onTap: () {
                                                  FocusScope.of(context).requestFocus(FocusNode());
                                                  Navigator.push(
                                                    context,
                                                    MaterialPageRoute(
                                                      builder: (context) => RidePassengersScreen(
                                                        rideId: rideId,
                                                        phoneNumber: widget.phoneNumber,
                                                      ),
                                                    ),
                                                  );
                                                },
                                                child: Align(
                                                  alignment: Alignment.bottomCenter,
                                                  child: Text(
                                                    'View Passengers',
                                                    style: GoogleFonts.poppins(
                                                      color: Colors.blue,
                                                      fontWeight: FontWeight.bold,
                                                      fontSize: 14,
                                                    ),
                                                  ),
                                                ),
                                              ),
                                          ],
                                        ),
                                      ),
                                    ),
                                  );
                                },
                              );
                            },
                          );
                        }).toList(),
                      ],
                    ),
                  ),
                );
              }).toList(),
            ],
          ),
        );
      },
    );
  }
}

