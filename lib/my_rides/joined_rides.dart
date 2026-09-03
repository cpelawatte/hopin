import 'dart:async';
import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:intl/intl.dart';
import 'package:hopin/inapp_communication/new_conversation.dart';
import 'package:hopin/tracking/live_tracking.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:hopin/inbox/inbox.dart';
import 'package:hopin/user_home/account_settings.dart';
import 'package:hopin/user_home/post_ride_selection.dart';
import 'package:hopin/user_home/home_page.dart';

import '../user_home/user_profile.dart';
import 'myrides.dart';

class JoinedRidesTab extends StatefulWidget {
  final String phoneNumber;

  const JoinedRidesTab({Key? key, required this.phoneNumber}) : super(key: key);

  @override
  _JoinedRidesTabState createState() => _JoinedRidesTabState();
}

class _JoinedRidesTabState extends State<JoinedRidesTab> {
  final DatabaseReference dbRef = FirebaseDatabase.instance.ref();
  bool _showInfoMessage = true;
  Timer? _timer;
  // Tracks which completed rides have expanded the rate widget.
  final Set<String> _expandedRatingRideIds = {};

  Future<List<Map<String, dynamic>>> fetchJoinedRides() async {
    List<Map<String, dynamic>> joinedRides = [];

    final passengersSnapshot = await dbRef.child('passenger_per_ride').get();
    final rideStatuses = await fetchRideStatuses();


    for (var rideEntry in passengersSnapshot.children) {
      final rideId = rideEntry.key!;

      for (var passengerEntry in rideEntry.children) {
        final passengerPhone = passengerEntry.child('passenger_phone').value.toString();

        if (passengerPhone == widget.phoneNumber) {
          final rideDetails = await dbRef.child('Rides/$rideId').get();

          if (rideDetails.exists) {
            final driverPhone = rideDetails.child('phoneNumber').value.toString();
            final driverSnapshot = await dbRef
                .child('Users')
                .orderByChild('phone')
                .equalTo(driverPhone)
                .get();
            final driverUser = driverSnapshot.children.first;

            // Retrieve the ride's start date.
            final startDate = rideDetails.child('startDate').value.toString();

            // Check if the rating already exists.
            DataSnapshot ratingSnapshot = await dbRef
                .child('ratings')
                .child(driverPhone)
                .child(rideId)
                .get();
            bool hasRated = ratingSnapshot.exists;

            List<Map<String, dynamic>> coPassengers = [];
            for (var coPassengerEntry in rideEntry.children) {
              final cpPhone = coPassengerEntry.child('passenger_phone').value.toString();
              if (cpPhone != widget.phoneNumber) {
                final cpSnapshot = await dbRef
                    .child('Users')
                    .orderByChild('phone')
                    .equalTo(cpPhone)
                    .get();
                if (cpSnapshot.exists) {
                  final cpUser = cpSnapshot.children.first;
                  coPassengers.add({
                    'username': cpUser.child('username').value.toString(),
                    'profileImageUrl': cpUser.child('profileImageUrl').value.toString(),
                    'phone': cpPhone
                  });
                }
              }
            }

            final statusSnapshot = await dbRef
                .child('passenger_ride_status')
                .child(rideId)
                .child(widget.phoneNumber)
                .get();
            String rideStatus = statusSnapshot.exists
                ? statusSnapshot.value.toString().toLowerCase()
                : "";

            // Determine if the cancel or end ride button should be shown.
            bool showCancelButton = rideStatus != 'cancelled' &&
                rideStatus != 'ended' &&
                rideStatus != 'completed';
            bool showEndRideButton = rideStatus == 'picked up';

            final globalStatus = rideStatuses[rideId] ?? '';

            joinedRides.add({

              'rideId': rideId,
              'destination': rideDetails.child('destinationAddress').value.toString(),
              'pickup': rideDetails.child('pickupAddress').value.toString(),
              'time': rideDetails.child('selectedTime').value.toString(),
              'pricePerPassenger': (rideDetails.child('pricePerPassenger').value as num).toStringAsFixed(2),
              'driverUsername': driverUser.child('username').value.toString(),
              'driverImage': driverUser.child('profileImageUrl').value.toString(),
              'driverPhone': driverPhone,
              'startDate': startDate,
              'coPassengers': coPassengers,
              'status': rideStatus,
              'globalStatus': globalStatus,
              'rideCancelled': rideStatus == 'cancelled',
              'rideCompleted': rideStatus == 'ended',
              'showCancelButton': showCancelButton,
              'showEndRideButton': showEndRideButton,
              'hasRated': hasRated,
            });
          }
        }
      }
    }
    // Sort rides by startDate from newest to oldest.
    joinedRides.sort((a, b) {
      DateTime dateA = DateTime.parse(a['startDate']);
      DateTime dateB = DateTime.parse(b['startDate']);
      return dateB.compareTo(dateA);
    });
    return joinedRides;
  }

