import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:geocoding/geocoding.dart';
import 'package:hopin/user_home/home_page.dart';
import 'package:hopin/inapp_communication/new_conversation.dart';
import 'package:hopin/inbox/inbox.dart';
import 'package:hopin/user_home/account_settings.dart';
import 'package:hopin/user_home/post_ride_selection.dart';
import 'package:hopin/user_home/home_page.dart';

import '../my_rides/myrides.dart';
import '../user_home/user_profile.dart';

class ResultPage extends StatefulWidget {
  final Map<String, dynamic> ride;
  final String currentUserPhone;
  final String rideId;

  const ResultPage({
    Key? key,
    required this.ride,
    required this.currentUserPhone,
    required this.rideId,
  }) : super(key: key);

  @override
  _ResultPageState createState() => _ResultPageState();
}

class _ResultPageState extends State<ResultPage> {
  Map<String, dynamic> driverDetails = {};
  String pickupAddressName = '';
  late TextEditingController pickupController;
  late TextEditingController destinationController;

  @override
  void initState() {
    super.initState();
    pickupController = TextEditingController();
    destinationController = TextEditingController(
      text: widget.ride['destinationAddress'] ?? '',
    );
    fetchDriverDetails();
    getPickupAddress();
  }

  Future<void> fetchDriverDetails() async {
    String phoneNumber = widget.ride['phoneNumber'] ?? '';
    if (phoneNumber.isEmpty) return;

    DatabaseReference usersRef = FirebaseDatabase.instance.ref("Users");
    DatabaseEvent event = await usersRef.orderByChild("phone").equalTo(phoneNumber).once();

    if (event.snapshot.value != null) {
      Map<String, dynamic> users = Map<String, dynamic>.from(event.snapshot.value as Map);
      String driverKey = users.keys.first;
      setState(() {
        driverDetails = Map<String, dynamic>.from(users[driverKey]);
      });
    }
  }

  Future<void> getPickupAddress() async {
    double lat = widget.ride['pickupLatitude'];
    double lon = widget.ride['pickupLongitude'];

    List<Placemark> placemarks = await placemarkFromCoordinates(lat, lon);
    if (placemarks.isNotEmpty) {
      setState(() {
        pickupAddressName = '${placemarks.first.locality}, ${placemarks.first.street}';
        pickupController.text = pickupAddressName;
      });
    }
  }

  Future<void> handleRequestRide() async {
    String driverPhone = driverDetails['phone'] ?? '';
    String requestDate = DateTime.now().toString();

    String finalPickup = pickupController.text.trim();
    String finalDestination = destinationController.text.trim();

    DatabaseReference rideRequestRef = FirebaseDatabase.instance.ref('ride_request_notifications').push();

    await rideRequestRef.set({
      'ride_id': widget.rideId,
      'requested_rider_phone': widget.currentUserPhone,
      'driver_phone': driverPhone,
      'pickup_address_name': finalPickup,
      'destination_address_name': finalDestination,
      'ride_request_notifications': 'Pending',
      'request_date': requestDate,
    });

    // ✅ Notification is now triggered by Cloud Function when this data is written
    print('✅ Ride request saved. Notification will be sent by Cloud Function.');

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Request successfully sent')),
    );

    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (context) => HomePage(phoneNumber: widget.currentUserPhone),
      ),
    );
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
                  builder: (context) => HomePage(phoneNumber: widget.currentUserPhone),
                ),
              );
            }
            else if (index == 1) {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => PostRideSelectionPage(phoneNumber: widget.currentUserPhone),
                ),
              );
            } else if (index == 2) {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => MyRidesPage(phoneNumber: widget.currentUserPhone),
                ),
              );
            } else if (index == 3) {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => InboxPage(phoneNumber: widget.currentUserPhone),
                ),
              );
            } else if (index == 4) {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => UserProfileViewPage(phoneNumber: widget.currentUserPhone),
                ),
              );
            }
          },
        ),
      appBar: AppBar(
        backgroundColor: const Color(0xffe154314),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Ride Details',
          style: GoogleFonts.poppins(
            color: Colors.white,
            fontWeight: FontWeight.w600,
            fontSize: 20,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.message, color: Colors.white),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => MessagePage(
                    currentUserPhone: widget.currentUserPhone,
                    driverPhone: widget.ride['phoneNumber'] ?? 'N/A',
                  ),
                ),
              );
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Center(
              child: CircleAvatar(
                radius: 55,
                backgroundImage: (driverDetails['profileImageUrl'] != null &&
                    driverDetails['profileImageUrl'].isNotEmpty)
                    ? NetworkImage(driverDetails['profileImageUrl'])
                    : const AssetImage('assets/images/user.png') as ImageProvider,
              ),
            ),
            const SizedBox(height: 35),
            buildInfoCard(
              title: 'Driver Information',
              children: [
                infoText('👤 Name: ${driverDetails['username'] ?? 'Unknown'}'),
                infoText('Phone: ${widget.ride['phoneNumber'] ?? 'N/A'}'),
                infoText('Email: ${driverDetails['email'] ?? 'N/A'}'),
                infoText('Age: ${driverDetails['age'] ?? 'N/A'}'),
              ],
            ),
            const SizedBox(height: 35),
            buildInfoCard(
              title: 'Ride Details',
              children: [
                textField(pickupController, 'Pickup Location'),
                const SizedBox(height: 28),
                textField(destinationController, 'Destination Location'),
                const SizedBox(height: 15),
                infoText('Time: ${widget.ride['selectedTime'] ?? 'N/A'}'),
                infoText('Date: ${widget.ride['startDate'] ?? 'N/A'}'),
              ],
            ),
            const SizedBox(height: 30),
            Center(
              child: ElevatedButton(
                onPressed: handleRequestRide,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xffe154314),
                  padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: Text(
                  'Request Ride',
                  style: GoogleFonts.poppins(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget buildInfoCard({required String title, required List<Widget> children}) {
    return Container(
      padding: const EdgeInsets.all(16.0),
      decoration: BoxDecoration(
        color: Colors.white70,
        borderRadius: BorderRadius.circular(10),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.2),
            spreadRadius: 2,
            blurRadius: 5,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.w600)),
          const SizedBox(height: 12),
          ...children,
        ],
      ),
    );
  }

  Widget infoText(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6.0),
      child: Text(text, style: GoogleFonts.poppins()),
    );
  }

  Widget textField(TextEditingController controller, String label) {
    return TextFormField(
      controller: controller,
      decoration: InputDecoration(
        labelText: label,
        border: const OutlineInputBorder(),
      ),
      style: GoogleFonts.poppins(),
    );
  }
}
