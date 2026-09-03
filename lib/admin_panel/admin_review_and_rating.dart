import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:hopin/admin_panel/admin_home.dart';
import 'package:hopin/admin_panel/admin_chat_support.dart';
import 'package:hopin/admin_panel/vehicle_registration_request.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:dropdown_search/dropdown_search.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';


class AdminReviewsPage extends StatefulWidget {
  final String adminPhoneNumber;
  const AdminReviewsPage({Key? key, required this.adminPhoneNumber}) : super(key: key);

  @override
  State<AdminReviewsPage> createState() => _AdminReviewsPageState();
}

class _AdminReviewsPageState extends State<AdminReviewsPage> {
  String selectedRatingFilter = 'All';
  String searchQuery = '';
  final ratingsRef = FirebaseDatabase.instance.ref().child('ratings');

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
            title: Text('User Reviews & Ratings', style: GoogleFonts.poppins(color: Colors.white, fontWeight: FontWeight.w600)),
          ),
          drawer: isLargeScreen ? null : Drawer(child: buildDrawer(context)),
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
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          // Ratings Filter Dropdown
                          Expanded(
                            flex: 1,
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                              decoration: BoxDecoration(
                                border: Border.all(color: Colors.grey),
                                borderRadius: BorderRadius.circular(10),
                                color: Colors.white70,
                              ),
                              child: DropdownButtonHideUnderline(
                                child: DropdownButton<String>(
                                  value: selectedRatingFilter,
                                  isExpanded: true,
                                  onChanged: (value) {
                                    setState(() {
                                      selectedRatingFilter = value!;
                                    });
                                  },
                                  items: ['All', '5', '4', '3', '2', '1']
                                      .map(
                                        (rating) => DropdownMenuItem<String>(
                                      value: rating,
                                      child: Text(
                                        rating == 'All' ? 'All Ratings' : '$rating Stars',
                                        style: GoogleFonts.poppins(),
                                      ),
                                    ),
                                  )
                                      .toList(),
                                ),
                              ),
                            ),
                          ),

                          const SizedBox(width: 10),

                          // Search Bar
                          Expanded(
                            flex: 2,
                            child: TextField(
                              decoration: InputDecoration(
                                hintText: 'Search by username or phone',
                                hintStyle: GoogleFonts.poppins(),
                                prefixIcon: const Icon(Icons.search),
                                fillColor: Colors.white70,
                                filled: true,
                                contentPadding: const EdgeInsets.symmetric(vertical: 12),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(10),
                                  borderSide: BorderSide.none,
                                ),
                              ),
                              onChanged: (value) {
                                setState(() {
                                  searchQuery = value.toLowerCase();
                                });
                              },
                            ),
                          ),

                          const SizedBox(width: 10),

                          // Send Warning Button
                          Expanded(
                            flex: 1,
                            child: SizedBox(
                              height: 48, // Match height with dropdown and text field
                              child: ElevatedButton.icon(
                                onPressed: () async {
                                  final selectedUser = await showDialog<Map<String, dynamic>>(
                                    context: context,
                                    builder: (_) => SelectUserDialog(),
                                  );

                                  if (selectedUser != null) {
                                    // Show confirmation dialog
                                    await showDialog(
                                      context: context,
                                      builder: (_) => ConfirmSendEmailDialog(user: selectedUser),
                                    );
                                  }
                                },
                                icon: const Icon(Icons.warning, color: Colors.white),
                                label: Text(
                                  'Send Warning',
                                  style: GoogleFonts.poppins(color: Colors.white),
                                ),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: const Color(0xFFFF7800),
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                ),
                              ),
                            ),
                          ),

                          const SizedBox(width: 10),
                          Expanded(
                            flex: 1,
                            child: SizedBox(
                              height: 48,
                              child: ElevatedButton.icon(
                                onPressed: () async {
                                  final selectedUser = await showDialog<Map<String, dynamic>>(
                                    context: context,
                                    builder: (_) => SelectUserDialog(),
                                  );

                                  if (selectedUser != null) {
                                    // Show delete confirmation dialog
                                    await showDialog(
                                      context: context,
                                      builder: (_) => ConfirmDeleteUserDialog(user: selectedUser),
                                    );
                                  }
                                },
                                icon: const Icon(Icons.delete, color: Colors.white),
                                label: Text(
                                  'Delete User',
                                  style: GoogleFonts.poppins(color: Colors.white),
                                ),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: const Color(0xffd0342c),
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                ),
                              ),
                            ),
                          ),

                        ],
                      ),
                      const SizedBox(height: 20),
                      Expanded(
                        child: StreamBuilder<DatabaseEvent>(
                          stream: ratingsRef.onValue,
                          builder: (context, snapshot) {
                            if (snapshot.hasData && snapshot.data!.snapshot.value != null) {
                              Map<dynamic, dynamic> ratingsMap = snapshot.data!.snapshot.value as Map<dynamic, dynamic>;
                              List<Map<String, dynamic>> allRatings = [];

                              ratingsMap.forEach((phone, userRatings) {
                                if (userRatings is Map) {
                                  userRatings.forEach((key, value) {
                                    allRatings.add({
                                      'phone': phone,
                                      'rating': value['rating'],
                                      'review': value['review'],
                                      'timestamp': value['timestamp'],
                                    });
                                  });
                                }
                              });

                              List<Map<String, dynamic>> filteredRatings = allRatings.where((item) {
                                bool matchesRating = selectedRatingFilter == 'All' || item['rating'].toString() == selectedRatingFilter;
                                return matchesRating;
                              }).toList();

                              return ListView.builder(
                                itemCount: filteredRatings.length,
                                itemBuilder: (context, index) {
                                  final ratingItem = filteredRatings[index];
                                  final phone = ratingItem['phone'];

                                  return FutureBuilder<DatabaseEvent>(
                                    future: FirebaseDatabase.instance.ref().child('Users').orderByChild('phone').equalTo(phone).once(),
                                    builder: (context, userSnapshot) {
                                      if (userSnapshot.connectionState == ConnectionState.waiting) {
                                        return const Center(child: CircularProgressIndicator());
                                      } else if (userSnapshot.hasData && userSnapshot.data!.snapshot.value != null) {
                                        final usersMap = userSnapshot.data!.snapshot.value as Map;
                                        final user = usersMap.values.first;

                                        if (searchQuery.isNotEmpty &&
                                            !(user['username']?.toLowerCase().contains(searchQuery) ?? false) &&
                                            !(phone.toLowerCase().contains(searchQuery))) {
                                          return const SizedBox.shrink();
                                        }

                                        return Card(
                                          margin: const EdgeInsets.symmetric(vertical: 8),
                                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                                          child: ListTile(
                                            title: Text(
                                              '${ratingItem['review']}',
                                              style: GoogleFonts.poppins(fontSize: 16),
                                            ),
                                            subtitle: Text(
                                              'Rating: ${ratingItem['rating']} ☆',
                                              style: GoogleFonts.poppins(color: Colors.grey[700]),
                                            ),
                                            trailing: Column(
                                              mainAxisAlignment: MainAxisAlignment.center,
                                              crossAxisAlignment: CrossAxisAlignment.end,
                                              children: [
                                                Text(
                                                  '${user['username']}',
                                                  style: GoogleFonts.poppins(fontWeight: FontWeight.w500),
                                                ),
                                                Text(
                                                  phone,
                                                  style: GoogleFonts.poppins(fontSize: 12, color: Colors.grey),
                                                ),
                                              ],
                                            ),
                                          ),
                                        );
                                      }
                                      return const SizedBox();
                                    },
                                  );
                                },
                              );
                            }
                            return const Center(child: CircularProgressIndicator());
                          },
                        ),
                      )
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class SelectUserDialog extends StatefulWidget {
  @override
  _SelectUserDialogState createState() => _SelectUserDialogState();
}

