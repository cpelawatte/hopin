import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:hopin/post_ride/set_cost.dart';
import 'package:lottie/lottie.dart';
import 'package:hopin/inbox/inbox.dart';
import 'package:hopin/user_home/account_settings.dart';
import 'package:hopin/user_home/post_ride_selection.dart';
import 'package:hopin/user_home/home_page.dart';

import '../my_rides/myrides.dart';
import '../user_home/user_profile.dart';

class SetDatePage extends StatefulWidget {
  final String vehicleType;
  final String phoneNumber;
  final double pickupLatitude;
  final double pickupLongitude;
  final double destinationLatitude;
  final double destinationLongitude;
  final String pickupAddress;
  final String destinationAddress;
  final double distanceInKm;

  SetDatePage({
    required this.vehicleType,
    required this.phoneNumber,
    required this.pickupLatitude,
    required this.pickupLongitude,
    required this.destinationLatitude,
    required this.destinationLongitude,
    required this.pickupAddress,
    required this.destinationAddress,
    required this.distanceInKm,
  });

  @override
  _SetDatePageState createState() => _SetDatePageState();
}

class _SetDatePageState extends State<SetDatePage> {
  DateTime selectedDate = DateTime.now();
  DateTime? endDate;
  String occurrence = 'One Time';
  TimeOfDay? selectedTime;
  List<String> selectedDays = [];
  Map<String, TimeOfDay?> weeklyDayTimes = {};
  final List<String> weekDays = [
    'Monday',
    'Tuesday',
    'Wednesday',
    'Thursday',
    'Friday',
    'Saturday',
    'Sunday'
  ];

