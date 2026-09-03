import 'dart:io';
import 'package:firebase_database/firebase_database.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'home_page.dart';

class UpdateProfilePage extends StatefulWidget {
  final String phoneNumber;
  const UpdateProfilePage({Key? key, required this.phoneNumber}) : super(key: key);

  @override
  _UpdateProfilePageState createState() => _UpdateProfilePageState();
}

class _UpdateProfilePageState extends State<UpdateProfilePage> {
  final DatabaseReference databaseRef = FirebaseDatabase.instance.ref().child("users");
  final ImagePicker _picker = ImagePicker();

  String? userKey;
  File? _imageFile;
  String? profileImageUrl;

  TextEditingController usernameController = TextEditingController();
  TextEditingController emailController = TextEditingController();
  TextEditingController passwordController = TextEditingController();
  TextEditingController phoneController = TextEditingController();
  TextEditingController ageController = TextEditingController();
  String selectedGender = "Male"; // Default gender

  @override
  void initState() {
    super.initState();
    fetchUserData();
  }

  // 🔹 Fetch user details using phone number
  void fetchUserData() async {
    DatabaseEvent event = await databaseRef.once();
    Map<dynamic, dynamic>? users = event.snapshot.value as Map<dynamic, dynamic>?;

    if (users != null) {
      users.forEach((key, value) {
        if (value['phone'] == widget.phoneNumber) {
          setState(() {
            userKey = key;
            usernameController.text = value['username'] ?? "";
            emailController.text = value['email'] ?? "";
            passwordController.text = value['password'] ?? "";
            phoneController.text = value['phone'] ?? "";
            ageController.text = value['age']?.toString() ?? "";
            selectedGender = value['gender'] ?? "Male";
            profileImageUrl = value['profileImage'] ?? "assets/images/account_profile.jpg"; // Set default image
          });
        }
      });
    }
  }

  // 🔹 Validate email format
  bool isValidEmail(String email) {
    final emailRegex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
    return emailRegex.hasMatch(email);
  }

  // 🔹 Validate phone number format (+94xxxxxxxxx for Sri Lanka)
  bool isValidPhone(String phone) {
    final phoneRegex = RegExp(r'^\+94\d{9}$');
    return phoneRegex.hasMatch(phone);
  }

  // 🔹 Function to pick an image
  Future<void> pickImage() async {
    final pickedFile = await _picker.pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      setState(() {
        _imageFile = File(pickedFile.path);
      });
    }
  }

  // 🔹 Function to update Firebase Database
  Future<void> updateUserProfile() async {
    if (!isValidEmail(emailController.text)) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Invalid email format!")));
      return;
    }
    if (!isValidPhone(phoneController.text)) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Invalid phone number! Use +94XXXXXXXXX format.")));
      return;
    }

    Map<String, dynamic> updatedData = {
      "username": usernameController.text,
      "email": emailController.text,
      "password": passwordController.text,
      "phone": phoneController.text,
      "age": int.tryParse(ageController.text) ?? 0,
      "gender": selectedGender,
    };

    if (_imageFile != null) {
      // 🔹 Upload profile picture to Firebase Storage
      String fileName = "profile_${widget.phoneNumber}.jpg";
      Reference storageRef = FirebaseStorage.instance.ref().child("profile_pictures/$fileName");

      UploadTask uploadTask = storageRef.putFile(_imageFile!);
      TaskSnapshot snapshot = await uploadTask;
      String imageUrl = await snapshot.ref.getDownloadURL();
      updatedData["profileImage"] = imageUrl;
    }

    // 🔹 Update database
    if (userKey != null) {
      await databaseRef.child(userKey!).update(updatedData);
      setState(() {
        profileImageUrl = updatedData["profileImage"]; // Update UI with new image
      });
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Profile updated successfully!")));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Update Profile"),
        leading: IconButton(
          icon: Icon(Icons.arrow_back),
          onPressed: () {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (context) => HomePage(phoneNumber: widget.phoneNumber)),
            );
          },
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              GestureDetector(
                onTap: pickImage,
                child: CircleAvatar(
                  radius: 50,
                  backgroundImage: _imageFile != null
                      ? FileImage(_imageFile!)
                      : (profileImageUrl != null && profileImageUrl!.startsWith("http")
                          ? NetworkImage(profileImageUrl!)
                          : AssetImage("assets/images/account_profile.jpg") as ImageProvider),
                  child: _imageFile == null && profileImageUrl == null
                      ? Icon(Icons.person, size: 50, color: Colors.grey)
                      : null,
                ),
              ),
              SizedBox(height: 20),
              TextField(controller: usernameController, decoration: InputDecoration(labelText: "Username")),
              TextField(controller: emailController, decoration: InputDecoration(labelText: "Email")),
              TextField(controller: passwordController, decoration: InputDecoration(labelText: "Password"), obscureText: true),
              TextField(controller: phoneController, decoration: InputDecoration(labelText: "Phone")),
              TextField(controller: ageController, decoration: InputDecoration(labelText: "Age"), keyboardType: TextInputType.number),
              DropdownButton<String>(
                value: selectedGender,
                items: ["Male", "Female", "Other"].map((gender) {
                  return DropdownMenuItem<String>(value: gender, child: Text(gender));
                }).toList(),
                onChanged: (value) {
                  setState(() {
                    selectedGender = value!;
                  });
                },
              ),
              SizedBox(height: 20),
              ElevatedButton(
                onPressed: updateUserProfile,
                child: Text("Update Profile"),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
