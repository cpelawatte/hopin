import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:hopin/post_ride/full_ride_details.dart';
import 'package:lottie/lottie.dart';
import 'package:hopin/inbox/inbox.dart';
import 'package:hopin/user_home/account_settings.dart';
import 'package:hopin/user_home/post_ride_selection.dart';
import 'package:hopin/user_home/home_page.dart';

import '../my_rides/myrides.dart';
import '../user_home/user_profile.dart';


class SetUpPage extends StatefulWidget {
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

  SetUpPage({
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
  });

  @override
  _SetUpPageState createState() => _SetUpPageState();
}

class _SetUpPageState extends State<SetUpPage> {
  int? maxPassengers = 1;

  Map<String, int> vehicleMaxPassengers = {
    'standard car': 4,
    'premier car': 4,
    'jeep': 6,
    'minivan': 8,
    'van': 10,
  };

  double calculatePricePerPassenger(double totalDistance, String vehicleType) {
    double baseFare = 100;
    double pricePerPerson = 0.0;
    double carTypeRate = 0.0;
    double distanceRate = 0.0;

    switch (vehicleType.toLowerCase()) {
      case 'standard car':
        carTypeRate = 1.0;
        break;
      case 'premier car':
        carTypeRate = 1.2;
        break;
      case 'jeep':
        carTypeRate = 1.4;
        break;
      case 'minivan':
        carTypeRate = 1.6;
        break;
      case 'van':
        carTypeRate = 1.8;
        break;
      default:
        carTypeRate = 0;
        break;
    }

    if (totalDistance < 3) {
      pricePerPerson = 100;
    } else if (totalDistance >= 3 && totalDistance < 7) {
      distanceRate = 60;
    } else if (totalDistance >= 7 && totalDistance < 10) {
      distanceRate = 50;
    } else if (totalDistance >= 10 && totalDistance < 15) {
      distanceRate = 40;
    } else if (totalDistance >= 15 && totalDistance < 30) {
      distanceRate = 30;
    } else if (totalDistance >= 30) {
      distanceRate = 20;
    }

    pricePerPerson = (baseFare + (totalDistance * distanceRate)) * carTypeRate;
    return pricePerPerson;
  }

  @override
  Widget build(BuildContext context) {
    double pricePerPassenger = calculatePricePerPassenger(widget.distanceInKm, widget.vehicleType);
    int maxAllowedPassengers = vehicleMaxPassengers[widget.vehicleType.toLowerCase()] ?? 4;

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        centerTitle: true,
        title: Text(
          'Set cost details',
          style: GoogleFonts.poppins(fontSize: 20, fontWeight: FontWeight.w600, color: Colors.white),
        ),
        backgroundColor: Color(0xff154314),
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
      body:
      Padding(
        padding: const EdgeInsets.all(18.0),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(height: 30),
              Center(
                child: Lottie.network(
                  'https://lottie.host/6c687545-0600-4869-9646-d6a161698797/GxmygjnOul.json',
                  height: 150,
                  width: 150,
                ),
              ),
              SizedBox(height: 20),
              Center(
                 child:
                 Container(
                   padding: EdgeInsets.all(15),
                   decoration: BoxDecoration(
                     color: Color(0xffdcd0c0).withOpacity(0.7),
                     borderRadius: BorderRadius.circular(8),
                   ),
                   child: Column(
                     crossAxisAlignment: CrossAxisAlignment.start,
                     children: [
                       Text('Vehicle Type: ${widget.vehicleType}', style: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.w500)),
                       SizedBox(height: 25),
                       Text('Distance: ${widget.distanceInKm.toStringAsFixed(2)} km', style: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.w500)),
                     ],
                   ),
                 ),
              ),
              SizedBox(height: 35),
              Center(
                child: Container(
                  padding: EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Color(0xffdcd0c0).withOpacity(0.7),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Column(
                    children: [
                      Text('Price Per Passenger', style: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.bold)),
                      SizedBox(height: 8),
                      Text('Rs.${pricePerPassenger.toStringAsFixed(2)}', style: GoogleFonts.poppins(fontSize: 22, fontWeight: FontWeight.bold)),
                    ],
                  ),
                ),
              ),
              SizedBox(height: 35),
              Center(
                child: Column(
                  children: [
                    Text('Max Passengers', style: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.w600)),
                    SizedBox(height: 10),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        IconButton(
                          icon: Icon(Icons.remove),
                          onPressed: () {
                            setState(() {
                              if (maxPassengers! > 1) maxPassengers = maxPassengers! - 1;
                            });
                          },
                        ),
                        Container(
                          decoration: BoxDecoration(
                            color: Color(0xffefe5dc).withOpacity(0.7),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          padding: EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                          child: Text(
                            '$maxPassengers',
                            style: GoogleFonts.poppins(fontSize: 18),
                          ),
                        ),
                        IconButton(
                          icon: Icon(Icons.add),
                          onPressed: () {
                            setState(() {
                              if (maxPassengers! < maxAllowedPassengers) {
                                maxPassengers = maxPassengers! + 1;
                              } else {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(content: Text('Maximum passengers for this vehicle type is $maxAllowedPassengers')),
                                );
                              }
                            });
                          },
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              SizedBox(height: 40),
              Center(
                child: ElevatedButton(
                  onPressed: () {
                    if (maxPassengers != null) {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => RideDetailsPage(
                            vehicleType: widget.vehicleType,
                            phoneNumber: widget.phoneNumber,
                            pickupLatitude: widget.pickupLatitude,
                            pickupLongitude: widget.pickupLongitude,
                            destinationLatitude: widget.destinationLatitude,
                            destinationLongitude: widget.destinationLongitude,
                            pickupAddress: widget.pickupAddress,
                            destinationAddress: widget.destinationAddress,
                            distanceInKm: widget.distanceInKm,
                            startDate: widget.startDate,
                            endDate: widget.endDate,
                            occurrence: widget.occurrence,
                            selectedDays: widget.selectedDays,
                            weeklyDayTimes: widget.weeklyDayTimes,
                            selectedTime: widget.selectedTime,
                            maxPassengers: maxPassengers!,
                            pricePerPassenger: pricePerPassenger,
                          ),
                        ),
                      );
                    } else {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Please enter max passengers')),
                      );
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Color(0xff154314),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    padding: EdgeInsets.symmetric(horizontal: 32, vertical: 12),
                  ),
                  child: Text(
                    'Confirm Price',
                    style: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white),
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
