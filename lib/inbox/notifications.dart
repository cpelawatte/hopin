import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:hopin/post_ride/rider_profile_view.dart';
import 'package:intl/intl.dart';
import 'package:hopin/inbox/inbox.dart';
import 'package:hopin/user_home/account_settings.dart';
import 'package:hopin/user_home/post_ride_selection.dart';
import 'package:hopin/user_home/home_page.dart';

import '../my_rides/myrides.dart';
import '../user_home/user_profile.dart';

class NotificationsTab extends StatefulWidget {
  final String phoneNumber;

  NotificationsTab({required this.phoneNumber});

  @override
  _NotificationsTabState createState() => _NotificationsTabState();
}

class _NotificationsTabState extends State<NotificationsTab> {
  late DatabaseReference rideRequestRef;

  @override
  void initState() {
    super.initState();
    rideRequestRef = FirebaseDatabase.instance.ref('ride_request_notifications');
  }

  // Function to accept the ride request (without reducing seats)
  void _acceptRequest(String rideRequestId, String rideId, String requestedRiderPhone, String pickupAddress, String destinationAddress) async {
    // Add rider to the passenger list with pickup and destination addresses
    DatabaseReference passengerRef = FirebaseDatabase.instance.ref('passenger_per_ride/$rideId');
    passengerRef.push().set({
      'passenger_phone': requestedRiderPhone,
      'pickup_address': pickupAddress,
      'destination_address': destinationAddress,
    });

    // Delete the notification from ride_request_notifications node
    rideRequestRef.child(rideRequestId).remove();

    // Save the accepted notification in the "notifications" node
    DatabaseReference notificationsRef = FirebaseDatabase.instance.ref('notifications');
    notificationsRef.push().set({
      'ride_id': rideId,
      'requested_rider_phone': requestedRiderPhone,
      'status': 'accepted',
      'pickup_address': pickupAddress,
      'destination_address': destinationAddress,
      'notification_date': DateTime.now().toString(),
    });
  }

  // Function to decline the ride request
  void _declineRequest(String rideRequestId, String requestedRiderPhone, String rideId, String pickupAddress, String destinationAddress) async {
    // Simply remove the notification if declined
    rideRequestRef.child(rideRequestId).remove();

    // Save the declined notification in the "notifications" node
    DatabaseReference notificationsRef = FirebaseDatabase.instance.ref('notifications');
    notificationsRef.push().set({
      'ride_id': rideId,
      'requested_rider_phone': requestedRiderPhone,
      'status': 'declined',
      'pickup_address': pickupAddress,
      'destination_address': destinationAddress,
      'notification_date': DateTime.now().toString(),
    });
  }

  // Function to fetch user profile data (name and image) by phone number
  Future<Map<String, dynamic>> _fetchUserProfile(String phoneNumber) async {
    DatabaseReference userRef = FirebaseDatabase.instance.ref('Users');
    DataSnapshot snapshot = await userRef.orderByChild('phone').equalTo(phoneNumber).get();

    if (snapshot.exists) {
      var userData = snapshot.children.first.value as Map<dynamic, dynamic>;
      return {
        'username': userData['username'] ?? 'Unknown',
        'profileImageUrl': userData['profileImageUrl'] ?? '',
        'disability': userData['disability'] ?? '',
        'assistenceRequired': userData['assistenceRequired'] ?? false,
      };
    } else {
      return {
        'username': 'Unknown',
        'profileImageUrl': '',
        'disability': '',
        'assistenceRequired': false,
      };
    }
  }


  String _formatDate(String dateString) {
    try {
      DateTime date = DateTime.parse(dateString);
      return DateFormat('yyyy-MM-dd').format(date); // Format as "2025-03-22"
    } catch (e) {
      return dateString; // Return the original string if it's not a valid date
    }
  }

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
      body: StreamBuilder(
        stream: rideRequestRef.onValue,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }

          if (!snapshot.hasData || snapshot.data!.snapshot.value == null) {
            return const Center(child: Text("No notifications available."));
          }

