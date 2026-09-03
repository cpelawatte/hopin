import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:hopin/inapp_communication/new_conversation.dart';
import 'package:hopin/inbox/inbox.dart';
import 'package:hopin/user_home/account_settings.dart';
import 'package:hopin/user_home/post_ride_selection.dart';
import 'package:hopin/user_home/home_page.dart';

import '../my_rides/myrides.dart';
import '../user_home/user_profile.dart';

class ChatsTab extends StatefulWidget {
  final String phoneNumber;

  ChatsTab({required this.phoneNumber});

  @override
  _ChatsTabState createState() => _ChatsTabState();
}

class _ChatsTabState extends State<ChatsTab> {
  late DatabaseReference _userChatsRef;
  late DatabaseReference _usersRef;
  Map<String, Map<String, String>> chatUsers = {}; // Stores chatID -> {username, profileImageUrl}

  @override
  void initState() {
    super.initState();
    _userChatsRef = FirebaseDatabase.instance.ref('users_chats/${widget.phoneNumber}');
    _usersRef = FirebaseDatabase.instance.ref('Users');
    _fetchChats();
  }

  void _fetchChats() {
    _userChatsRef.onValue.listen((event) {
      if (event.snapshot.value != null && event.snapshot.value is Map) {
        Map<dynamic, dynamic> chats = event.snapshot.value as Map;
        print('Chats: $chats');  // Debugging line to see the fetched chats

        Map<String, Map<String, String>> updatedChatUsers = {};

        List<Future<void>> futures = [];

        // Iterate through each chatID
        for (String chatID in chats.keys) {
          // Extract the other user's phone number
          String otherUserPhone = chatID.replaceAll(widget.phoneNumber, '').replaceAll('_', '').trim();

          print('Looking for user: $otherUserPhone');  // Debugging line to check phone

          // Query the Users node to get the username and profileImageUrl of the other user
          futures.add(_usersRef.orderByChild('phone').equalTo(otherUserPhone).once().then((DatabaseEvent event) {
            if (event.snapshot.value != null && event.snapshot.value is Map) {
              Map<dynamic, dynamic> usersData = event.snapshot.value as Map;
              print('User Data: $usersData');  // Debugging line to see fetched user data

              // Iterate through the fetched user data
              usersData.forEach((key, value) {
                if (value is Map && value.containsKey('username') && value.containsKey('profileImageUrl')) {
                  updatedChatUsers[chatID] = {
                    'username': value['username'],
                    'profileImageUrl': value['profileImageUrl'],
                  };
                }
              });
            }
          }));
        }

        // Wait for all futures to complete, then update the state
        Future.wait(futures).then((_) {
          setState(() {
            chatUsers = updatedChatUsers;  // Update the chatUsers map with usernames and profileImageUrl
          });
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xffefe5dc),
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
      body: chatUsers.isEmpty
          ? Center(child: Text("No chats yet"))
          : ListView.builder(
        itemCount: chatUsers.length,
        itemBuilder: (context, index) {
          String chatID = chatUsers.keys.elementAt(index);
          String username = chatUsers[chatID]?['username'] ?? "Unknown";
          String profileImageUrl = chatUsers[chatID]?['profileImageUrl'] ?? '';

          return ListTile(
            leading: CircleAvatar(
              backgroundImage: profileImageUrl.isNotEmpty
                  ? NetworkImage(profileImageUrl)
                  : null,
              child: profileImageUrl.isEmpty
                  ? Icon(Icons.account_circle) // Placeholder if no image is available
                  : null,
            ),
            title: Text(username),
            subtitle: Text("Tap to open chat"),
            onTap: () {
              // Extract the other user's phone number from chatID
              String otherUserPhone = chatID.replaceAll(widget.phoneNumber, '').replaceAll('_', '').trim();

              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => MessagePage(
                    currentUserPhone: widget.phoneNumber,
                    driverPhone: otherUserPhone,
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