  void _openMessagePage(String coPassengerPhone) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => MessagePage(
          currentUserPhone: widget.phoneNumber,
          driverPhone: coPassengerPhone,
        ),
      ),
    );
  }

  Future<void> _cancelRide(String rideId) async {
    await dbRef.child('passenger_ride_status').child(rideId).child(widget.phoneNumber).set("Cancelled");

    final rideRef = dbRef.child('Rides/$rideId');
    final rideSnapshot = await rideRef.get();
    if (rideSnapshot.exists) {
      int currentSeats = rideSnapshot.child('seats_available').value as int;
      await rideRef.update({'seats_available': currentSeats + 1});
    }

    String currentDate = DateFormat('yyyy-MM-dd').format(DateTime.now());

    await dbRef.child('cancelled_passengers').push().set({
      'passenger_phone': widget.phoneNumber,
      'ride_id': rideId,
      'cancelled_on': currentDate,
    });

    setState(() {});
  }

  Future<Map<String, String>> fetchRideStatuses() async {
    final snapshot = await dbRef.child('ride_status').get();
    Map<String, String> rideStatuses = {};

    for (var entry in snapshot.children) {
      final rideId = entry.child('ride_id').value.toString();
      final status = entry.child('status').value.toString();
      rideStatuses[rideId] = status;
    }

    return rideStatuses;
  }


  Future<void> _endRide(String rideId) async {
    await dbRef.child('passenger_ride_status').child(rideId).child(widget.phoneNumber).set("ended");
    setState(() {});
  }

  @override
  void initState() {
    super.initState();
    _timer = Timer(const Duration(seconds: 4), () {
      setState(() {
        _showInfoMessage = false;
      });
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }


  @override
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xffefe5dc),
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
          if (index == 0) {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => HomePage(phoneNumber: widget.phoneNumber),
              ),
            );
          } else if (index == 1) {
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
      body: Container(
        color: const Color(0xffefe5dc),
        child: FutureBuilder<List<Map<String, dynamic>>>(
          future: fetchJoinedRides(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }

            if (!snapshot.hasData || snapshot.data!.isEmpty) {
              return Center(
                child: Text(
                  "No joined rides found.",
                  style: GoogleFonts.poppins(fontWeight: FontWeight.w500),
                ),
              );
            }

            final rides = snapshot.data!;

            return Column(
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  child: ElevatedButton.icon(
                    onPressed: _showDateRangePicker,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xff154314),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                    ),
                    icon: const Icon(Icons.attach_money, color: Colors.white),
                    label: Text(
                      "View My Expenses",
                      style: GoogleFonts.poppins(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),

                // 🔽 Rides List
                Expanded(
                  child: ListView.builder(
                    itemCount: rides.length,
                    itemBuilder: (context, index) {
                      final ride = rides[index];
                      bool isRideCancelled = ride['rideCancelled'];
                      bool isRideCompleted = ride['rideCompleted'];

                      String formattedDate = "";
                      try {
                        DateTime rideDate = DateTime.parse(ride['startDate']);
                        formattedDate = DateFormat('yyyy-MM-dd').format(rideDate);
                      } catch (e) {
                        formattedDate = "Unknown Date";
                      }

                      return GestureDetector(
                        onTap: () {
                          print('Ride Card: id=${ride['rideId']} | status=${ride['status']}');
                          if (ride['status'] == 'picked up' || ride['globalStatus'] == 'started') {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => LiveTrackingPage(
                                  currentUserPhone: widget.phoneNumber,
                                  rideId: ride['rideId'],
                                ),
                              ),
                            );
                          }
                        },
                        child: Card(
                          margin: const EdgeInsets.all(10),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                          elevation: 4,
                          color: isRideCancelled
                              ? Colors.grey[300]
                              : isRideCompleted
                              ? Colors.green[100]
                              : Colors.white,
                          child: Padding(
                            padding: const EdgeInsets.all(12.0),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Date: $formattedDate',
                                  style: GoogleFonts.poppins(
                                    fontWeight: FontWeight.w500,
                                    fontSize: 14,
                                    color: Colors.black87,
                                  ),
                                ),
                                const SizedBox(height: 5),
                                Row(
                                  children: [
                                    CircleAvatar(
                                      radius: 25,
                                      backgroundImage: NetworkImage(ride['driverImage']),
                                    ),
                                    const SizedBox(width: 10),
                                    Text(
                                      'Driver: ${ride['driverUsername']}',
                                      style: GoogleFonts.poppins(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 16,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 10),
                                Text('Pickup: ${ride['pickup']}', style: GoogleFonts.poppins(fontWeight: FontWeight.w400)),
                                Text('Destination: ${ride['destination']}', style: GoogleFonts.poppins(fontWeight: FontWeight.w400)),
                                Text('Time: ${ride['time']}', style: GoogleFonts.poppins(fontWeight: FontWeight.w400)),
                                Text(
                                  'Price per passenger: Rs. ${ride['pricePerPassenger']}',
                                  style: GoogleFonts.poppins(fontWeight: FontWeight.w500),
                                ),
                                const SizedBox(height: 25),
                                Text('Co-passengers:', style: GoogleFonts.poppins(fontWeight: FontWeight.bold)),
                                const SizedBox(height: 5),
                                Visibility(
                                  visible: _showInfoMessage,
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 15),
                                    margin: const EdgeInsets.only(bottom: 10),
                                    color: Colors.amber.withOpacity(0.2),
                                    child: Row(
                                      children: [
                                        const Icon(Icons.info, color: Colors.amber),
                                        const SizedBox(width: 5),
                                        Expanded(
                                          child: Text(
                                            'Tap on a co-passenger\'s profile picture to start a conversation.',
                                            style: GoogleFonts.poppins(fontWeight: FontWeight.w500, fontSize: 13),
                                          ),
                                        ),
                                        const SizedBox(width: 15),
                                      ],
                                    ),
                                  ),
                                ),
                                Wrap(
                                  spacing: 15,
                                  runSpacing: 15,
                                  alignment: WrapAlignment.start,
                                  children: ride['coPassengers'].map<Widget>((cp) {
                                    return GestureDetector(
                                      onTap: () => _openMessagePage(cp['phone']),
                                      child: Column(
                                        mainAxisSize: MainAxisSize.min,
                                        crossAxisAlignment: CrossAxisAlignment.center,
                                        children: [
                                          CircleAvatar(
                                            radius: 30,
                                            backgroundImage: NetworkImage(cp['profileImageUrl']),
                                          ),
                                          const SizedBox(height: 5),
                                          Text(
                                            cp['username'],
                                            style: GoogleFonts.poppins(fontSize: 12, fontWeight: FontWeight.w600),
                                          ),
                                        ],
                                      ),
                                    );
                                  }).toList(),
                                ),
                                if (isRideCancelled)
                                  Padding(
                                    padding: const EdgeInsets.only(top: 10),
                                    child: Text(
                                      'You have cancelled this ride!',
                                      style: GoogleFonts.poppins(color: Colors.red, fontWeight: FontWeight.w600),
                                    ),
                                  ),
                                if (isRideCompleted)
                                  Padding(
                                    padding: const EdgeInsets.only(top: 10),
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          'Ride completed',
                                          style: GoogleFonts.poppins(color: Colors.green, fontWeight: FontWeight.w600),
                                        ),
                                        const SizedBox(height: 10),
                                        ride['hasRated']
                                            ? Text(
                                          'Rating submitted',
                                          style: GoogleFonts.poppins(color: Colors.grey, fontWeight: FontWeight.w600),
                                        )
                                            : Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            ElevatedButton(
                                              onPressed: () {
                                                setState(() {
                                                  if (_expandedRatingRideIds.contains(ride['rideId'])) {
                                                    _expandedRatingRideIds.remove(ride['rideId']);
                                                  } else {
                                                    _expandedRatingRideIds.add(ride['rideId']);
                                                  }
                                                });
                                              },
                                              style: ElevatedButton.styleFrom(
                                                backgroundColor: Colors.blueAccent,
                                                shape: RoundedRectangleBorder(
                                                  borderRadius: BorderRadius.circular(12),
                                                ),
                                                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                                              ),
                                              child: Text(
                                                _expandedRatingRideIds.contains(ride['rideId'])
                                                    ? 'Hide Rating'
                                                    : 'Rate Driver',
                                                style: GoogleFonts.poppins(
                                                    fontSize: 14, fontWeight: FontWeight.w600, color: Colors.white),
                                              ),
                                            ),
                                            const SizedBox(height: 10),
                                            if (_expandedRatingRideIds.contains(ride['rideId']))
                                              _buildRateDriverSection(
                                                rideId: ride['rideId'],
                                                driverPhone: ride['driverPhone'],
                                                driverName: ride['driverUsername'],
                                              ),
                                          ],
                                        ),
                                      ],
                                    ),
                                  ),
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.end,
                                  children: [
                                    if (ride['showCancelButton'])
                                      ElevatedButton(
                                        onPressed: () => _cancelRide(ride['rideId']),
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: const Color(0xff154314),
                                          shape: RoundedRectangleBorder(
                                            borderRadius: BorderRadius.circular(12),
                                          ),
                                          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                                        ),
                                        child: Text(
                                          'Cancel Ride',
                                          style: GoogleFonts.poppins(fontSize: 14, fontWeight: FontWeight.w600, color: Colors.white),
                                        ),
                                      ),
                                    if (ride['showEndRideButton']) const SizedBox(width: 10),
                                    if (ride['showEndRideButton'])
                                      ElevatedButton(
                                        onPressed: () => _endRide(ride['rideId']),
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: Colors.blue,
                                          shape: RoundedRectangleBorder(
                                            borderRadius: BorderRadius.circular(12),
                                          ),
                                          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                                        ),
                                        child: Text(
                                          'End Ride',
                                          style: GoogleFonts.poppins(fontSize: 14, fontWeight: FontWeight.w600, color: Colors.white),
                                        ),
                                      ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  Future<void> _showDateRangePicker() async {
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

    if (picked != null) {
      final rides = await fetchJoinedRides();
      final total = _calculateTotalExpense(rides, picked.start, picked.end);

      showGeneralDialog(
        context: context,
        barrierDismissible: true,
        barrierLabel: MaterialLocalizations.of(context).modalBarrierDismissLabel,
        barrierColor: Colors.black54,
        transitionDuration: const Duration(milliseconds: 200),
        pageBuilder: (context, animation1, animation2) {
          return Center(
            child: Material(
              color: Colors.transparent,
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
                      "Total Expense",
                      style: GoogleFonts.poppins(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.black,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      "Rs. ${total.toStringAsFixed(2)} spent from ${DateFormat('yyyy-MM-dd').format(picked.start)} to ${DateFormat('yyyy-MM-dd').format(picked.end)}",
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
                        style: GoogleFonts.poppins(color: Colors.white, fontWeight: FontWeight.w600),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      );

    }
  }

  double _calculateTotalExpense(List<Map<String, dynamic>> rides, DateTime start, DateTime end) {
    double total = 0.0;

    for (var ride in rides) {
      try {
        DateTime rideDate = DateTime.parse(ride['startDate']);
        if (rideDate.isAfter(start.subtract(const Duration(days: 1))) &&
            rideDate.isBefore(end.add(const Duration(days: 1)))) {
          total += double.tryParse(ride['pricePerPassenger']) ?? 0.0;
        }
      } catch (_) {}
    }

    return total;
  }


  Widget _buildRateDriverSection({required String rideId, required String driverPhone, required String driverName}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Rate Driver:',
          style: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.black87),
        ),
        const SizedBox(height: 8),
        DriverRatingWidget(
          rideId: rideId,
          driverPhone: driverPhone,
          driverName: driverName,
        ),
      ],
    );
  }
}

class DriverRatingWidget extends StatefulWidget {
  final String rideId;
  final String driverPhone;
  final String driverName;

  const DriverRatingWidget({Key? key, required this.rideId, required this.driverPhone, required this.driverName}) : super(key: key);

  @override
  _DriverRatingWidgetState createState() => _DriverRatingWidgetState();
}

class _DriverRatingWidgetState extends State<DriverRatingWidget> {
  int currentRating = 0;
  bool isSubmitted = false;
  final TextEditingController _reviewController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _checkIfAlreadyRated();
  }

  Future<void> _checkIfAlreadyRated() async {
    DatabaseReference ratingRef = FirebaseDatabase.instance
        .ref()
        .child('ratings')
        .child(widget.driverPhone)
        .child(widget.rideId);
    DataSnapshot snapshot = await ratingRef.get();
    if (snapshot.exists) {
      setState(() {
        isSubmitted = true;
      });
    }
  }

  Future<void> submitRating() async {
    DatabaseReference ratingRef = FirebaseDatabase.instance
        .ref()
        .child('ratings')
        .child(widget.driverPhone)
        .child(widget.rideId);
    await ratingRef.set({
      'rating': currentRating,
      'review': _reviewController.text.trim(),
      'timestamp': DateTime.now().millisecondsSinceEpoch,
    });
    setState(() {
      isSubmitted = true;
    });
  }

  @override
  void dispose() {
    _reviewController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return isSubmitted
        ? Text("Rating submitted", style: TextStyle(color: Colors.green))
        : Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisSize: MainAxisSize.min,
          children: List.generate(5, (index) {
            return IconButton(
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(),
              icon: Icon(
                Icons.star,
                color: index < currentRating ? Colors.amber : Colors.grey,
                size: 20,
              ),
              onPressed: () {
                setState(() {
                  currentRating = index + 1;
                });
              },
            );
          }),
        ),
        Container(
          width: 200,
          child: TextField(
            controller: _reviewController,
            decoration: const InputDecoration(
              hintText: 'Enter review (optional)',
              contentPadding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              border: OutlineInputBorder(),
            ),
            style: GoogleFonts.poppins(fontSize: 12),
          ),
        ),
        const SizedBox(height: 4),
        ElevatedButton(
          onPressed: currentRating > 0 ? submitRating : null,
          child: Text("Submit", style: GoogleFonts.poppins(fontSize: 12)),
        )
      ],
    );
  }
}
