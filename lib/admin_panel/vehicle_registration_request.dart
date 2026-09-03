import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:hopin/admin_panel/admin_home.dart';
import 'package:hopin/admin_panel/admin_chat_support.dart';
import 'package:hopin/admin_panel/admin_review_and_rating.dart';

class AdminRequests extends StatefulWidget {
  final String adminPhoneNumber;
  const AdminRequests({Key? key, required this.adminPhoneNumber}) : super(key: key);

  @override
  _AdminRequestsState createState() => _AdminRequestsState();
}

class _AdminRequestsState extends State<AdminRequests> {
  final dbRef = FirebaseDatabase.instance.ref().child('Vehicle_requests');

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        bool isLargeScreen = constraints.maxWidth >= 800;
        return Scaffold(
          backgroundColor: const Color(0xffefe5dc),
          appBar: AppBar(
            backgroundColor: const Color(0xff154314),
            leading: IconButton(
              icon: Icon(Icons.arrow_back),
              color: Colors.white,
              onPressed: () {
                Navigator.pop(context);
              },
            ),
            title: GestureDetector(
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => AdminRequests(adminPhoneNumber: widget.adminPhoneNumber),
                  ),
                );
              },
              child: Text(
                'Vehicle Registration Requests',
                style: GoogleFonts.poppins(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
          drawer: isLargeScreen ? null : buildDrawer(context),
          body: Row(
            children: [
              if (isLargeScreen)
                Container(
                  width: 250,
                  color: const Color(0xffefe5dc),
                  child: Column(
                    children: [
                      Expanded(child: buildDrawer(context)),
                      VerticalDivider(color: Colors.grey, thickness: 1, width: 1),
                    ],
                  ),
                ),
              VerticalDivider(color: Colors.grey, thickness: 1, width: 1),
              Expanded(
                child: StreamBuilder(
                  stream: dbRef.onValue,
                  builder: (context, snapshot) {
                    if (snapshot.hasData &&
                        snapshot.data != null &&
                        (snapshot.data! as DatabaseEvent).snapshot.value != null) {
                      Map<dynamic, dynamic> values = (snapshot.data! as DatabaseEvent).snapshot.value as Map<dynamic, dynamic>;
                      return ListView.builder(
                        itemCount: values.length,
                        itemBuilder: (context, index) {
                          String key = values.keys.elementAt(index);
                          Map<dynamic, dynamic> request = values[key];

                          return FutureBuilder<DataSnapshot>(
                            future: FirebaseDatabase.instance
                                .ref()
                                .child('Users')
                                .orderByChild('phone')
                                .equalTo(request['phoneNumber'])
                                .get(),
                            builder: (context, userSnapshot) {
                              if (userSnapshot.connectionState == ConnectionState.waiting) {
                                return const Center(child: CircularProgressIndicator());
                              } else if (userSnapshot.hasData && userSnapshot.data!.value != null) {
                                Map<dynamic, dynamic> usersMap = userSnapshot.data!.value as Map<dynamic, dynamic>;
                                String username = usersMap.values.first['username'] ?? 'Unknown';

                                return Card(
                                  margin: const EdgeInsets.all(8.0),
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                                  child: ListTile(
                                    title: Text(
                                      '$username | ${request['phoneNumber']} | ${request['vehicleName']}',
                                      style: const TextStyle(fontFamily: 'Poppins'),
                                    ),
                                    subtitle: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          'Plate: ${request['vehicleNumber']} | Date: ${(request['request_date'] ?? 'N/A').toString().split(' ').first}',
                                          style: const TextStyle(fontFamily: 'Poppins'),
                                        ),
                                        Row(
                                          children: [
                                            TextButton(
                                              onPressed: () {
                                                _launchURL(request['driverLicenseUrl']);
                                              },
                                              child: const Text(
                                                'Driver License',
                                                style: TextStyle(fontFamily: 'Poppins', color: Colors.blue),
                                              ),
                                            ),
                                            const SizedBox(width: 10),
                                            TextButton(
                                              onPressed: () {
                                                _launchURL(request['vehicleLicenseUrl']);
                                              },
                                              child: const Text(
                                                'Vehicle License',
                                                style: TextStyle(fontFamily: 'Poppins', color: Colors.blue),
                                              ),
                                            ),
                                          ],
                                        ),
                                        if (request['status'] == 'declined')
                                          Row(
                                            mainAxisAlignment: MainAxisAlignment.end,
                                            children: [
                                              const Text(
                                                'This request has been declined',
                                                style: TextStyle(
                                                  fontFamily: 'Poppins',
                                                  color: Colors.red,
                                                  fontSize: 12,
                                                  fontStyle: FontStyle.italic,
                                                ),
                                              ),
                                            ],
                                          ),
                                        if (request['status'] == 'accepted')
                                          Row(
                                            mainAxisAlignment: MainAxisAlignment.end,
                                            children: [
                                              const Text(
                                                'This request has been accepted',
                                                style: TextStyle(
                                                  fontFamily: 'Poppins',
                                                  color: Colors.green,
                                                  fontSize: 12,
                                                  fontStyle: FontStyle.italic,
                                                ),
                                              ),
                                            ],
                                          ),
                                      ],
                                    ),
                                    trailing: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        ElevatedButton(
                                          onPressed: request['status'] == 'declined' || request['status'] == 'accepted'
                                              ? null
                                              : () => acceptRequest(key, request),
                                          style: ElevatedButton.styleFrom(backgroundColor: const Color(0xffe15431)),
                                          child: const Text('Accept', style: TextStyle(fontFamily: 'Poppins', color: Colors.white, fontWeight: FontWeight.w500)),
                                        ),
                                        const SizedBox(width: 8),
                                        ElevatedButton(
                                          onPressed: request['status'] == 'declined' || request['status'] == 'accepted'
                                              ? null
                                              : () => declineRequest(key, request),
                                          style: ElevatedButton.styleFrom(backgroundColor: Colors.grey),
                                          child: const Text('Decline', style: TextStyle(fontFamily: 'Poppins', color: Colors.white, fontWeight: FontWeight.w500)),
                                        ),
                                      ],
                                    ),
                                  ),
                                );
                              } else {
                                return const SizedBox();
                              }
                            },
                          );
                        },
                      );
                    }
                    return const Center(child: CircularProgressIndicator());
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget buildDrawer(BuildContext context) {
    return Column(
      children: [
        ListTile(
          leading: const Icon(Icons.dashboard, color: Color(0xff154314)),
          title: const Text('Dashboard', style: TextStyle(fontFamily: 'Poppins')),
          onTap: () {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(
                builder: (context) => AdminDashboard(adminPhoneNumber: widget.adminPhoneNumber),
              ),
            );
          },
        ),
        const Divider(),
        ListTile(
          leading: const Icon(Icons.directions_car, color: Color(0xff154314)),
          title: const Text('Vehicle Requests', style: TextStyle(fontFamily: 'Poppins')),
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => AdminRequests(adminPhoneNumber: widget.adminPhoneNumber),
              ),
            );
          },
        ),
        const Divider(),
        ListTile(
          leading: const Icon(Icons.map, color: Color(0xff154314)),
          title: const Text('Moitor Reviews', style: TextStyle(fontFamily: 'Poppins')),
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => AdminReviewsPage(adminPhoneNumber: widget.adminPhoneNumber),
              ),
            );
          },
        ),
        const Divider(),
        ListTile(
          leading: const Icon(Icons.people, color: Color(0xff154314)),
          title: const Text('User Details', style: TextStyle(fontFamily: 'Poppins')),
        ),
        const Divider(),
        ListTile(
          leading: const Icon(Icons.chat, color: Color(0xff154314)),
          title: const Text('Support Chats', style: TextStyle(fontFamily: 'Poppins')),
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => AdminChatPage(adminPhoneNumber: widget.adminPhoneNumber),
              ),
            );
          },
        ),
        const Divider(),
      ],
    );
  }

  void acceptRequest(String key, Map<dynamic, dynamic> request) async {
    DatabaseReference vehiclesRef = FirebaseDatabase.instance.ref().child('Vehicles');
    DatabaseReference notificationsRef = FirebaseDatabase.instance.ref().child('vehicle_requests_notification');

    await vehiclesRef.child(key).set({
      'driverLicenseUrl': request['driverLicenseUrl'],
      'phoneNumber': request['phoneNumber'],
      'vehicleLicenseUrl': request['vehicleLicenseUrl'],
      'vehicleName': request['vehicleName'],
      'vehicleNumber': request['vehicleNumber'],
      'vehicleType': request['vehicleType'],
    });

    await dbRef.child(key).update({'status': 'accepted'});

    await notificationsRef.push().set({
      'phone': request['phoneNumber'],
      'status': 'accepted',
      'message':
      'Your vehicle registration request for ${request['vehicleNumber']} has been accepted by admin (${widget.adminPhoneNumber})',
    });
  }

  void declineRequest(String key, Map<dynamic, dynamic> request) async {
    await dbRef.child(key).update({'status': 'declined'});

    DatabaseReference notificationsRef = FirebaseDatabase.instance.ref().child('vehicle_requests_notification');

    await notificationsRef.push().set({
      'phone': request['phoneNumber'],
      'status': 'declined',
      'message':
      'Your vehicle registration request for vehicle number ${request['vehicleNumber']} has been declined by admin (${widget.adminPhoneNumber}).',
    });
  }

  void _launchURL(String url) async {
    if (await canLaunch(url)) {
      await launch(url);
    } else {
      throw 'Could not launch $url';
    }
  }
}
