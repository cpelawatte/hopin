import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:intl/intl.dart';
import 'package:google_fonts/google_fonts.dart';

class MessagePage extends StatefulWidget {
  final String currentUserPhone;
  final String driverPhone;

  const MessagePage({Key? key, required this.currentUserPhone, required this.driverPhone}) : super(key: key);

  @override
  _MessagePageState createState() => _MessagePageState();
}

class _MessagePageState extends State<MessagePage> {
  TextEditingController _messageController = TextEditingController();
  late DatabaseReference _chatRef;
  late DatabaseReference _userChatsRef;
  late String _chatID;
  String _driverName = "Driver"; // Default name

  @override
  void initState() {
    super.initState();
    _chatID = getChatID(widget.currentUserPhone, widget.driverPhone);
    _chatRef = FirebaseDatabase.instance.ref('chats/$_chatID/messages');
    _userChatsRef = FirebaseDatabase.instance.ref('users_chats');
    _fetchDriverName();
  }

  // Function to generate chatID from user phone numbers
  String getChatID(String userPhone, String driverPhone) {
    List<String> phones = [userPhone, driverPhone];
    phones.sort();
    return phones.join('_');
  }

  // Fetch driver's name from Firebase
  void _fetchDriverName() {
    DatabaseReference usersRef = FirebaseDatabase.instance.ref('Users');

    usersRef.orderByChild('phone').equalTo(widget.driverPhone).once().then((DatabaseEvent event) {
      if (event.snapshot.value != null && event.snapshot.value is Map) {
        Map<dynamic, dynamic> usersData = event.snapshot.value as Map<dynamic, dynamic>;
        usersData.forEach((key, value) {
          if (value is Map && value.containsKey('username')) {
            setState(() {
              _driverName = value['username'];
            });
          }
        });
      }
    });
  }

  // Function to send a new message
  void _sendMessage() async {
    String message = _messageController.text.trim();
    if (message.isEmpty) return;

    String timestamp = DateFormat("yyyy-MM-dd HH:mm:ss").format(DateTime.now());

    DatabaseReference chatRef = FirebaseDatabase.instance.ref('chats/$_chatID');

    // Ensure chat and participants exist
    await chatRef.child('participants').update({
      widget.currentUserPhone: true,
      widget.driverPhone: true,
    });

    // Message data
    Map<String, dynamic> messageData = {
      'sender': widget.currentUserPhone,
      'receiver': widget.driverPhone,
      'timestamp': timestamp,
      'message': message,
    };

    try {
      await chatRef.child('messages').push().set(messageData);
      await _userChatsRef.child(widget.currentUserPhone).child(_chatID).set(true);
      await _userChatsRef.child(widget.driverPhone).child(_chatID).set(true);
      _messageController.clear();
    } catch (error) {
      print("🔥 Firebase Write Error: $error");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: PreferredSize(
          preferredSize: Size.fromHeight(80),
          child: AppBar(
            backgroundColor: Color(0xffe154314),
            automaticallyImplyLeading: false, // remove default leading
            title: Padding(
              padding: const EdgeInsets.only(top: 10),
              child: Row(
                children: [
                  IconButton(
                    icon: Icon(Icons.arrow_back, color: Colors.white, size: 30),
                    onPressed: () => Navigator.pop(context),
                  ),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Chat with $_driverName',
                      style: GoogleFonts.poppins(
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                        fontSize: 22,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),



      body: Column(
        children: [
          SizedBox(height: 25),
          Expanded(
              child: StreamBuilder(
                stream: _chatRef.onValue,
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return Center(child: CircularProgressIndicator());
                  }
                  if (snapshot.hasData && snapshot.data != null) {
                    var data = snapshot.data!.snapshot.value;
                    if (data is Map<dynamic, dynamic>) {
                      List<Map<dynamic, dynamic>> messages = [];

                      // Convert map to list and add key if needed
                      data.forEach((key, value) {
                        if (value is Map) {
                          value['key'] = key;
                          messages.add(value);
                        }
                      });

                      // Sort messages by timestamp
                      messages.sort((a, b) {
                        return DateTime.parse(a['timestamp'])
                            .compareTo(DateTime.parse(b['timestamp']));
                      });

                      List<Widget> messageWidgets = messages.map((value) {
                        bool isSender = value['sender'] == widget.currentUserPhone;
                        Color bubbleColor = isSender
                            ? Color(0xffe154314).withOpacity(0.9)
                            : Color(0xffefe5dc).withOpacity(1.0);

                        FontWeight fontWeight = isSender ? FontWeight.w500 : FontWeight.w400;

                        return Padding(
                          padding: const EdgeInsets.symmetric(vertical: 5.0, horizontal: 8.0),
                          child: Align(
                            alignment: isSender ? Alignment.centerRight : Alignment.centerLeft,
                            child: ConstrainedBox(
                              constraints: BoxConstraints(
                                maxWidth: MediaQuery.of(context).size.width * 0.7,
                              ),
                              child: Container(
                                padding: EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
                                decoration: BoxDecoration(
                                  color: bubbleColor,
                                  borderRadius: BorderRadius.only(
                                    topLeft: Radius.circular(18),
                                    topRight: Radius.circular(18),
                                    bottomLeft: isSender ? Radius.circular(18) : Radius.circular(6),
                                    bottomRight: isSender ? Radius.circular(6) : Radius.circular(18),
                                  ),
                                ),
                                child: Text(
                                  value['message'],
                                  style: GoogleFonts.poppins(
                                    color: isSender ? Colors.white : Colors.black,
                                    fontWeight: fontWeight,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        );
                      }).toList();

                      return ListView(
                        padding: EdgeInsets.only(bottom: 10),
                        children: messageWidgets,
                      );
                    } else {
                      return Center(child: Text('No messages yet.'));
                    }
                  } else {
                    return Center(child: Text('No messages yet.'));
                  }
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
                      hintText: 'Type a message...',
                      border: OutlineInputBorder(),
                    ),
                  ),
                ),
                IconButton(
                  icon: Icon(Icons.send),
                  onPressed: _sendMessage,
                  color: Color(0xffe154314),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
