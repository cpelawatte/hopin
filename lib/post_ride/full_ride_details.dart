import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:lottie/lottie.dart';
import 'package:geocoding/geocoding.dart';
import '../user_home/user_profile.dart';
import 'add_vehicle.dart';
import 'package:hopin/success_msgs/success_ride_post.dart';
import 'package:hopin/my_rides/myrides.dart';
import 'package:hopin/book_a_ride/search_location.dart';
import 'package:hopin/inbox/inbox.dart';
import 'package:hopin/user_home/account_settings.dart';
import 'package:hopin/user_home/post_ride_selection.dart';
import 'package:hopin/user_home/home_page.dart';

class RideDetailsPage extends StatefulWidget {
  final String vehicleType;
  final String phoneNumber;
  final double pickupLatitude;
  final double pickupLongitude;
  final double destinationLatitude;
  final double destinationLongitude;
  final String pickupAddress;
  final String destinationAddress;
  final double distanceInKm;
  final String startDate;
  final String? endDate;
  final String occurrence;
  final List<String> selectedDays;
  final Map<String, TimeOfDay?> weeklyDayTimes;
  final String? selectedTime;
  final int maxPassengers;
  final double pricePerPassenger;

  RideDetailsPage({
    required this.vehicleType,
    required this.phoneNumber,
    required this.pickupLatitude,
    required this.pickupLongitude,
    required this.destinationLatitude,
    required this.destinationLongitude,
    required this.pickupAddress,
    required this.destinationAddress,
    required this.distanceInKm,
    required this.startDate,
    this.endDate,
    required this.occurrence,
    required this.selectedDays,
    required this.weeklyDayTimes,
    this.selectedTime,
    required this.maxPassengers,
    required this.pricePerPassenger,
  });

  @override
  State<RideDetailsPage> createState() => _RideDetailsPageState();
}

class _RideDetailsPageState extends State<RideDetailsPage> {
  bool womenOnly = false;
  bool showWomenOnlyOption = false;
  bool petFriendly = false;
  String? selectedVehicle;
  List<String> vehicleList = [];
  String pickupLocationName = "Fetching location...";

  @override
  void initState() {
    super.initState();
    fetchVehicles();
    _getPickupLocationName();
    checkUserGender();
  }

  void fetchVehicles() async {
    final dbRef = FirebaseDatabase.instance.ref().child('Vehicles');
    try {
      DatabaseEvent event = await dbRef.once();
      final data = event.snapshot.value;

      if (data != null && data is Map<dynamic, dynamic>) {
        Set<String> userVehicles = {};

        data.forEach((key, value) {
          if (value is Map &&
              value.containsKey('phoneNumber') &&
              value.containsKey('vehicleType') &&
              value.containsKey('vehicleName') &&
              value.containsKey('vehicleNumber')) {

            final phoneMatches = value['phoneNumber'].toString() == widget.phoneNumber;
            final typeMatches = value['vehicleType'].toString().toLowerCase() == widget.vehicleType.toLowerCase();

            if (phoneMatches && typeMatches) {
              String vehicleName = value['vehicleName'].toString();
              String vehicleNumber = value['vehicleNumber'].toString();
              userVehicles.add("$vehicleName ($vehicleNumber)");
            }
          }
        });

        setState(() {
          vehicleList = userVehicles.toList();
          selectedVehicle = vehicleList.isNotEmpty ? vehicleList.first : null;
        });
      } else {
        setState(() {
          vehicleList = [];
          selectedVehicle = null;
        });
      }
    } catch (e) {
      print("Error fetching vehicles: $e");
      setState(() {
        vehicleList = [];
        selectedVehicle = null;
      });
    }
  }

  void _getPickupLocationName() async {
    try {
      List<Placemark> placemarks = await placemarkFromCoordinates(widget.pickupLatitude, widget.pickupLongitude);
      if (placemarks.isNotEmpty) {
        setState(() {
          pickupLocationName = placemarks[0].name ?? "Unknown location";
        });
      }
    } catch (e) {
      print("Error fetching pickup location name: $e");
    }
  }

  void checkUserGender() async {
    final dbRef = FirebaseDatabase.instance.ref().child('Users');
    try {
      DatabaseEvent event = await dbRef.orderByChild('phone').equalTo(widget.phoneNumber).once();
      final data = event.snapshot.value as Map<dynamic, dynamic>?;

      if (data != null) {
        data.forEach((key, value) {
          String gender = (value['gender'] ?? '').toString().toLowerCase();
          if (gender == 'female') {
            setState(() {
              showWomenOnlyOption = true;
            });
          }
        });
      }
    } catch (e) {
      print("Error fetching user gender: $e");
    }
  }