          // Handle dynamic type issue here by explicitly casting the snapshot data
          Map<String, dynamic> notifications = Map<String, dynamic>.from(snapshot.data!.snapshot.value as Map);

          // Filter notifications to show only those matching the rider_phone
          Map<String, dynamic> filteredNotifications = {};
          notifications.forEach((key, value) {
            if (value['driver_phone'] == widget.phoneNumber) {
              filteredNotifications[key] = value;
            }
          });

          return ListView.builder(
            itemCount: filteredNotifications.length,
            itemBuilder: (context, index) {
              String rideRequestId = filteredNotifications.keys.elementAt(index);
              var notification = filteredNotifications[rideRequestId];

              String requestedRiderPhone = notification['requested_rider_phone'] ?? '';
              String rideId = notification['ride_id'] ?? '';
              String requestDate = notification['request_date'] ?? '';
              String pickupAddress = notification['pickup_address_name'] ?? '';
              String destinationAddress = notification['destination_address_name'] ?? '';

              return FutureBuilder<Map<String, dynamic>>(
              future: _fetchUserProfile(requestedRiderPhone),
                builder: (context, userSnapshot) {
                  if (userSnapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  if (!userSnapshot.hasData) {
                    return const Center(child: Text("User not found"));
                  }

                  var userProfile = userSnapshot.data!;
                  String username = userProfile['username'] ?? 'Unknown';
                  String profileImageUrl = userProfile['profileImageUrl'] ?? '';

                  return GestureDetector(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => UpdateProfilePage(phoneNumber: requestedRiderPhone),
                        ),
                      );
                    },
                    child: Stack(
                      children: [
                        Card(
                          margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          color: const Color(0xffefe5dc),
                          child: Padding(
                            padding: const EdgeInsets.all(8),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    CircleAvatar(
                                      backgroundImage: profileImageUrl.isNotEmpty
                                          ? NetworkImage(profileImageUrl)
                                          : AssetImage('assets/images/user.png') as ImageProvider,
                                    ),
                                    const SizedBox(width: 8),
                                    Text(
                                      username,
                                      style: GoogleFonts.poppins(
                                        fontWeight: FontWeight.w600,
                                        color: const Color(0xffe154314),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  'Request Date: ${_formatDate(requestDate)}',
                                  style: GoogleFonts.poppins(
                                    fontWeight: FontWeight.w400,
                                    color: Colors.black,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  'Pickup: $pickupAddress',
                                  style: GoogleFonts.poppins(
                                    fontWeight: FontWeight.w400,
                                    color: Colors.black,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  'Destination: $destinationAddress',
                                  style: GoogleFonts.poppins(
                                    fontWeight: FontWeight.w400,
                                    color: Colors.black,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    ElevatedButton(
                                      onPressed: () {
                                        _acceptRequest(rideRequestId, rideId, requestedRiderPhone, pickupAddress, destinationAddress);
                                      },
                                      style: ElevatedButton.styleFrom(backgroundColor: const Color(0xffe154314)),
                                      child: Text('Accept', style: GoogleFonts.poppins(fontWeight: FontWeight.w600, color: Colors.white)),
                                    ),
                                    ElevatedButton(
                                      onPressed: () {
                                        _declineRequest(rideRequestId, requestedRiderPhone, rideId, pickupAddress, destinationAddress);
                                      },
                                      style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                                      child: Text('Decline', style: GoogleFonts.poppins(fontWeight: FontWeight.w600, color: Colors.white)),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ),

                        // 🔷 Disability Label
                        if (userProfile['disability'] != null && userProfile['disability'].toString().isNotEmpty)
                          Positioned(
                            top: 10,
                            right: 30,
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: Colors.blue,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                userProfile['disability'],
                                style: GoogleFonts.poppins(
                                    fontSize: 10, fontWeight: FontWeight.bold, color: Colors.white),
                              ),
                            ),
                          ),

                      ],
                    ),
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
