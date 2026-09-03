import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:hopin/inbox/inbox.dart';
import 'package:hopin/user_home/account_settings.dart';
import 'package:hopin/user_home/post_ride_selection.dart';
import 'package:hopin/user_home/home_page.dart';
import 'package:hopin/my_rides/myrides.dart';

import '../user_home/user_profile.dart'; // ✅ ADDED THIS

class RidePassengersScreen extends StatefulWidget {
  final String rideId;
  final String phoneNumber; // ✅ ADDED THIS

  const RidePassengersScreen({
    Key? key,
    required this.rideId,
    required this.phoneNumber, // ✅ ADDED THIS
  }) : super(key: key);

  @override
  State<RidePassengersScreen> createState() => _RidePassengersScreenState();
}

class _RidePassengersScreenState extends State<RidePassengersScreen> {
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
    } catch (e) {
      return phone;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xffefe5dc),
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
      appBar: AppBar(
        iconTheme: const IconThemeData(color: Colors.white),
        title: Text(
          'Ride Passengers',
          style: GoogleFonts.poppins(
            fontSize: 20,
            fontWeight: FontWeight.w600,
            color: Colors.white,
          ),
        ),
        backgroundColor: const Color(0xff154314),
        elevation: 0,
      ),
      body: FutureBuilder<DataSnapshot>(
        future: database.ref().child('passenger_per_ride').child(widget.rideId).get(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator(color: Color(0xff15431)));
          }

          if (snapshot.hasError) {
            return Center(
              child: Text(
                'Error: ${snapshot.error}',
                style: GoogleFonts.poppins(fontSize: 14, fontWeight: FontWeight.w400),
              ),
            );
          }

          final passengersData = snapshot.data!.value;

          if (passengersData == null) {
            return Center(
              child: Text(
                'No passengers found for this ride.',
                style: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.w500),
              ),
            );
          }

          final passengers = (passengersData as Map<dynamic, dynamic>).values.toList();

          return ListView.builder(
            itemCount: passengers.length,
            itemBuilder: (context, index) {
              final passenger = passengers[index] as Map<dynamic, dynamic>;
              final passengerPhone = passenger['passenger_phone'] ?? '';
              final pickupAddress = passenger['pickup_address'] ?? '';
              final destinationAddress = passenger['destination_address'] ?? '';

              return FutureBuilder<String>(
                future: getUsernameByPhone(passengerPhone),
                builder: (context, userSnapshot) {
                  final passengerName = userSnapshot.data ?? passengerPhone;

                  return FutureBuilder<DataSnapshot>(
                    future: database
                        .ref()
                        .child('passenger_ride_status')
                        .child(widget.rideId)
                        .child(passengerPhone)
                        .get(),
                    builder: (context, statusSnapshot) {
                      String status = statusSnapshot.data?.value?.toString() ?? '';

                      return Card(
                        color: Colors.white,
                        margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                        elevation: 4,
                        child: Padding(
                          padding: const EdgeInsets.all(12.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  const Icon(Icons.person, color: Color(0xff154314), size: 28),
                                  const SizedBox(width: 10),
                                  Text(
                                    passengerName,
                                    style: GoogleFonts.poppins(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w600,
                                      color: Colors.black,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8),
                              Text(
                                'Pickup: $pickupAddress',
                                style: GoogleFonts.poppins(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w400,
                                  color: Colors.black87,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'Destination: $destinationAddress',
                                style: GoogleFonts.poppins(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w400,
                                  color: Colors.black87,
                                ),
                              ),
                              const SizedBox(height: 12),
                              if (status != 'Picked Up')
                                Align(
                                  alignment: Alignment.centerRight,
                                  child: ElevatedButton(
                                    onPressed: () {
                                      markPassengerAsPickedUp(passengerPhone);
                                    },
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: const Color(0xffe15431),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(10),
                                      ),
                                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                                    ),
                                    child: Text(
                                      'Pick Up',
                                      style: GoogleFonts.poppins(
                                        fontSize: 14,
                                        fontWeight: FontWeight.w500,
                                        color: Colors.white,
                                      ),
                                    ),
                                  ),
                                )
                              else
                                Align(
                                  alignment: Alignment.centerRight,
                                  child: Text(
                                    'Picked Up',
                                    style: GoogleFonts.poppins(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w600,
                                      color: Colors.green,
                                    ),
                                  ),
                                )
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
      ),
    );
  }
}