class _SelectUserDialogState extends State<SelectUserDialog> {
  List<Map<String, dynamic>> _userList = [];

  @override
  void initState() {
    super.initState();
    _fetchUsers();
  }

  Future<void> _fetchUsers() async {
    DatabaseReference ref = FirebaseDatabase.instance.ref('Users');
    final snapshot = await ref.get();

    List<Map<String, dynamic>> tempList = [];
    if (snapshot.exists) {
      final data = snapshot.value as Map;
      data.forEach((key, value) {
        final user = Map<String, dynamic>.from(value);
        tempList.add(user);
      });
    }

    setState(() {
      _userList = tempList;
    });
  }

  bool _matchesSearch(String search, Map<String, dynamic> user) {
    final searchLower = search.toLowerCase();

    // Clean phone number for comparison
    final phoneRaw = user['phone'].toString().replaceAll('+94', '0').replaceAll(RegExp(r'\D'), '');
    final phoneShort = phoneRaw.startsWith('0') ? phoneRaw.substring(1) : phoneRaw;

    return user['username'].toString().toLowerCase().contains(searchLower) ||
        user['email'].toString().toLowerCase().contains(searchLower) ||
        phoneRaw.contains(search) ||
        phoneShort.contains(search);
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(
        'Select a User',
        style: GoogleFonts.poppins(
          fontSize: 18,
          fontWeight: FontWeight.w600,
        ),
      ),
      content: DropdownSearch<Map<String, dynamic>>(
        asyncItems: (String filter) async {
          return _userList.where((user) => _matchesSearch(filter, user)).toList();
        },
        itemAsString: (user) => '${user['username']} (${user['phone']})',
        onChanged: (user) {
          Navigator.of(context).pop(user);
        },
        dropdownDecoratorProps: DropDownDecoratorProps(
          dropdownSearchDecoration: InputDecoration(
            hintText: 'Select a user',
          ),
        ),
        popupProps: PopupProps.menu(
          showSearchBox: true,
          searchFieldProps: TextFieldProps(
            decoration: InputDecoration(hintText: 'Search by username, phone, or email'),
          ),
        ),
      ),
    );
  }
}

