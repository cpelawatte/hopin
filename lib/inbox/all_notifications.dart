// import 'package:flutter/material.dart';
// import 'package:firebase_database/firebase_database.dart';
// import 'package:intl/intl.dart';
//
// class NotificationsViewTab extends StatefulWidget {
//   final String phoneNumber;
//   const NotificationsViewTab({Key? key, required this.phoneNumber}) : super(key: key);
//
//   @override
//   _NotificationsViewTabState createState() => _NotificationsViewTabState();
// }
//
// class _NotificationsViewTabState extends State<NotificationsViewTab> {
//   final DatabaseReference _dbRef = FirebaseDatabase.instance.ref();
//
//   Future<String> _fetchUsername(String phoneNumber) async {
//     final snapshot = await _dbRef.child('Users').orderByChild('phone').equalTo(phoneNumber).get();
//     if (snapshot.exists && snapshot.value is Map) {
//       Map userMap = snapshot.value as Map;
//       return userMap.values.first['username'] ?? 'Unknown';
//     }
//     return 'Unknown';
//   }
//
//   String _formatDate(String dateString) {
//     DateTime dateTime = DateTime.parse(dateString);
//     return DateFormat('yyyy-MM-dd').format(dateTime);
//   }
//
//   Future<void> _markAsRead(String notificationId) async {
//     await _dbRef.child('notifications/$notificationId').update({'isRead': true});
//   }
//
//   Color _getStatusColor(String status) {
//     if (status.toLowerCase().contains('cancelled')) {
//       return Colors.red;
//     } else if (status.toLowerCase().contains('started')) {
//       return Colors.green;
//     }
//     return Colors.black; // Default color for other statuses
//   }
//
//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       body: StreamBuilder(
//         stream: _dbRef.child('notifications').orderByChild('requested_rider_phone').equalTo(widget.phoneNumber).onValue,
//         builder: (context, AsyncSnapshot<DatabaseEvent> snapshot) {
//           if (snapshot.connectionState == ConnectionState.waiting) {
//             return Center(child: CircularProgressIndicator());
//           }
//           if (!snapshot.hasData || snapshot.data!.snapshot.value == null) {
//             return Center(child: Text('No notifications available.'));
//           }
//
//           Map<dynamic, dynamic> notificationsMap = snapshot.data!.snapshot.value as Map;
//           List<Map<String, dynamic>> notifications = notificationsMap.entries.map((entry) {
//             Map<String, dynamic> data = Map<String, dynamic>.from(entry.value);
//             data['id'] = entry.key; // Store notification ID
//             return data;
//           }).toList();
//
//           // Sort notifications by date in descending order
//           notifications.sort((a, b) {
//             DateTime dateA = DateTime.parse(a['notification_date']);
//             DateTime dateB = DateTime.parse(b['notification_date']);
//             return dateB.compareTo(dateA); // Latest notifications first
//           });
//
//           return ListView.builder(
//             itemCount: notifications.length,
//             itemBuilder: (context, index) {
//               var notification = notifications[index];
//
//               return FutureBuilder(
//                 future: _fetchUsername(notification['requested_rider_phone']),
//                 builder: (context, AsyncSnapshot<String> usernameSnapshot) {
//                   if (!usernameSnapshot.hasData) {
//                     return ListTile(title: Text('Loading...'));
//                   }
//
//                   String username = usernameSnapshot.data!;
//                   String formattedDate = _formatDate(notification['notification_date']);
//                   String message = "Dear $username, the ride you requested on $formattedDate to go from ${notification['pickup_address']} to ${notification['destination_address']} has been ${notification['status']}!";
//
//                   // Using Text.rich to format bold parts of the message
//                   return Card(
//                     color: notification['isRead'] ?? false ? Colors.grey[300] : Color(0xFFE4D9CD),
//                     margin: EdgeInsets.all(8),
//                     child: Padding(
//                       padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
//                       child: Row(
//                         crossAxisAlignment: CrossAxisAlignment.center, // Center the row contents vertically
//                         children: [
//                           Icon(Icons.notifications, color: notification['isRead'] ?? false ? Colors.grey : Color(0xffe154314)),
//                           SizedBox(width: 10),
//                           Expanded(
//                             child: Text.rich(
//                               TextSpan(
//                                 children: [
//                                   TextSpan(
//                                     text: "Dear ",
//                                     style: TextStyle(fontWeight: FontWeight.normal), // Normal text
//                                   ),
//                                   TextSpan(
//                                     text: username,
//                                     style: TextStyle(fontWeight: FontWeight.bold), // Bold username
//                                   ),
//                                   TextSpan(
//                                     text: ", the ride you requested on ",
//                                     style: TextStyle(fontWeight: FontWeight.normal), // Normal text
//                                   ),
//                                   TextSpan(
//                                     text: formattedDate,
//                                     style: TextStyle(fontWeight: FontWeight.bold), // Bold date
//                                   ),
//                                   TextSpan(
//                                     text: " to go from ",
//                                     style: TextStyle(fontWeight: FontWeight.normal), // Normal text
//                                   ),
//                                   TextSpan(
//                                     text: notification['pickup_address'],
//                                     style: TextStyle(fontWeight: FontWeight.bold), // Bold pickup address
//                                   ),
//                                   TextSpan(
//                                     text: " to ",
//                                     style: TextStyle(fontWeight: FontWeight.normal), // Normal text
//                                   ),
//                                   TextSpan(
//                                     text: notification['destination_address'],
//                                     style: TextStyle(fontWeight: FontWeight.bold), // Bold destination address
//                                   ),
//                                   TextSpan(
//                                     text: " has been ",
//                                     style: TextStyle(fontWeight: FontWeight.normal), // Normal text
//                                   ),
//                                   TextSpan(
//                                     text: notification['status'],
//                                     style: TextStyle(
//                                       fontWeight: FontWeight.bold, // Bold status
//                                       color: _getStatusColor(notification['status']), // Set the status font color
//                                     ),
//                                   ),
//                                   TextSpan(
//                                     text: "!",
//                                     style: TextStyle(fontWeight: FontWeight.normal), // Normal text
//                                   ),
//                                 ],
//                               ),
//                             ),
//                           ),
//                           if (!(notification['isRead'] ?? false))
//                             InkWell(
//                               onTap: () => _markAsRead(notification['id']),
//                               child: Padding(
//                                 padding: const EdgeInsets.only(left: 10, top: 5),
//                                 child: Text(
//                                   "Mark as Read",
//                                   style: TextStyle(fontSize: 12, color: Colors.blue),
//                                 ),
//                               ),
//                             ),
//                         ],
//                       ),
//                     ),
//                   );
//                 },
//               );
//             },
//           );
//         },
//       ),
//     );
//   }
// }

