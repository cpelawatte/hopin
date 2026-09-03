import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter/services.dart';
import 'package:hopin/admin_panel/admin_chat_support.dart';
import 'package:hopin/admin_panel/vehicle_registration_request.dart';
import 'package:hopin/admin_panel/admin_home.dart';
import 'package:hopin/admin_panel/admin_review_and_rating.dart';
import 'package:intl/intl.dart';

class AdminChatPage extends StatefulWidget {
  final String adminPhoneNumber;
  const AdminChatPage({Key? key, required this.adminPhoneNumber}) : super(key: key);

  @override
  _AdminChatPageState createState() => _AdminChatPageState();
}

class _AdminChatPageState extends State<AdminChatPage> {
  final DatabaseReference _supportChatsRef = FirebaseDatabase.instance.ref('support_chats');
  final DatabaseReference _usersRef = FirebaseDatabase.instance.ref('Users');
  late TextEditingController _messageController;

  @override
  void initState() {
    super.initState();
    _messageController = TextEditingController();
  }

  void sendMessage(String userPhoneNumber) {
    if (_messageController.text.isNotEmpty) {
      String message = _messageController.text;
      String timestamp = DateTime.now().toIso8601String();

      // Push the new message to the correct chat node
      _supportChatsRef.child(userPhoneNumber).push().set({
        'message': message,
        'sender': widget.adminPhoneNumber,
        'timestamp': timestamp,
        'isRead': false,
      });

      // Clear the input field after sending the message
      _messageController.clear();
    }
  }

  // Open Drawer (sidebar menu)
  void openDrawer() {
    Scaffold.of(context).openDrawer();
  }

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
              icon: const Icon(Icons.arrow_back),
              color: Colors.white,
              onPressed: () {
                Navigator.pop(context);
              },
            ),
            title: Text(
              'Support Chats',
              style: GoogleFonts.poppins(color: Colors.white, fontWeight: FontWeight.bold),
            ),
          ),
          drawer: isLargeScreen ? null : buildDrawer(context),
          body: Row(
            children: [
              if (isLargeScreen)
                Container(
                  width: 250,
                  color: const Color(0xffefe5dc),
                  child: buildDrawer(context),
                ),
              if (isLargeScreen)
                const VerticalDivider(
                  width: 1,
                  thickness: 1,
                  color: Colors.grey,
                ),
              Expanded(
                child: StreamBuilder(
                  stream: _supportChatsRef.onValue,
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(child: CircularProgressIndicator());
                    }

                    if (snapshot.hasData) {
                      final dataSnapshot = (snapshot.data! as DatabaseEvent)
                          .snapshot.value;

                      if (dataSnapshot == null) {
                        return const Center(child: Text(
                            "No Chats Available"));
                      }

                      Map<dynamic, dynamic> chats = dataSnapshot as Map<
                          dynamic,
                          dynamic>;

                      return ListView.builder(
                        itemCount: chats.length,
                        itemBuilder: (context, index) {
                          String userPhoneNumber = chats.keys.elementAt(
                              index);
                          Map<dynamic,
                              dynamic> messages = chats[userPhoneNumber];

                          bool hasUnread = messages.values.any((msg) => msg['sender'] == userPhoneNumber && msg['isRead'] == false);

                          return FutureBuilder(
                            future: _usersRef.orderByChild('phone').equalTo(
                                userPhoneNumber).get(),
                            builder: (context, userSnapshot) {
                              if (userSnapshot.connectionState ==
                                  ConnectionState.waiting) {
                                return const Center(
                                    child: CircularProgressIndicator());
                              } else if (userSnapshot.hasData &&
                                  userSnapshot.data != null) {
                                Map<dynamic, dynamic> userData =
                                (userSnapshot.data! as DataSnapshot)
                                    .value as Map<dynamic, dynamic>;
                                String username = userData.values
                                    .first['username'] ?? 'Unknown';
                                String profileImageUrl = userData.values
                                    .first['profileImageUrl'] ?? '';

                                return Card(
                                  margin: const EdgeInsets.all(8.0),
                                  shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(
                                          16)),
                                  child: ListTile(
                                    leading: profileImageUrl.isNotEmpty
                                        ? CircleAvatar(
                                      backgroundImage: NetworkImage(
                                          profileImageUrl),
                                    )
                                        : const CircleAvatar(
                                        child: Icon(Icons.person)),
                                    title: Text(
                                      username,
                                      style: const TextStyle(
                                          fontFamily: 'Poppins'),
                                    ),
                                    subtitle: Text(
                                      'Tap to chat with $username',
                                      style: const TextStyle(
                                          fontFamily: 'Poppins',
                                          color: Colors.grey),
                                    ),
                                    trailing: hasUnread
                                        ? const Icon(Icons.circle, color: Color(0xff154314), size: 12)
                                        : null,

                                    onTap: () {
                                      Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (context) =>
                                              IndividualChatPage(
                                                adminPhoneNumber: widget
                                                    .adminPhoneNumber,
                                                userPhoneNumber: userPhoneNumber,
                                              ),
                                        ),
                                      );
                                    },
                                  ),
                                );
                              }
                              return const SizedBox();
                            },
                          );
                        },
                      );
                    }

                    return const Center(child: Text("No Chats Available"));
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
}


