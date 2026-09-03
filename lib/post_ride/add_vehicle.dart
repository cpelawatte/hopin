import 'dart:io';
import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:hopin/inbox/inbox.dart';
import 'package:hopin/user_home/account_settings.dart';
import 'package:hopin/user_home/post_ride_selection.dart';
import 'package:hopin/user_home/home_page.dart';

import '../my_rides/myrides.dart';
import '../user_home/user_profile.dart';

class AddVehiclePage extends StatefulWidget {
  final String phoneNumber;

  AddVehiclePage({required this.phoneNumber});

  @override
  _AddVehiclePageState createState() => _AddVehiclePageState();
}

class _AddVehiclePageState extends State<AddVehiclePage> {
  final _formKey = GlobalKey<FormState>();
  final _vehicleNameController = TextEditingController();
  final _vehicleNumberController = TextEditingController();

  String? selectedVehicleType;
  File? driverLicenseImage;
  File? vehicleLicenseImage;

  final List<String> vehicleTypes = [
    'Standard Car',
    'Premier Car',
    'Jeep',
    'Minivan',
    'Van',
  ];


  final picker = ImagePicker();

  Future<void> pickImage(bool isDriverLicense) async {
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);

    if (pickedFile != null) {
      final file = File(pickedFile.path);
      final fileName = file.path.toLowerCase();

      if (!(fileName.endsWith('.jpg') || fileName.endsWith('.jpeg') || fileName.endsWith('.png')) || fileName.contains('.exe')) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Invalid file type or suspicious file. Please upload JPG, JPEG, or PNG only.')),
        );
        return;
      }

      setState(() {
        if (isDriverLicense) {
          driverLicenseImage = file;
        } else {
          vehicleLicenseImage = file;
        }
      });
    }
  }

  Future<String> uploadImage(File imageFile, String fileName) async {
    final ref = FirebaseStorage.instance.ref().child('vehicle_licenses/${widget.phoneNumber}_$fileName');
    await ref.putFile(imageFile);
    final downloadUrl = await ref.getDownloadURL();
    return downloadUrl;
  }

  Future<bool> checkIfUserExists() async {
    final ref = FirebaseDatabase.instance.ref().child('Users');
    final snapshot = await ref.orderByChild("phone").equalTo(widget.phoneNumber).get();

    return snapshot.exists; // Returns true if the user exists, false otherwise
  }

  void saveVehicle() async {
    if (_formKey.currentState!.validate() &&
        selectedVehicleType != null &&
        driverLicenseImage != null &&
        vehicleLicenseImage != null) {

      bool userExists = await checkIfUserExists();
      if (!userExists) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('User not found. Please register before adding a vehicle.')),
        );
        return;
      }

      try {
        final driverLicenseUrl = await uploadImage(driverLicenseImage!, 'driver_license');
        final vehicleLicenseUrl = await uploadImage(vehicleLicenseImage!, 'vehicle_license');

        String requestDate = "${DateTime.now().year}-${DateTime.now().month.toString().padLeft(2, '0')}-${DateTime.now().day.toString().padLeft(2, '0')}";


        DatabaseReference vehicleRequestRef = FirebaseDatabase.instance.ref().child('Vehicle_requests').push();
        await vehicleRequestRef.set({
          'vehicleName': _vehicleNameController.text.trim().toUpperCase(),
          'vehicleNumber': _vehicleNumberController.text.trim().toUpperCase(),
          'vehicleType': selectedVehicleType,
          'phoneNumber': widget.phoneNumber,
          'driverLicenseUrl': driverLicenseUrl,
          'vehicleLicenseUrl': vehicleLicenseUrl,
          'request_date': requestDate,  // Add the current date to the request
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Vehicle request submitted successfully!')),
        );
        Navigator.pop(context);
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error occurred: $e')),
        );
      }
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Please fill all details and upload both licenses.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        centerTitle: true,
        title: Text(
          'Add New Vehicle',
          style: GoogleFonts.poppins(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: const Color(0xff154314),
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
      body: Container(
        color: const Color(0xffefe5dc),
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                TextFormField(
                  controller: _vehicleNameController,
                  decoration: InputDecoration(labelText: 'Vehicle Name'),
                  validator: (value) => value == null || value.isEmpty
                      ? 'Please enter vehicle name'
                      : null,
                  style: GoogleFonts.poppins(),
                ),
                SizedBox(height: 25),
                TextFormField(
                  controller: _vehicleNumberController,
                  decoration: InputDecoration(labelText: 'Vehicle Number (i.e: CAA-6363)'),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter vehicle number';
                    }
                    final pattern = RegExp(r'^[A-Za-z]{2,3}-[0-9]{4}$');
                    if (!pattern.hasMatch(value)) {
                      return 'Format must be like CAA-1234 or KL-1234';
                    }
                    return null;
                  },
                  style: GoogleFonts.poppins(),
                ),
                SizedBox(height: 25),
                DropdownButtonFormField<String>(
                  decoration: InputDecoration(labelText: 'Vehicle Type'),
                  value: selectedVehicleType,
                  items: vehicleTypes.map((type) {
                    return DropdownMenuItem<String>(
                      value: type,
                      child: Text(
                        type,
                        style: GoogleFonts.poppins(color: Colors.black),
                      ),
                    );
                  }).toList(),
                  onChanged: (value) => setState(() => selectedVehicleType = value),
                  validator: (value) => value == null
                      ? 'Please select a vehicle type'
                      : null,
                  style: GoogleFonts.poppins(),
                ),
                SizedBox(height: 20),
                Text('Upload Driver License Image:',
                    style: GoogleFonts.poppins(fontWeight: FontWeight.w500)),
                SizedBox(height: 12),
                GestureDetector(
                  onTap: () => pickImage(true),
                  child: Container(
                    height: 150,
                    width: double.infinity,
                    color: Colors.grey[300],
                    child: driverLicenseImage != null
                        ? Image.file(driverLicenseImage!, fit: BoxFit.cover)
                        : Center(child: Text('Tap to upload driver license')),
                  ),
                ),
                SizedBox(height: 20),
                Text('Upload Vehicle License Image:',
                    style: GoogleFonts.poppins(fontWeight: FontWeight.w500)),
                SizedBox(height: 12),
                GestureDetector(
                  onTap: () => pickImage(false),
                  child: Container(
                    height: 150,
                    width: double.infinity,
                    color: Colors.grey[300],
                    child: vehicleLicenseImage != null
                        ? Image.file(vehicleLicenseImage!, fit: BoxFit.cover)
                        : Center(child: Text('Tap to upload vehicle license')),
                  ),
                ),
                SizedBox(height: 35),
                Center(
                  child: ElevatedButton(
                    onPressed: saveVehicle,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xff154314), // Background color
                      padding: EdgeInsets.symmetric(vertical: 16, horizontal: 32), // Padding
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8), // Border radius
                      ),
                    ),
                    child: Text(
                      'Save Vehicle',
                      style: GoogleFonts.poppins(
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                        fontSize: 16,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