class ConfirmSendEmailDialog extends StatelessWidget {
  final Map<String, dynamic> user;

  const ConfirmSendEmailDialog({Key? key, required this.user}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: const Color(0xffefe5dc),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      title: Text('Confirm Warning Email', style: GoogleFonts.poppins(fontWeight: FontWeight.bold)),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Username: ${user['username']}', style: GoogleFonts.poppins()),
          Text('Email: ${user['email']}', style: GoogleFonts.poppins()),
        ],
      ),
      actions: [
        TextButton(
          style: TextButton.styleFrom(
            backgroundColor: Colors.red,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
          child: Text(
            'Cancel',
            style: GoogleFonts.poppins(color: Colors.white),
          ),
          onPressed: () => Navigator.of(context).pop(),
        ),
        TextButton(
          style: TextButton.styleFrom(
            backgroundColor: Color(0xff154314),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
          child: Text(
            'Send Email',
            style: GoogleFonts.poppins(color: Colors.white),
          ),
          onPressed: () async {
            Navigator.of(context).pop();
            await sendWarningEmailToUser(user['phone']);
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                  'Warning email sent to ${user['email']}',
                  style: GoogleFonts.poppins(),
                ),
              ),
            );
          },
        ),
      ],
    );
  }

}


Future<void> sendWarningEmailToUser(String phone) async {
  const serviceID = 'service_zsz6t7u';
  const templateID = 'template_e3pp6bd';
  const publicKey = 'D28ijxKAYyPRhR60Y';
  const privateKey = 'K6zklW_-H2APsYw0sIATA';

  try {
    // Query the user based on phone number
    DatabaseReference usersRef = FirebaseDatabase.instance.ref('Users');
    DataSnapshot snapshot = await usersRef.orderByChild('phone').equalTo(phone).get();

    if (!snapshot.exists) {
      print("User not found with phone: $phone");
      return;
    }

    // Since multiple users could match, get the first user
    Map<String, dynamic> userMap = Map<String, dynamic>.from((snapshot.value as Map).values.first);

    final emailData = {
      'service_id': serviceID,
      'template_id': templateID,
      'user_id': publicKey,
      'template_params': {
        'username': userMap['username'],
        'date_sent': DateTime.now().toLocal().toString().split(' ')[0],
        'email': userMap['email'],
      }
    };

    final response = await http.post(
      Uri.parse('https://api.emailjs.com/api/v1.0/email/send'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $privateKey',
      },
      body: jsonEncode(emailData),
    );

    if (response.statusCode == 200) {
      print("Email sent to ${userMap['email']}.");
    } else {
      print("Failed to send email. Status code: ${response.statusCode}");
      print("Response: ${response.body}");
    }
  } catch (e) {
    print("Error sending email: $e");
  }
}