import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:intl/intl.dart';
import 'package:hopin/inbox/inbox.dart';
import 'package:hopin/user_home/account_settings.dart';
import 'package:hopin/user_home/post_ride_selection.dart';
import 'package:hopin/user_home/home_page.dart';

import '../my_rides/myrides.dart';
import '../user_home/user_profile.dart';

class NotificationsViewTab extends StatefulWidget {
  final String phoneNumber;
  const NotificationsViewTab({Key? key, required this.phoneNumber}) : super(key: key);

  @override
  _NotificationsViewTabState createState() => _NotificationsViewTabState();
}

class _NotificationsViewTabState extends State<NotificationsViewTab> {
  final DatabaseReference _dbRef = FirebaseDatabase.instance.ref();

  Future<String> _fetchUsername(String phoneNumber) async {
    final snapshot = await _dbRef.child('Users').orderByChild('phone').equalTo(phoneNumber).get();
    if (snapshot.exists && snapshot.value is Map) {
      Map userMap = snapshot.value as Map;
      return userMap.values.first['username'] ?? 'Unknown';
    }
    return 'Unknown';
  }

  String _formatDate(String dateString) {
    DateTime dateTime = DateTime.parse(dateString);
    return DateFormat('yyyy-MM-dd').format(dateTime);
  }

  Future<void> _markAsRead(String notificationId) async {
    await _dbRef.child('notifications/$notificationId').update({'isRead': true});
  }

