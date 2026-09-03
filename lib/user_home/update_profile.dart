import 'dart:io';
import 'package:firebase_database/firebase_database.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:hopin/user_home/user_profile.dart';
import 'package:image_picker/image_picker.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart'; // Import for date formatting
import 'package:hopin/my_rides/myrides.dart';
import 'package:hopin/book_a_ride/search_location.dart';
import 'package:hopin/inbox/inbox.dart';
import 'package:hopin/user_home/account_settings.dart';
import 'package:hopin/user_home/post_ride_selection.dart';
import 'package:hopin/user_home/home_page.dart';

class UpdateProfilePage extends StatefulWidget {
  final String phoneNumber; // Identify the user

  UpdateProfilePage({required this.phoneNumber});

  @override
  _UpdateProfilePageState createState() => _UpdateProfilePageState();
}

class _UpdateProfilePageState extends State<UpdateProfilePage> {
  final ImagePicker _picker = ImagePicker();
  File? _imageFile;
  String? profileImageUrl;
  TextEditingController _usernameController = TextEditingController();
  TextEditingController _emailController = TextEditingController();
  TextEditingController _phoneNumberController = TextEditingController();

  // New description controller
  TextEditingController _descriptionController = TextEditingController();
  TextEditingController _currentPasswordController = TextEditingController();
  TextEditingController _newPasswordController = TextEditingController();
  TextEditingController _confirmPasswordController = TextEditingController();

  int _passwordRetryCount = 0;
  bool _isPasswordEditable = true; // Initially allow password changes
  DateTime? _lastFailedAttempt; // Track the last failed password attempt
  bool _incorrectPasswordAttempted = false; // Flag to track incorrect password attempts

  String? _selectedDisability;
  bool _requireAssistance = false;

  @override
  void initState() {
    super.initState();
    _loadUserDetails();
    _phoneNumberController.text = widget.phoneNumber; // Lock phone number
  }

  // Fetch user details from Firebase, including description if available
  Future<void> _loadUserDetails() async {
    DatabaseReference userRef = FirebaseDatabase.instance.ref().child('Users');

    userRef.once().then((DatabaseEvent event) {
      if (event.snapshot.exists) {
        Map<dynamic, dynamic> users = event.snapshot.value as Map;
        users.forEach((key, value) {
          if (value['phone'] == widget.phoneNumber) {
            setState(() {
              _usernameController.text = value['username'] ?? 'No username';
              _emailController.text = value['email'] ?? 'No email';
              profileImageUrl = value['profileImageUrl'];
              // Load description if it exists
              _descriptionController.text = value['description'] ?? '';
            });
          }
        });
      } else {
        print("No user found with this phone number.");
      }
    }).catchError((error) {
      print("Error loading user details: $error");
    });
  }