class ConfirmDeleteUserDialog extends StatelessWidget {
  final Map<String, dynamic> user;

  const ConfirmDeleteUserDialog({Key? key, required this.user}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: const Color(0xffefe5dc),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      title: Text('Confirm User Deletion', style: GoogleFonts.poppins(fontWeight: FontWeight.bold)),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Username: ${user['username']}', style: GoogleFonts.poppins()),
          Text('Email: ${user['email']}', style: GoogleFonts.poppins()),
        ],
      ),
      actions: [
        TextButton(
          style: TextButton.styleFrom(
            backgroundColor: Colors.red,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
          child: Text(
            'Cancel',
            style: GoogleFonts.poppins(color: Colors.white),
          ),
          onPressed: () => Navigator.of(context).pop(),
        ),
        TextButton(
          style: TextButton.styleFrom(
            backgroundColor: Color(0xff154314),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
          child: Text(
            'Delete',
            style: GoogleFonts.poppins(color: Colors.white),
          ),
          onPressed: () async {
            Navigator.of(context).pop();

            await deleteUser(user['phone']);

            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                  'User ${user['username']} deleted',
                  style: GoogleFonts.poppins(),
                ),
              ),
            );
          },
        ),
      ],
    );
  }
}

Future<void> deleteUser(String phone) async {
  const serviceID = 'service_zsz6t7u';
  const templateID = 'template_20nqzvv';
  const publicKey = 'D28ijxKAYyPRhR60Y';
  const privateKey = 'K6zklW_-H2APsYw0sIATA';

  try {
    final usersRef = FirebaseDatabase.instance.ref('Users');
    final snapshot = await usersRef.orderByChild('phone').equalTo(phone).get();

    if (!snapshot.exists) {
      print("User not found with phone: $phone");
      return;
    }

    final usersMap = snapshot.value as Map;
    final userKey = usersMap.keys.first;
    final userData = Map<String, dynamic>.from(usersMap[userKey]);

    // Copy to deleted_users
    await FirebaseDatabase.instance.ref('deleted_users/$userKey').set(userData);

    // Delete from Users
    await FirebaseDatabase.instance.ref('Users/$userKey').remove();

    // Send deletion email
    final emailData = {
      'service_id': serviceID,
      'template_id': templateID,
      'user_id': publicKey,
      'template_params': {
        'username': userData['username'],
        'date_sent': DateTime.now().toLocal().toString().split(' ')[0],
        'email': userData['email'],
      }
    };

    final response = await http.post(
      Uri.parse('https://api.emailjs.com/api/v1.0/email/send'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $privateKey',
      },
      body: jsonEncode(emailData),
    );

    if (response.statusCode == 200) {
      print("Deletion email sent to ${userData['email']}.");
    } else {
      print("Failed to send deletion email. Status: ${response.statusCode}");
    }
  } catch (e) {
    print("Error deleting user: $e");
  }
}
