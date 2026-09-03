import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:hopin/firebase_options.dart';

class DevAdminChatTestScreen extends StatefulWidget {
  const DevAdminChatTestScreen({super.key});

  @override
  State<DevAdminChatTestScreen> createState() => _DevAdminChatTestScreenState();
}

class _DevAdminChatTestScreenState extends State<DevAdminChatTestScreen> {
  late DatabaseReference _chatRef;
  late Stream<DatabaseEvent> _chatStream;

  @override
  void initState() {
    super.initState();
    _initializeFirebaseAndDatabase();
  }

  Future<void> _initializeFirebaseAndDatabase() async {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
    _chatRef = FirebaseDatabase.instance.ref('support_chats/+94785249713');
    setState(() {
      _chatStream = _chatRef.onValue;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("🧪 Admin Chat Test")),
      body: _chatStreamBuilder(),
    );
  }

  Widget _chatStreamBuilder() {
    if (_chatRef == null || _chatStream == null) {
      return const Center(child: CircularProgressIndicator());
    }

    return StreamBuilder<DatabaseEvent>(
      stream: _chatStream,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError) {
          return Center(child: Text("❌ Error: ${snapshot.error}"));
        }

        if (!snapshot.hasData || snapshot.data?.snapshot.value == null) {
          return const Center(child: Text("No messages found"));
        }

        final messagesMap = Map<String, dynamic>.from(
          snapshot.data!.snapshot.value as Map,
        );

        // Sort by timestamp if exists
        final sortedMessages = messagesMap.entries.toList()
          ..sort((a, b) {
            final aTime = a.value['timestamp'] ?? 0;
            final bTime = b.value['timestamp'] ?? 0;
            return aTime.compareTo(bTime);
          });

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: sortedMessages.length,
          itemBuilder: (context, index) {
            final msgData = sortedMessages[index].value;
            final msg = msgData['message'] ?? 'No message';
            final sender = msgData['sender'] ?? 'Unknown';
            final time = msgData['timestamp'] ?? 0;

            return Container(
              margin: const EdgeInsets.only(bottom: 12),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: sender == 'admin' ? Colors.blue.shade50 : Colors.green.shade50,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(sender, style: const TextStyle(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 4),
                  Text(msg),
                  const SizedBox(height: 4),
                  Text('⏱ $time', style: const TextStyle(fontSize: 10, color: Colors.grey)),
                ],
              ),
            );
          },
        );
      },
    );
  }
}