  Future<void> _pickImage() async {
    final pickedFile = await _picker.pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      setState(() {
        _imageFile = File(pickedFile.path);
      });
    }
  }

  Future<void> _uploadImageToFirebase() async {
    if (_imageFile == null) return;

    try {
      String fileName = "profile_pictures/user_${DateTime
          .now()
          .millisecondsSinceEpoch}.jpg";
      Reference ref = FirebaseStorage.instance.ref().child(fileName);
      UploadTask uploadTask = ref.putFile(_imageFile!);

      TaskSnapshot snapshot = await uploadTask;
      String downloadUrl = await snapshot.ref.getDownloadURL();

      setState(() {
        profileImageUrl = downloadUrl;
      });

      ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Profile picture updated!")));
    } catch (e) {
      print("Error uploading image: $e");
    }
  }

  Future<void> _updateUserDetails() async {
    DatabaseReference userRef = FirebaseDatabase.instance.ref().child('Users');
    DataSnapshot snapshot = await userRef.get();

    if (snapshot.exists && snapshot.value is Map) {
      Map users = snapshot.value as Map;
      String userKey = '';

      users.forEach((key, value) {
        if (value['phone'] == widget.phoneNumber) {
          userKey = key;
        }
      });

      if (userKey.isNotEmpty) {
        // Prepare update data
        Map<String, dynamic> updatedData = {
          'username': _usernameController.text,
          'email': _emailController.text,
          'profileImageUrl': profileImageUrl,
          'description': _descriptionController.text,
        };

        // Only add disability if something other than "Select" is chosen
        if (_selectedDisability != null && _selectedDisability != 'Select') {
          updatedData['disability'] = _selectedDisability!;
        } else {
          // Optionally, remove disability field if user deselects
          updatedData['disability'] = null;
        }

        // Add assistance requirement regardless of disability
        updatedData['assistenceRequired'] = _requireAssistance;

        await userRef.child(userKey).update(updatedData);

        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text("Profile updated!"))
        );
      }
    }
  }


  Future<double> _getAverageRating(String phoneNumber) async {
    DatabaseReference ratingsRef = FirebaseDatabase.instance.ref(
        'ratings/$phoneNumber');
    DataSnapshot snapshot = await ratingsRef.get();
    if (!snapshot.exists) return 0.0;
    double total = 0;
    int count = 0;
    for (var child in snapshot.children) {
      var data = child.value as Map<dynamic, dynamic>;
      if (data.containsKey('rating')) {
        total += (data['rating'] as num).toDouble();
        count++;
      }
    }
    return count == 0 ? 0.0 : total / count;
  }


  // Function to clear fields before showing the popup
  void _clearPasswordFields() {
    _currentPasswordController.clear();
    _newPasswordController.clear();
    _confirmPasswordController.clear();
  }

  Future<void> _showPasswordPopup() async {
    _clearPasswordFields();

    if (_incorrectPasswordAttempted) {
      ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Incorrect password, please try again!")));
      _incorrectPasswordAttempted = false;
    }

    if (_passwordRetryCount >= 3) {
      if (_lastFailedAttempt != null && DateTime
          .now()
          .difference(_lastFailedAttempt!)
          .inMinutes < 10) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(
            "Maximum attempts reached. Try again in 10 minutes.")));
        return;
      } else {
        setState(() {
          _passwordRetryCount = 0;
        });
      }
    }

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text("Change Password",
              style: GoogleFonts.poppins(fontWeight: FontWeight.w600)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: _currentPasswordController,
                obscureText: true,
                decoration: InputDecoration(labelText: "Current Password"),
              ),
              TextField(
                controller: _newPasswordController,
                obscureText: true,
                decoration: InputDecoration(labelText: "New Password"),
              ),
              TextField(
                controller: _confirmPasswordController,
                obscureText: true,
                decoration: InputDecoration(labelText: "Confirm New Password"),
              ),
              SizedBox(height: 16),
              ElevatedButton(
                onPressed: () async {
                  String currentPassword = _currentPasswordController.text
                      .trim();
                  String newPassword = _newPasswordController.text.trim();
                  String confirmPassword = _confirmPasswordController.text
                      .trim();

                  DatabaseReference userRef = FirebaseDatabase.instance
                      .ref()
                      .child('Users');
                  DataSnapshot snapshot = await userRef.get();

                  if (snapshot.exists && snapshot.value is Map) {
                    Map users = snapshot.value as Map;
                    String userKey = '';
                    String? actualPassword;

                    users.forEach((key, value) {
                      if (value['phone'] == widget.phoneNumber) {
                        userKey = key;
                        actualPassword = value['password']?.toString()?.trim();
                      }
                    });

                    if (userKey.isEmpty) {
                      ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text("User not found!")));
                      return;
                    }

                    if (currentPassword == actualPassword) {
                      if (newPassword == confirmPassword) {
                        await userRef.child(userKey).update({
                          'password': newPassword,
                        });

                        ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text(
                                "Password updated successfully!")));
                        Navigator.of(context).pop(); // Close the popup
                      } else {
                        ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text(
                                "New passwords do not match!")));
                      }
                    } else {
                      setState(() {
                        _passwordRetryCount++;
                        _lastFailedAttempt = DateTime.now();
                        _incorrectPasswordAttempted = true;
                      });

                      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                          content: Text("Incorrect current password!")));
                      Navigator.of(context).pop();
                    }
                  } else {
                    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                        content: Text("No users found in the database!")));
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Color(0xFF5E6D3A),
                  padding: EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: Text(
                  "Update Password",
                  style: GoogleFonts.poppins(
                    fontSize: 13,
                    color: Color(0xFFEFE5DC),
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<double>(
      future: _getAverageRating(_phoneNumberController.text),
      builder: (context, snapshot) {
        double averageRating = snapshot.data ?? 0.0;

        return Scaffold(
          backgroundColor: Color(0xFFEFE5DC),
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
          appBar: AppBar(
            backgroundColor: Color(0xFF154314),
            title: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  "Update Profile",
                  style: GoogleFonts.poppins(
                    fontSize: 18,
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                Row(
                  children: [
                    Icon(Icons.star, color: Colors.amberAccent, size: 20),
                    SizedBox(width: 4),
                    Text(
                      averageRating.toStringAsFixed(1),
                      style: GoogleFonts.poppins(
                        fontSize: 16,
                        color: Colors.white,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ],
            ),
            leading: IconButton(
              icon: Icon(Icons.arrow_back, color: Colors.white),
              onPressed: () => Navigator.pop(context),
            ),
          ),
          body: SingleChildScrollView(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              children: [
                GestureDetector(
                  onTap: _pickImage,
                  child: Stack(
                    alignment: Alignment.bottomRight,
                    children: [
                      Padding(
                        padding: const EdgeInsets.only(top: 16.0),
                        child: CircleAvatar(
                          radius: 60,
                          backgroundColor: Colors.white,
                          backgroundImage: profileImageUrl != null
                              ? NetworkImage(profileImageUrl!)
                              : AssetImage(
                              "assets/images/user.png") as ImageProvider,
                        ),
                      ),
                      Icon(Icons.camera_alt, color: Colors.white),
                    ],
                  ),
                ),
                SizedBox(height: 8),
                ElevatedButton(
                  onPressed: _uploadImageToFirebase,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Color(0xFF5E6D3A),
                    padding: EdgeInsets.symmetric(vertical: 8, horizontal: 9),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: Text(
                    "Upload Profile Picture",
                    style: GoogleFonts.poppins(
                      fontSize: 10,
                      color: Color(0xFFEFE5DC),
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
                SizedBox(height: 16),
                TextField(
                  controller: _usernameController,
                  decoration: InputDecoration(labelText: "Username"),
                ),
                SizedBox(height: 16),
                TextField(
                  controller: _emailController,
                  decoration: InputDecoration(labelText: "Email"),
                ),
                SizedBox(height: 16),
                TextField(
                  controller: _phoneNumberController,
                  decoration: InputDecoration(labelText: "Phone Number"),
                  readOnly: true,
                ),
                SizedBox(height: 16),
                TextField(
                  controller: _descriptionController,
                  decoration: InputDecoration(
                    labelText: "About Yourself",
                    hintText: "Enter a short description (max 150 words) about your interests, music taste, etc.",
                    border: OutlineInputBorder(),
                  ),
                  maxLines: 5,
                ),

                // Disability Dropdown
                SizedBox(height: 16),
                DropdownButtonFormField<String>(
                  value: _selectedDisability,
                  items: [
                    DropdownMenuItem(child: Text("Select", style: GoogleFonts.poppins()), value: null),
                    DropdownMenuItem(child: Text("Hearing Impairment", style: GoogleFonts.poppins()), value: "Hearing Impairment"),
                    DropdownMenuItem(child: Text("Vision Impairment", style: GoogleFonts.poppins()), value: "Vision Impairment"),
                    DropdownMenuItem(child: Text("Mobility Disability", style: GoogleFonts.poppins()), value: "Mobility Disability"),
                    DropdownMenuItem(child: Text("Speech Impairment", style: GoogleFonts.poppins()), value: "Speech Impairment"),
                    DropdownMenuItem(child: Text("Cognitive Disability", style: GoogleFonts.poppins()), value: "Cognitive Disability"),
                    DropdownMenuItem(child: Text("Mental Health Condition", style: GoogleFonts.poppins()), value: "Mental Health Condition"),
                    DropdownMenuItem(child: Text("Other", style: GoogleFonts.poppins()), value: "Other"),
                  ],
                  decoration: InputDecoration(
                    labelText: "Disability",
                    labelStyle: GoogleFonts.poppins(),
                    border: OutlineInputBorder(),
                  ),
                  onChanged: (value) {
                    setState(() {
                      _selectedDisability = value;
                    });
                  },
                ),

// Require Assistance Checkbox
                SizedBox(height: 16),
                CheckboxListTile(
                  title: Text(
                    "Require Assistance",
                    style: GoogleFonts.poppins(fontSize: 14),
                  ),
                  value: _requireAssistance,
                  onChanged: (bool? value) {
                    setState(() {
                      _requireAssistance = value ?? false;
                    });
                  },
                  activeColor: Color(0xFF154314),
                  checkColor: Color(0xFFEFE5DC),
                  controlAffinity: ListTileControlAffinity.leading,
                ),
                SizedBox(height: 30),
                ElevatedButton(
                  onPressed: _isPasswordEditable ? _showPasswordPopup : null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red,
                    padding: EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    minimumSize: Size(200, 0),
                  ),
                  child: Text(
                    "Change Password",
                    style: GoogleFonts.poppins(
                      fontSize: 13,
                      color: Colors.white,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
                SizedBox(height: 45),
                ElevatedButton(
                  onPressed: _updateUserDetails,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Color(0xFF154314),
                    padding: EdgeInsets.symmetric(vertical: 16, horizontal: 98),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    minimumSize: Size(200, 0),
                  ),
                  child: Text(
                    "Update Profile",
                    style: GoogleFonts.poppins(
                      fontSize: 16,
                      color: Color(0xFFEFE5DC),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