  void saveRideToDatabase() async {
    final dbRef = FirebaseDatabase.instance.ref().child('Rides');
    final rideRef = dbRef.push(); // This will generate a unique ID for the ride
    String rideId = rideRef.key!; // The rideId generated by Firebase

    try {
      // Save the ride data under the generated rideId
      await rideRef.set({
        'vehicleType': widget.vehicleType,
        'phoneNumber': widget.phoneNumber,
        'pickupLatitude': widget.pickupLatitude,
        'pickupLongitude': widget.pickupLongitude,
        'destinationLatitude': widget.destinationLatitude,
        'destinationLongitude': widget.destinationLongitude,
        'pickupAddress': widget.pickupAddress,
        'destinationAddress': widget.destinationAddress,
        'distanceInKm': widget.distanceInKm,
        'startDate': widget.startDate,
        'endDate': widget.endDate ?? '',
        'occurrence': widget.occurrence,
        'selectedDays': widget.selectedDays,
        'weeklyDayTimes': widget.weeklyDayTimes.map((key, value) => MapEntry(key, value?.format(context) ?? 'No time')),
        'selectedTime': widget.selectedTime ?? '',
        'maxPassengers': widget.maxPassengers,
        'pricePerPassenger': widget.pricePerPassenger,
        'women_only': womenOnly,
        'petFriendly': petFriendly,
        'seats_available': widget.maxPassengers,
        'rideId': rideId, // Store the rideId under the ride data
      });

      ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Ride successfully saved!"))
      );
    } catch (e) {
      print("Error saving ride: $e");
      ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Failed to save ride.")));
    }
  }

  // Keep the single buildDetailRow definition as follows
  Widget buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: RichText(
        text: TextSpan(
          text: '$label: ',
          style: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.black),
          children: [
            TextSpan(
              text: value,
              style: GoogleFonts.poppins(fontSize: 14, fontWeight: FontWeight.w500, color: Colors.black),
            ),
          ],
        ),
      ),
    );
  }

  Widget buildPetFriendlyCheckbox() {
    return Row(
      children: [
        Checkbox(
          activeColor: const Color(0xff154314),
          value: petFriendly,
          onChanged: (bool? value) {
            setState(() {
              petFriendly = value ?? false;
            });
          },
        ),
        Text(
          "Pet-Friendly",
          style: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.w500),
        ),
      ],
    );
  }



  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Ride Details',
          style: GoogleFonts.poppins(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white),
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
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 30),
              Center(
                child: Lottie.network(
                  'https://lottie.host/6c687545-0600-4869-9646-d6a161698797/GxmygjnOul.json',
                  height: 150,
                  width: 150,
                ),
              ),
              const SizedBox(height: 20),
              if (showWomenOnlyOption)
                Row(
                  children: [
                    Checkbox(
                      activeColor: const Color(0xff154314),
                      value: womenOnly,
                      onChanged: (value) {
                        setState(() {
                          womenOnly = value ?? false;
                        });
                      },
                    ),
                    Text(
                      'Women only ride',
                      style: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.w500),
                    ),
                  ],
                ),
              buildPetFriendlyCheckbox(),
              const SizedBox(height: 20),
              Center(
                child:Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: const Color(0xffdcd0c0).withOpacity(0.7),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        buildDetailRow('Vehicle Type', widget.vehicleType),
                        const SizedBox(height: 10),
                        buildDetailRow('Phone Number', widget.phoneNumber),
                        const SizedBox(height: 10),
                        buildDetailRow('Pickup Address', pickupLocationName),
                        const SizedBox(height: 10),
                        buildDetailRow('Destination Address', widget.destinationAddress),
                        const SizedBox(height: 10),
                        buildDetailRow('Distance', '${widget.distanceInKm.toStringAsFixed(2)} km'),
                        const SizedBox(height: 10),
                        buildDetailRow('Start Date', widget.startDate),
                        // Show End Date only if occurrence is NOT "One Time"
                        if (widget.occurrence != 'One Time' && widget.endDate != null)
                          buildDetailRow('End Date', widget.endDate!),
                        const SizedBox(height: 10),
                        buildDetailRow('Seats Available', widget.maxPassengers.toString()),
                        const SizedBox(height: 10),
                        buildDetailRow('Price per Passenger', 'Rs.${widget.pricePerPassenger.toStringAsFixed(2)}'),
                        const SizedBox(height: 10),
                        buildDetailRow('Ride Occurrence', widget.occurrence),
                        if (widget.occurrence != 'One Time' && widget.endDate != null)
                          buildDetailRow('Selected Days', widget.selectedDays.join(', ')),
                        const SizedBox(height: 10),
                        buildDetailRow('Selected Time', widget.selectedTime ?? 'No specific time selected'),
                      ],
                    ) ,
                 ),

              ),
              const SizedBox(height: 20),
              Text('Select a Vehicle:', style: GoogleFonts.poppins(fontSize: 18)),
              const SizedBox(height: 10),

              DropdownButtonFormField<String>(
                value: selectedVehicle,
                items: vehicleList.isNotEmpty
                    ? vehicleList.map((vehicle) {
                  return DropdownMenuItem<String>(
                    value: vehicle,
                    child: Text(vehicle, style: GoogleFonts.poppins(fontSize: 16)),
                  );
                }).toList()
                    : [],
                onChanged: vehicleList.isEmpty
                    ? null
                    : (value) {
                  setState(() {
                    selectedVehicle = value;
                  });
                },
                decoration: InputDecoration(
                  border: OutlineInputBorder(),
                  contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  hintText: vehicleList.isEmpty ? "No vehicles available" : "Select a vehicle",
                ),
              ),


              const SizedBox(height: 20),
              Center(
                child: ElevatedButton(
                  onPressed: () async {
                    saveRideToDatabase();
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => RideSuccessScreen(phoneNumber: widget.phoneNumber),
                      ),
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xff154314),
                    padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 24),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: Text(
                    'Confirm Ride',
                    style: GoogleFonts.poppins(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
