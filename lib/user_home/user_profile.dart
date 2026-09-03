import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:hopin/user_home/post_ride_selection.dart';

import '../inbox/inbox.dart';
import '../my_rides/myrides.dart';
import 'account_settings.dart';
import 'home_page.dart';

class UserProfileViewPage extends StatefulWidget {
  final String phoneNumber;
  const UserProfileViewPage({required this.phoneNumber});

  @override
  State<UserProfileViewPage> createState() => _UserProfileViewPageState();
}

class _UserProfileViewPageState extends State<UserProfileViewPage> {
  String? username;
  String? email;
  String? profileImageUrl;
  String? description;
  String? disability;
  bool assistanceRequired = false;
  int? age;
  String? gender;
  String? registeredDate;
  double rating = 0.0;

  @override
  void initState() {
    super.initState();
    _loadUserDetails();
    _getAverageRating(widget.phoneNumber);
  }

  Future<void> _loadUserDetails() async {
    DatabaseReference ref = FirebaseDatabase.instance.ref().child('Users');
    DataSnapshot snapshot = await ref.get();

    if (snapshot.exists) {
      final users = Map<String, dynamic>.from(snapshot.value as Map);
      users.forEach((key, value) {
        final user = Map<String, dynamic>.from(value);
        if (user['phone'] == widget.phoneNumber) {
          setState(() {
            username = user['username'] ?? '';
            email = user['email'] ?? '';
            profileImageUrl = user['profileImageUrl'];
            description = user['description'] ?? '';
            disability = user['disability'];
            assistanceRequired = user['assistenceRequired'] ?? false;
            age = user['age'];
            gender = user['gender'];
            registeredDate = user['registered_Date'];
          });
        }
      });
    }
  }

  Future<void> _getAverageRating(String phoneNumber) async {
    DatabaseReference ratingsRef =
    FirebaseDatabase.instance.ref('ratings/$phoneNumber');
    DataSnapshot snapshot = await ratingsRef.get();
    if (!snapshot.exists) return;

    double total = 0;
    int count = 0;
    for (var child in snapshot.children) {
      var data = Map<String, dynamic>.from(child.value as Map);
      if (data.containsKey('rating')) {
        total += (data['rating'] as num).toDouble();
        count++;
      }
    }

    setState(() {
      rating = count == 0 ? 0.0 : total / count;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xFFEFE5DC),
      appBar: AppBar(
        backgroundColor: Color(0xFF154314),
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          "User Profile",
          style: GoogleFonts.poppins(
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: Colors.white,
          ),
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.settings, color: Colors.white),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => SettingsPage(phoneNumber: widget.phoneNumber),
                ),
              );
            },
          ),
        ],
      ),
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
            if (index == 1) {
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
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Center(
          child: Column(
            children: [
              // === DISABILITY LABEL BELOW APPBAR ===
              if (disability != null && disability!.isNotEmpty)
                Align(
                  alignment: Alignment.centerRight,
                  child: Container(
                    margin: EdgeInsets.only(top: 8, right: 8),
                    padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: Colors.blueAccent,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      disability!,
                      style: GoogleFonts.poppins(
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),

              SizedBox(
                height: 160,
                child: Stack(
                  clipBehavior: Clip.none,
                  alignment: Alignment.center,
                  children: [
                    Padding(
                      padding: const EdgeInsets.only(top: 16),
                      child: CircleAvatar(
                        radius: 60,
                        backgroundColor: Colors.white,
                        backgroundImage: profileImageUrl != null
                            ? NetworkImage(profileImageUrl!)
                            : AssetImage("assets/images/user.png")
                        as ImageProvider,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                width: double.infinity,
                margin: EdgeInsets.only(top: 24),
                padding: EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Color(0xFFD8CEC4),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Text(
                      username ?? '',
                      style: GoogleFonts.poppins(
                          fontSize: 20, fontWeight: FontWeight.w600),
                    ),
                    Text(
                      email ?? '',
                      style: GoogleFonts.poppins(fontSize: 14),
                    ),
                    SizedBox(height: 10),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.star,
                            color: Colors.amberAccent, size: 20),
                        SizedBox(width: 4),
                        Text(
                          rating.toStringAsFixed(1),
                          style: GoogleFonts.poppins(
                              fontSize: 16, fontWeight: FontWeight.w500),
                        ),
                      ],
                    ),
                    SizedBox(height: 16),
                    _buildDetailText("Phone Number", widget.phoneNumber),
                    _buildDetailText("Gender", gender),
                    _buildDetailText("Age", age?.toString()),
                    _buildDetailText("Disability", disability ?? 'Not available'),
                    SizedBox(height: 16),
                    Container(
                      width: double.infinity,
                      padding: EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Color(0xFFEEE2D3),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.grey.shade300),
                      ),
                      child: Column(
                        children: [
                          Center(
                            child: Text(
                              "About",
                              style: GoogleFonts.poppins(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                          SizedBox(height: 8),
                          Text(
                            description ?? '',
                            style: GoogleFonts.poppins(fontSize: 14),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),

    );
  }

  Widget _buildDetailText(String label, String? value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Center(
        child: Text(
          "$label: ${value ?? 'Not available'}",
          style: GoogleFonts.poppins(fontSize: 14),
          textAlign: TextAlign.center,
        ),
      ),
    );
  }
}