class IndividualChatPage extends StatefulWidget {
  final String adminPhoneNumber;
  final String userPhoneNumber;

  const IndividualChatPage({
    Key? key,
    required this.adminPhoneNumber,
    required this.userPhoneNumber,
  }) : super(key: key);

  @override
  _IndividualChatPageState createState() => _IndividualChatPageState();
}

class _IndividualChatPageState extends State<IndividualChatPage> {
  final DatabaseReference _supportChatsRef =
  FirebaseDatabase.instance.ref('support_chats');
  final DatabaseReference _usersRef = FirebaseDatabase.instance.ref('Users');
  late TextEditingController _messageController;

  String? username;

  @override
  void initState() {
    super.initState();
    _messageController = TextEditingController();
    fetchUsername();
    markMessagesAsRead();
  }

  void fetchUsername() async {
    final snapshot = await _usersRef
        .orderByChild('phone')
        .equalTo(widget.userPhoneNumber)
        .once();

    final data = snapshot.snapshot.value as Map?;
    if (data != null) {
      setState(() {
        username = data.values.first['username'] ?? 'User';
      });
    }
  }

  void markMessagesAsRead() async {
    final snapshot =
    await _supportChatsRef.child(widget.userPhoneNumber).once();

    final messages = snapshot.snapshot.value as Map?;
    if (messages != null) {
      messages.forEach((key, value) {
        if (value['sender'] == widget.userPhoneNumber &&
            value['isRead'] == false) {
          _supportChatsRef
              .child(widget.userPhoneNumber)
              .child(key)
              .update({'isRead': true});
        }
      });
    }
  }

  void sendMessage() {
    if (_messageController.text.isNotEmpty) {
      String message = _messageController.text;

      // Get current time and format it
      DateTime now = DateTime.now().toLocal();
      String timestamp = DateFormat('hh:mm  dd/MM/yyyy').format(now);

      _supportChatsRef.child(widget.userPhoneNumber).push().set({
        'message': message,
        'sender': widget.adminPhoneNumber,
        'timestamp': timestamp,
        'isRead': false,
      });

      _messageController.clear();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xffefe5dc),
      appBar: AppBar(
        backgroundColor: const Color(0xff154314),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          color: Colors.white,
          onPressed: () {
            Navigator.pop(context);
          },
        ),
        title: Text(
          'Chat with ${username ?? widget.userPhoneNumber}',
          style: GoogleFonts.poppins(
            color: Colors.white,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: StreamBuilder(
              stream: _supportChatsRef
                  .child(widget.userPhoneNumber)
                  .onValue,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (!snapshot.hasData || snapshot.data == null) {
                  return const Center(child: Text("No messages yet"));
                }

                var snapshotData =
                    (snapshot.data! as DatabaseEvent).snapshot.value;

                if (snapshotData == null || snapshotData == "") {
                  return const Center(child: Text("No messages yet"));
                }

                List<Widget> messageWidgets = [];

                if (snapshotData is Map<dynamic, dynamic>) {
                  var sortedKeys = snapshotData.keys.toList()
                    ..sort((a, b) =>
                        snapshotData[a]['timestamp']
                            .compareTo(snapshotData[b]['timestamp']));

                  for (var key in sortedKeys) {
                    var messageData = snapshotData[key];
                    String sender = messageData['sender'] ?? 'Unknown';
                    String message = messageData['message'] ?? '';
                    String rawTimestamp = messageData['timestamp'] ?? '';
                    String timestamp = rawTimestamp;
                    try {
                      DateTime parsed = DateTime.parse(rawTimestamp);
                      timestamp = DateFormat(' hh:mm  dd/MM/yyyy').format(parsed);
                    } catch (_) {}

                    bool isAdmin = sender == widget.adminPhoneNumber;

                    messageWidgets.add(
                      Align(
                        alignment: isAdmin
                            ? Alignment.centerRight
                            : Alignment.centerLeft,
                        child: Container(
                          margin: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 4),
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: isAdmin
                                ? const Color(0xff154314)
                                : const Color(0xfff0f0f0),
                            borderRadius: BorderRadius.only(
                              topLeft: const Radius.circular(16),
                              topRight: const Radius.circular(16),
                              bottomLeft: isAdmin
                                  ? const Radius.circular(16)
                                  : const Radius.circular(0),
                              bottomRight: isAdmin
                                  ? const Radius.circular(0)
                                  : const Radius.circular(16),
                            ),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                message,
                                style: TextStyle(
                                  fontFamily: 'Poppins',
                                  color:
                                  isAdmin ? Colors.white : Colors.black87,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                timestamp,
                                style: const TextStyle(
                                  fontSize: 10,
                                  fontFamily: 'Poppins',
                                  color: Colors.grey,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  }
                }

                return ListView(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  children: messageWidgets,
                );
              },
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _messageController,
                    decoration: InputDecoration(
                      hintText: 'Type your message...',
                      border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(16)),
                      filled: true,
                      fillColor: Colors.white,
                    ),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.send, color: Color(0xff154314)),
                  onPressed: sendMessage,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