  Future<void> _selectDate(BuildContext context, {bool isEndDate = false}) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: isEndDate ? (endDate ?? selectedDate) : selectedDate,
      firstDate: DateTime.now(),
      lastDate: DateTime(2101),
      builder: (BuildContext context, Widget? child) {
        return Theme(
          data: ThemeData.light().copyWith(
            primaryColor: Color(0xFF154314), // Green for primary color
            hintColor: Color(0xFF154314),
            buttonTheme: ButtonThemeData(textTheme: ButtonTextTheme.primary),
            dialogTheme: DialogThemeData(backgroundColor: Color(0xFF154314)),
          ),
          child: child!,
        );
      },
    );
    if (picked != null) {
      setState(() {
        if (isEndDate) {
          endDate = picked;
        } else {
          selectedDate = picked;
        }
      });
    }
  }

  Future<void> _selectTime(BuildContext context, {String? day}) async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.now(),
      builder: (BuildContext context, Widget? child) {
        return Theme(
          data: ThemeData.light().copyWith(
            primaryColor: Color(0xFF154314), // Green as the primary color
            hintColor: Color(0xFF154314),
            buttonTheme: ButtonThemeData(textTheme: ButtonTextTheme.primary),
            dialogTheme: DialogThemeData(backgroundColor: Color(0xFF154314)),
          ),
          child: child!,
        );
      },
    );
    if (picked != null) {
      setState(() {
        if (day != null) {
          weeklyDayTimes[day] = picked;
        } else {
          selectedTime = picked;
        }
      });
    }
  }

  void _setDateAndTime() {
    if (selectedDate == null ||
        occurrence.isEmpty ||
        (occurrence == "Weekly" && selectedDays.isEmpty) ||
        (occurrence != "One Time" && endDate == null) ||
        (occurrence == "Weekly" &&
            selectedDays.any((day) => weeklyDayTimes[day] == null)) ||
        (occurrence != "Weekly" && selectedTime == null)) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(
          "Please fill all required fields (date, occurrence, times, and end date if applicable).",
          style: GoogleFonts.poppins(),
        ),
      ));
      return;
    }

    // Navigate to SetUpPage with all the required parameters
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => SetUpPage(
          vehicleType: widget.vehicleType,
          phoneNumber: widget.phoneNumber,
          pickupLatitude: widget.pickupLatitude,
          pickupLongitude: widget.pickupLongitude,
          destinationLatitude: widget.destinationLatitude,
          destinationLongitude: widget.destinationLongitude,
          pickupAddress: widget.pickupAddress,
          destinationAddress: widget.destinationAddress,
          distanceInKm: widget.distanceInKm,
          startDate: DateFormat('yyyy-MM-dd').format(selectedDate),
          endDate: endDate != null ? DateFormat('yyyy-MM-dd').format(endDate!) : null,
          occurrence: occurrence,
          selectedDays: selectedDays,
          weeklyDayTimes: weeklyDayTimes,
          selectedTime: selectedTime?.format(context),
        ),
      ),
    );

    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(
        "Ride date and time set!",
        style: GoogleFonts.poppins(),
      ),
    ));
  }

  @override
  Widget build(BuildContext context) {
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
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () {
            Navigator.pop(context);
          },
        ),
        backgroundColor: Color(0xFF154314),
        title: Text("Set Ride Details", style: GoogleFonts.poppins(color: Colors.white, fontWeight: FontWeight.w600)),
        centerTitle: true,
      ),

      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(height: 30),
            Center(
              child: Lottie.network(
                'https://lottie.host/6c687545-0600-4869-9646-d6a161698797/GxmygjnOul.json',
                height: 140,
                width: 150,
              ),
            ),
            SizedBox(height: 10),
            Center(
              child: Card(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
                color: Color(0xffdcd0c0).withOpacity(0.7),
                elevation: 5,
                child: Padding(
                  padding: const EdgeInsets.all(25.0),
                  child: Text(
                    "Distance: ${widget.distanceInKm.toStringAsFixed(2)} km",
                    style: GoogleFonts.poppins(fontSize: 22, fontWeight: FontWeight.bold, color: Color(0xFF154314)),
                  ),
                ),
              ),
            ),
            SizedBox(height: 40),
          Center(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "Select Ride Date",
                  style: GoogleFonts.poppins(
                      fontSize: 18, fontWeight: FontWeight.w600, color: Color(0xFF154314)),
                ),
                SizedBox(height: 10),
                GestureDetector(
                  onTap: () => _selectDate(context),
                  child: Container(
                    padding: EdgeInsets.symmetric(vertical: 16, horizontal: 20),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(15),
                      color: Color(0xffdcd0c0).withOpacity(0.7),
                    ),
                    child: Text(
                      DateFormat('yyyy-MM-dd').format(selectedDate),
                      style: GoogleFonts.poppins(fontSize: 16, color: Color(0xFF154314)),
                    ),
                  ),
                ),
                SizedBox(height: 30),
                Text(
                  "Occurrence",
                  style: GoogleFonts.poppins(
                      fontSize: 18, fontWeight: FontWeight.w600, color: Color(0xFF154314)),
                ),
                SizedBox(height: 10),
                DropdownButtonFormField<String>(
                  value: occurrence,
                  items: ["One Time", "Daily(Week days)", "Weekly"]
                      .map((item) => DropdownMenuItem<String>(
                    value: item,
                    child: Text(item, style: GoogleFonts.poppins(color: Color(0xFF154314))),
                  ))
                      .toList(),
                  onChanged: (val) {
                    setState(() {
                      occurrence = val!;
                      if (occurrence != "Weekly") {
                        selectedDays.clear();
                        weeklyDayTimes.clear();
                      }
                      if (occurrence == "One Time") {
                        endDate = null;
                      }
                    });
                  },
                  decoration: InputDecoration(
                    filled: true,
                    fillColor: Color(0xffdcd0c0).withOpacity(0.7),
                    border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(15), borderSide: BorderSide.none),
                    contentPadding: EdgeInsets.symmetric(vertical: 15, horizontal: 10),
                  ),
                ),
                if (occurrence != "One Time") ...[
                  SizedBox(height: 20),
                  Text(
                    "Select End Date",
                    style: GoogleFonts.poppins(
                        fontSize: 18, fontWeight: FontWeight.w600, color: Color(0xFF154314)),
                  ),
                  SizedBox(height: 10),
                  GestureDetector(
                    onTap: () => _selectDate(context, isEndDate: true),
                    child: Container(
                      padding: EdgeInsets.symmetric(vertical: 16, horizontal: 20),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(15),
                        color: Color(0xffdcd0c0).withOpacity(0.7),
                      ),
                      child: Text(
                        endDate != null ? DateFormat('yyyy-MM-dd').format(endDate!) : "Select End Date",
                        style: GoogleFonts.poppins(fontSize: 16, color: Color(0xFF154314)),
                      ),
                    ),
                  ),
                ],
                if (occurrence == "Weekly") ...[
                  SizedBox(height: 20),
                  Text(
                    "Select Days and Times",
                    style: GoogleFonts.poppins(
                        fontSize: 18, fontWeight: FontWeight.w600, color: Color(0xFF154314)),
                  ),
                  Column(
                    children: weekDays.map((day) {
                      return Column(
                        children: [
                          CheckboxListTile(
                            activeColor: Color(0xFF154314),
                            title: Text(day, style: GoogleFonts.poppins(color: Color(0xFF154314))),
                            value: selectedDays.contains(day),
                            onChanged: (val) {
                              setState(() {
                                if (val == true) {
                                  selectedDays.add(day);
                                } else {
                                  selectedDays.remove(day);
                                  weeklyDayTimes.remove(day);
                                }
                              });
                            },
                          ),
                          if (selectedDays.contains(day))
                            Padding(
                              padding: const EdgeInsets.only(left: 20.0, bottom: 10),
                              child: GestureDetector(
                                onTap: () => _selectTime(context, day: day),
                                child: Container(
                                  padding: EdgeInsets.symmetric(vertical: 12, horizontal: 20),
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(10),
                                    color: Color(0xFFEFE5DC),
                                  ),
                                  child: Text(
                                    weeklyDayTimes[day]?.format(context) ?? "Select time for $day",
                                    style: GoogleFonts.poppins(color: Color(0xFF154314)),
                                  ),
                                ),
                              ),
                            ),
                        ],
                      );
                    }).toList(),
                  ),
                ],
                if (occurrence != "Weekly") ...[
                  SizedBox(height: 30),
                  Text(
                    "Pick-up Time",
                    style: GoogleFonts.poppins(
                        fontSize: 18, fontWeight: FontWeight.w600, color: Color(0xFF154314)),
                  ),
                  SizedBox(height: 10),
                  GestureDetector(
                    onTap: () => _selectTime(context),
                    child: Container(
                      padding: EdgeInsets.symmetric(vertical: 16, horizontal: 20),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(15),
                        color: Color(0xffdcd0c0).withOpacity(0.7),
                      ),
                      child: Text(
                        selectedTime != null ? selectedTime!.format(context) : "Select Time",
                        style: GoogleFonts.poppins(fontSize: 16, color: Color(0xFF154314)),
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
            SizedBox(height: 50),
            Center(
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Color(0xFF154314),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                  padding: EdgeInsets.symmetric(horizontal: 50, vertical: 16),
                ),
                onPressed: _setDateAndTime,
                child: Text("Set Date and Time", style: GoogleFonts.poppins(fontSize: 16, color: Colors.white, fontWeight: FontWeight.w600)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
