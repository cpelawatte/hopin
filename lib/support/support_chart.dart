import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:google_fonts/google_fonts.dart';

class SupportChatScreen extends StatefulWidget {
  final String phoneNumber;

  SupportChatScreen({required this.phoneNumber});

  @override
  _SupportChatScreenState createState() => _SupportChatScreenState();
}

class _SupportChatScreenState extends State<SupportChatScreen> {
  late DatabaseReference _chatRef;
  TextEditingController _messageController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _chatRef = FirebaseDatabase.instance.ref('support_chats/${widget.phoneNumber}');
  }

  void _sendMessage() {
    if (_messageController.text.isNotEmpty) {
      String messageText = _messageController.text;
      String timestamp = DateTime.now().toIso8601String();

      _chatRef.push().set({
        'message': messageText,
        'timestamp': timestamp,
        'sender': widget.phoneNumber,
      });

      _messageController.clear();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xffefe5dc),
      appBar: AppBar(
        backgroundColor: Color(0xFF154314),
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () {
            Navigator.pop(context);
          },
        ),
        title: Text(
          "Support Chat",
          style: GoogleFonts.poppins(
            fontWeight: FontWeight.w600,
            color: Colors.white,
          ),
        ),
      ),


      body: Column(
        children: [
      Expanded(
      child: StreamBuilder(
      stream: _chatRef.onValue,
        builder: (context, AsyncSnapshot<DatabaseEvent> snapshot) {
          if (snapshot.hasData && snapshot.data!.snapshot.value != null) {
            try {
              Map<dynamic, dynamic> messages = snapshot.data!.snapshot.value as Map;
              List<Map<String, dynamic>> chatList = messages.entries.map((entry) {
                return {
                  'message': entry.value['message'] ?? '',
                  'timestamp': entry.value['timestamp'] ?? '',
                  'sender': entry.value['sender'] ?? '',
                };
              }).toList();

              // Sort by timestamp
              chatList.sort((a, b) => a['timestamp'].compareTo(b['timestamp']));

              return Container(
                color: Colors.transparent, // Optional: for styling
                child: ListView.builder(
                  itemCount: chatList.length,
                  itemBuilder: (context, index) {
                    var chat = chatList[index];
                    String sender = chat['sender'];
                    String message = chat['message'];
                    String timestamp = chat['timestamp'];

                    DateTime dateTime = DateTime.tryParse(timestamp) ?? DateTime.now();
                    String formattedDate =
                        "${dateTime.hour}:${dateTime.minute} - ${dateTime.day}/${dateTime.month}/${dateTime.year}";

                    return Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
                      child: Align(
                        alignment: sender == widget.phoneNumber
                            ? Alignment.centerRight
                            : Alignment.centerLeft,
                        child: ConstrainedBox(
                          constraints: BoxConstraints(
                            maxWidth: MediaQuery.of(context).size.width * 0.6,
                          ),
                          child: Container(
                            padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                            decoration: BoxDecoration(
                              color: sender == widget.phoneNumber
                                  ? Color(0xff154314)
                                  : Color(0xFFF5F5F5),
                              borderRadius: BorderRadius.only(
                                topLeft: Radius.circular(12),
                                topRight: Radius.circular(12),
                                bottomLeft: Radius.circular(sender == widget.phoneNumber ? 12 : 0),
                                bottomRight: Radius.circular(sender == widget.phoneNumber ? 0 : 12),
                              ),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  message,
                                  style: GoogleFonts.poppins(
                                    color: sender == widget.phoneNumber ? Colors.white : Colors.black,
                                  ),
                                ),
                                SizedBox(height: 5),
                                Text(
                                  formattedDate,
                                  style: GoogleFonts.poppins(
                                    color: sender == widget.phoneNumber
                                        ? Colors.white70
                                        : Colors.black45,
                                    fontSize: 11,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    );
                  },
                ),
              );
            } catch (e) {
              return Center(child: Text("Error parsing chat data."));
            }
          }

          return Center(child: Text("No messages yet"));
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
                      hintText: "Type a message",
                      filled: true,
                      fillColor: Colors.white,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                  ),
                ),
                SizedBox(width: 8),
                IconButton(
                  icon: Icon(Icons.send, color: Color(0xFF154314)),
                  onPressed: _sendMessage,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