  Color _getStatusColor(String status) {
    if (status.toLowerCase().contains('cancelled')) {
      return Colors.red;
    } else if (status.toLowerCase().contains('started')) {
      return Colors.green;
    }
    return Colors.black; // Default color for other statuses
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
      body: StreamBuilder(
        stream: _dbRef.child('notifications').orderByChild('requested_rider_phone').equalTo(widget.phoneNumber).onValue,
        builder: (context, AsyncSnapshot<DatabaseEvent> snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          }
          if (!snapshot.hasData || snapshot.data!.snapshot.value == null) {
            return Center(child: Text('No notifications available.'));
          }

          Map<dynamic, dynamic> notificationsMap = snapshot.data!.snapshot.value as Map;
          List<Map<String, dynamic>> notifications = notificationsMap.entries.map((entry) {
            Map<String, dynamic> data = Map<String, dynamic>.from(entry.value);
            data['id'] = entry.key; // Store notification ID
            return data;
          }).toList();

          // Sort notifications by date in descending order
          notifications.sort((a, b) {
            DateTime dateA = DateTime.parse(a['notification_date']);
            DateTime dateB = DateTime.parse(b['notification_date']);
            return dateB.compareTo(dateA); // Latest notifications first
          });

          return ListView.builder(
            itemCount: notifications.length,
            itemBuilder: (context, index) {
              var notification = notifications[index];

              return FutureBuilder(
                future: _fetchUsername(notification['requested_rider_phone']),
                builder: (context, AsyncSnapshot<String> usernameSnapshot) {
                  if (!usernameSnapshot.hasData) {
                    return ListTile(title: Text('Loading...'));
                  }

                  String username = usernameSnapshot.data!;
                  String formattedDate = _formatDate(notification['notification_date']);
                  String message = "Dear $username, the ride you requested on $formattedDate to go from ${notification['pickup_address']} to ${notification['destination_address']} has been ${notification['status']}!";

                  // Using Text.rich to format bold parts of the message
                  return Card(
                    color: notification['isRead'] ?? false ? Colors.grey[300] : Color(0xFFE4D9CD),
                    margin: EdgeInsets.all(8),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.center, // Center the row contents vertically
                        children: [
                          Icon(Icons.notifications, color: notification['isRead'] ?? false ? Colors.grey : Color(0xffe154314)),
                          SizedBox(width: 10),
                          Expanded(
                            child: Text.rich(
                              TextSpan(
                                children: [
                                  TextSpan(
                                    text: "Dear ",
                                    style: TextStyle(fontWeight: FontWeight.normal), // Normal text
                                  ),
                                  TextSpan(
                                    text: username,
                                    style: TextStyle(fontWeight: FontWeight.bold), // Bold username
                                  ),
                                  TextSpan(
                                    text: ", the ride you requested on ",
                                    style: TextStyle(fontWeight: FontWeight.normal), // Normal text
                                  ),
                                  TextSpan(
                                    text: formattedDate,
                                    style: TextStyle(fontWeight: FontWeight.bold), // Bold date
                                  ),
                                  TextSpan(
                                    text: " to go from ",
                                    style: TextStyle(fontWeight: FontWeight.normal), // Normal text
                                  ),
                                  TextSpan(
                                    text: notification['pickup_address'],
                                    style: TextStyle(fontWeight: FontWeight.bold), // Bold pickup address
                                  ),
                                  TextSpan(
                                    text: " to ",
                                    style: TextStyle(fontWeight: FontWeight.normal), // Normal text
                                  ),
                                  TextSpan(
                                    text: notification['destination_address'],
                                    style: TextStyle(fontWeight: FontWeight.bold), // Bold destination address
                                  ),
                                  TextSpan(
                                    text: " has been ",
                                    style: TextStyle(fontWeight: FontWeight.normal), // Normal text
                                  ),
                                  TextSpan(
                                    text: notification['status'],
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold, // Bold status
                                      color: _getStatusColor(notification['status']), // Set the status font color
                                    ),
                                  ),
                                  TextSpan(
                                    text: "!",
                                    style: TextStyle(fontWeight: FontWeight.normal), // Normal text
                                  ),
                                ],
                              ),
                            ),
                          ),
                          if (!(notification['isRead'] ?? false))
                            InkWell(
                              onTap: () => _markAsRead(notification['id']),
                              child: Padding(
                                padding: const EdgeInsets.only(left: 10, top: 5),
                                child: Text(
                                  "Mark as Read",
                                  style: TextStyle(fontSize: 12, color: Colors.blue),
                                ),
                              ),
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
      ),
    );
  }
}

