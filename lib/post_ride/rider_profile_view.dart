import 'dart:io';

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:image_picker/image_picker.dart';
import '../user_home/home_page.dart';
import 'dart:typed_data';

// Only import dart:io on mobile platforms
// Use conditional import to avoid web crashes
// dart:io is only safe to use outside web
// ignore: avoid_web_libraries_in_flutter
import 'dart:io' if (dart.library.html) 'dart:html' as html;

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
  dynamic _imageFile;
  Uint8List? webImageData;
  String? profileImageUrl;

  TextEditingController usernameController = TextEditingController();
  TextEditingController emailController = TextEditingController();
  TextEditingController passwordController = TextEditingController();
  TextEditingController phoneController = TextEditingController();
  TextEditingController ageController = TextEditingController();
  String selectedGender = "Male";

  @override
  void initState() {
    super.initState();
    fetchUserData();
  }

  void fetchUserData() async {
    DatabaseEvent event = await databaseRef.once();
    Map<dynamic, dynamic>? users = event.snapshot.value as Map?;

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
            profileImageUrl = value['profileImage'];
          });
        }
      });
    }
  }

  bool isValidEmail(String email) {
    final emailRegex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
    return emailRegex.hasMatch(email);
  }

  bool isValidPhone(String phone) {
    final phoneRegex = RegExp(r'^\+94\d{9}$');
    return phoneRegex.hasMatch(phone);
  }

  Future<void> pickImage() async {
    final pickedFile = await _picker.pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      if (kIsWeb) {
        _imageFile = pickedFile; // Use as-is for web
        webImageData = await pickedFile.readAsBytes();
      } else {
        _imageFile = File(pickedFile.path); // Use dart:io on mobile
      }
      setState(() {});
    }
  }

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
      String fileName = "profile_${widget.phoneNumber}.jpg";
      Reference storageRef = FirebaseStorage.instance.ref().child("profile_pictures/$fileName");

      UploadTask uploadTask;

      if (kIsWeb) {
        uploadTask = storageRef.putData(webImageData!);
      } else {
        uploadTask = storageRef.putFile(_imageFile);
      }

      TaskSnapshot snapshot = await uploadTask;
      String imageUrl = await snapshot.ref.getDownloadURL();
      updatedData["profileImage"] = imageUrl;
    }

    if (userKey != null) {
      await databaseRef.child(userKey!).update(updatedData);
      setState(() {
        profileImageUrl = updatedData["profileImage"];
      });
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Profile updated successfully!")));
    }
  }

  @override
  Widget build(BuildContext context) {
    ImageProvider? profileImage;
    if (_imageFile != null) {
      if (kIsWeb && webImageData != null) {
        profileImage = MemoryImage(webImageData!);
      } else if (!kIsWeb) {
        profileImage = FileImage(_imageFile);
      }
    } else if (profileImageUrl != null && profileImageUrl!.startsWith("http")) {
      profileImage = NetworkImage(profileImageUrl!);
    } else {
      profileImage = AssetImage("assets/images/account_profile.jpg");
    }

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
            children: [
              GestureDetector(
                onTap: pickImage,
                child: CircleAvatar(
                  radius: 50,
                  backgroundImage: profileImage,
                  child: (_imageFile == null && profileImageUrl == null)
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
