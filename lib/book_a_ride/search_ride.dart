import 'dart:math';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:hopin/book_a_ride/search_result.dart';
import 'package:intl/intl.dart';
import 'package:hopin/inbox/inbox.dart';
import 'package:hopin/user_home/account_settings.dart';
import 'package:hopin/user_home/post_ride_selection.dart';
import 'package:hopin/user_home/home_page.dart';

import '../my_rides/myrides.dart';
import '../user_home/user_profile.dart';

double calculateDistance(double lat1, double lon1, double lat2, double lon2) {
  const R = 6371; // Earth's radius in km
  double dLat = (lat2 - lat1) * pi / 180;
  double dLon = (lon2 - lon1) * pi / 180;
  double a = sin(dLat / 2) * sin(dLat / 2) +
      cos(lat1 * pi / 180) * cos(lat2 * pi / 180) *
          sin(dLon / 2) * sin(dLon / 2);
  double c = 2 * atan2(sqrt(a), sqrt(1 - a));
  return R * c;
}

class SearchRideParams {
  final String currentUserPhone;
  final double pickupLatitude;
  final double pickupLongitude;
  final double destinationLatitude;
  final double destinationLongitude;
  final String pickupAddress;
  final String destinationAddress;
  final double distanceInKm;

  SearchRideParams({
    required this.currentUserPhone,
    required this.pickupLatitude,
    required this.pickupLongitude,
    required this.destinationLatitude,
    required this.destinationLongitude,
    required this.pickupAddress,
    required this.destinationAddress,
    required this.distanceInKm,
  });
}

class SearchRide extends StatefulWidget {
  final SearchRideParams params;

  const SearchRide({Key? key, required this.params}) : super(key: key);

  @override
  _SearchRideState createState() => _SearchRideState();
}

class _SearchRideState extends State<SearchRide> {
  late Future<List<Map<String, dynamic>>> _rides;
  bool isWomenOnly = false;
  DateTime? selectedDate;
  String? selectedVehicleType;

  @override
  void initState() {
    super.initState();
    _rides = _fetchRides();
  }

  // Function to fetch rides after filtering based on distance and user-selected filters.
  Future<List<Map<String, dynamic>>> _fetchRides() async {
    List<Map<String, dynamic>> rideResults = [];
    DatabaseReference ridesRef = FirebaseDatabase.instance.ref('Rides');
    DatabaseReference cancelledRidesRef = FirebaseDatabase.instance.ref('cancelled_rides');
    const double maxDistanceThreshold = 5.0;

    // Get current user's gender
    final userSnapshot = await FirebaseDatabase.instance
        .ref('Users')
        .orderByChild('phone')
        .equalTo(widget.params.currentUserPhone)
        .get();
    bool isCurrentUserFemale = false;
    if (userSnapshot.exists) {
      final userData = userSnapshot.children.first.value as Map<dynamic, dynamic>;
      isCurrentUserFemale = (userData['gender']?.toString().toLowerCase() == 'female');
    }

    final rideSnapshot = await ridesRef.get();
    if (rideSnapshot.exists) {
      for (var rideDoc in rideSnapshot.children) {
        Map<String, dynamic> rideData = Map.from(rideDoc.value as Map);

        DateTime rideDate = DateTime.parse(rideData['startDate']);
        if (rideDate.isBefore(DateTime.now())) {
          continue;
        }

        double pickupDistance = calculateDistance(
          widget.params.pickupLatitude,
          widget.params.pickupLongitude,
          rideData['pickupLatitude'],
          rideData['pickupLongitude'],
        );
        double destinationDistance = calculateDistance(
          widget.params.destinationLatitude,
          widget.params.destinationLongitude,
          rideData['destinationLatitude'],
          rideData['destinationLongitude'],
        );

        bool matchesFilter = true;

        // If ride is women-only and user is not female, skip (or if filter requires women only)
        if (rideData['women_only'] == true && !isCurrentUserFemale) {
          continue;
        }
        if (isWomenOnly && rideData['women_only'] != true) {
          matchesFilter = false;
        }
        if (selectedDate != null) {
          DateTime rideDate = DateTime.parse(rideData['startDate']);
          if (rideDate.isBefore(selectedDate!)) {
            matchesFilter = false;
          }
        }
        if (selectedVehicleType != null && rideData['vehicleType'] != selectedVehicleType) {
          matchesFilter = false;
        }

        if (pickupDistance <= maxDistanceThreshold && destinationDistance <= maxDistanceThreshold) {
          final rideId = rideDoc.key ?? '';
          final cancelledRideSnapshot = await cancelledRidesRef.child(rideId).get();
          if (cancelledRideSnapshot.exists) {
            continue;
          }
          if (matchesFilter) {
            // Get driver's profile image URL and other details
            final userProfileSnapshot = await FirebaseDatabase.instance
                .ref('Users')
                .orderByChild('phone')
                .equalTo(rideData['phoneNumber'])
                .get();
            String profileImageUrl = '';
            if (userProfileSnapshot.exists) {
              profileImageUrl = userProfileSnapshot.children.first.child('profileImageUrl').value as String? ?? '';
            }
            rideData['profileImageUrl'] = profileImageUrl;
            rideData['rideId'] = rideDoc.key;
            rideResults.add(rideData);
          }
        }
      }
    }
    // Sort rides from newest to oldest based on startDate.
    rideResults.sort((a, b) {
      DateTime dateA = DateTime.parse(a['startDate']);
      DateTime dateB = DateTime.parse(b['startDate']);
      return dateB.compareTo(dateA);
    });
    return rideResults;
  }

  // Fetch driver's additional profile info (including description) by phone number.
  Future<Map<String, String>> _fetchDriverProfile(String phoneNumber) async {
    DatabaseReference userRef = FirebaseDatabase.instance.ref('Users');
    DataSnapshot snapshot = await userRef.orderByChild('phone').equalTo(phoneNumber).get();
    if (snapshot.exists) {
      var userData = snapshot.children.first.value as Map<dynamic, dynamic>;
      return {
        'username': userData['username'] ?? 'Unknown',
        'profileImageUrl': userData['profileImageUrl'] ?? '',
        'description': userData['description'] ?? '',
      };
    } else {
      return {'username': 'Unknown', 'profileImageUrl': '', 'description': ''};
    }
  }

  // Function to compute the average rating for the driver.
  Future<double> _getAverageRating(String phoneNumber) async {
    DatabaseReference ratingsRef = FirebaseDatabase.instance.ref('ratings/$phoneNumber');
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

  // Get number of co-riders from passenger_per_ride for a given rideId.
  Future<int> _getCoRiderCount(String rideId) async {
    DatabaseReference passengerRef = FirebaseDatabase.instance.ref('passenger_per_ride/$rideId');
    DataSnapshot snapshot = await passengerRef.get();
    if (!snapshot.exists) return 0;
    return snapshot.children.length; // total riders in this ride.
  }

  // Format date string.
  String _formatDate(String dateString) {
    try {
      DateTime date = DateTime.parse(dateString);
      return DateFormat('yyyy-MM-dd').format(date);
    } catch (e) {
      return dateString;
    }
  }

  // Open Search Result page for selected ride.
  void _openResultPage(Map<String, dynamic> ride) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ResultPage(
          ride: ride,
          currentUserPhone: widget.params.currentUserPhone,
          rideId: ride['rideId'],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xffefe5dc),
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
                builder: (context) => HomePage(phoneNumber: widget.params.currentUserPhone),
              ),
            );
          }
          else if (index == 1) {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => PostRideSelectionPage(phoneNumber: widget.params.currentUserPhone),
              ),
            );
          } else if (index == 2) {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => MyRidesPage(phoneNumber: widget.params.currentUserPhone),
              ),
            );
          } else if (index == 3) {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => InboxPage(phoneNumber: widget.params.currentUserPhone),
              ),
            );
          } else if (index == 4) {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => UserProfileViewPage(phoneNumber: widget.params.currentUserPhone),
              ),
            );
          }
        },
      ),
      appBar: AppBar(
        title: Text(
          "Search Ride",
          style: GoogleFonts.poppins(fontSize: 22, fontWeight: FontWeight.w600, color: Colors.white),
        ),
        backgroundColor: const Color(0xffe154314),
        iconTheme: const IconThemeData(color: Colors.white),
        actions: [
          IconButton(
            icon: Icon(Icons.filter_alt_outlined),
            onPressed: _openFilterDialog,
          ),
        ],
      ),
      body: FutureBuilder<List<Map<String, dynamic>>>(
        future: _rides,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }
          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return Center(child: Text('No rides found.'));
          }
          final rides = snapshot.data!;
          return ListView.builder(
            itemCount: rides.length,
            itemBuilder: (context, index) {
              final ride = rides[index];
              // Build the ride card
              return FutureBuilder<List<dynamic>>(
                future: Future.wait([
                  _fetchDriverProfile(ride['phoneNumber']),
                  _getAverageRating(ride['phoneNumber']),
                  _getCoRiderCount(ride['rideId']),
                ]),
                builder: (context, combinedSnapshot) {
                  if (combinedSnapshot.connectionState == ConnectionState.waiting) {
                    return Center(child: CircularProgressIndicator());
                  }
                  if (!combinedSnapshot.hasData) {
                    return Center(child: Text("Error fetching driver info"));
                  }
                  Map<String, String> driverProfile = combinedSnapshot.data![0] as Map<String, String>;
                  double avgRating = combinedSnapshot.data![1] as double;
                  int coRiderCount = combinedSnapshot.data![2] as int;

                  String driverName = driverProfile['username'] ?? 'Unknown';
                  String driverImageUrl = driverProfile['profileImageUrl'] ?? '';
                  String driverDescription = driverProfile['description'] ?? '';

                  bool isWomenOnly = ride['women_only'] == true; // expect boolean flag in ride data

                  // Local collapsible state for driver's description.
                  return GestureDetector(
                    onTap: () => _openResultPage(ride),
                    child: Stack(
                      children: [
                        Card(
                          margin: EdgeInsets.symmetric(vertical: 8, horizontal: 16),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          color: Color(0xffefe5dc).withOpacity(0.9),
                          child: Padding(
                            padding: EdgeInsets.all(12),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    CircleAvatar(
                                      backgroundImage: driverImageUrl.isNotEmpty
                                          ? NetworkImage(driverImageUrl)
                                          : AssetImage('assets/images/user.png') as ImageProvider,
                                      radius: 25,
                                    ),
                                    SizedBox(width: 10),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(driverName,
                                              style: GoogleFonts.poppins(
                                                  fontWeight: FontWeight.bold, fontSize: 16)),
                                          Text("Avg Rating: ${avgRating.toStringAsFixed(1)} ⭐",
                                              style: GoogleFonts.poppins(fontSize: 14)),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                                SizedBox(height: 8),
                                Text("Pickup: ${ride['pickupAddress'] ?? 'Not Available'}",
                                    style: GoogleFonts.poppins(fontSize: 14)),
                                Text("Destination: ${ride['destinationAddress'] ?? 'Not Available'}",
                                    style: GoogleFonts.poppins(fontSize: 14)),
                                Text("Time: ${ride['selectedTime'] ?? 'Not Available'}",
                                    style: GoogleFonts.poppins(fontSize: 14)),
                                Text("Vehicle: ${ride['vehicleType'] ?? 'Not specified'}",
                                    style: GoogleFonts.poppins(fontSize: 14)),
                                Text("Co-Riders: $coRiderCount",
                                    style: GoogleFonts.poppins(fontSize: 14)),
                                SizedBox(height: 8),
                                _DriverDescriptionSection(description: driverDescription),
                              ],
                            ),
                          ),
                        ),
                        if (isWomenOnly)
                          Positioned(
                            top:20,
                            right: 30,
                            child: Container(
                              padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: Color(0xff154314),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                "Women-only",
                                style: GoogleFonts.poppins(
                                    fontSize: 12, fontWeight: FontWeight.bold, color: Colors.white),
                              ),
                            ),
                          ),
                        if (ride['petFriendly'] == true)
                          Positioned(
                            top:60,
                            right: 30,
                            child: Container(
                              padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: Color(0xff154314),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                "Pet-friendly",
                                style: GoogleFonts.poppins(
                                    fontSize: 12, fontWeight: FontWeight.bold, color: Colors.white),
                              ),
                            ),
                          ),
                      ],
                    ),
                  );
                },
              );
            },
          );
        },
      ),
    );
  }

  void _openFilterDialog() async {
    await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: Color(0xffefe5dc),
          title: Text("Filter Rides", style: GoogleFonts.poppins(fontWeight: FontWeight.w600)),
          content: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text("Women Only Ride", style: GoogleFonts.poppins()),
                    Checkbox(
                      value: isWomenOnly,
                      activeColor: Color(0xffe154314),
                      onChanged: (value) {
                        setState(() {
                          isWomenOnly = value!;
                        });
                      },
                    ),
                  ],
                ),
                Row(
                  children: [
                    Text("Date", style: GoogleFonts.poppins()),
                    IconButton(
                      icon: Icon(Icons.calendar_today, color: Color(0xffe154314)),
                      onPressed: () async {
                        final pickedDate = await showDatePicker(
                          context: context,
                          initialDate: DateTime.now(),
                          firstDate: DateTime(2020),
                          lastDate: DateTime(2101),
                        );
                        if (pickedDate != null && pickedDate != selectedDate) {
                          setState(() {
                            selectedDate = pickedDate;
                          });
                        }
                      },
                    ),
                    Expanded(
                      child: Text(
                        selectedDate == null
                            ? "Select a date"
                            : "${selectedDate?.toLocal()}".split(' ')[0],
                        style: GoogleFonts.poppins(),
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 10),
                Text("Vehicle Type", style: GoogleFonts.poppins(fontWeight: FontWeight.w500)),
                DropdownButton<String>(
                  value: selectedVehicleType,
                  isExpanded: true,
                  hint: Text("Select Vehicle Type", style: GoogleFonts.poppins()),
                  items: [
                    'Standard Car',
                    'Premier Car',
                    'Jeep',
                    'Minivan',
                    'Van',
                  ].map((type) {
                    return DropdownMenuItem(
                      value: type,
                      child: Text(type, style: GoogleFonts.poppins()),
                    );
                  }).toList(),
                  onChanged: (value) {
                    setState(() {
                      selectedVehicleType = value;
                    });
                  },
                ),
              ],
            ),
          ),
          actions: <Widget>[
            TextButton(
              onPressed: () {
                setState(() {
                  isWomenOnly = false;
                  selectedDate = null;
                  selectedVehicleType = null;
                  _rides = _fetchRides();
                });
                Navigator.of(context).pop();
              },
              child: Text('Clear Filters', style: GoogleFonts.poppins(color: Colors.red)),
            ),
            TextButton(
              onPressed: () {
                setState(() {
                  _rides = _fetchRides();
                });
                Navigator.of(context).pop();
              },
              child: Text('Apply Filters', style: GoogleFonts.poppins(color: Color(0xffe154314), fontWeight: FontWeight.bold)),
            ),
          ],
        );
      },
    );
  }
}

class _DriverDescriptionSection extends StatefulWidget {
  final String description;
  const _DriverDescriptionSection({Key? key, required this.description}) : super(key: key);

  @override
  __DriverDescriptionSectionState createState() => __DriverDescriptionSectionState();
}

class __DriverDescriptionSectionState extends State<_DriverDescriptionSection> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TextButton(
          onPressed: () {
            setState(() {
              _expanded = !_expanded;
            });
          },
          child: Text(
            _expanded ? 'Hide Driver Description' : 'Show Driver Description',
            style: GoogleFonts.poppins(fontWeight: FontWeight.w500),
          ),
        ),
        if (_expanded)
          Container(
            padding: EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.grey.shade200,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              widget.description.isNotEmpty ? widget.description : 'No description provided.',
              style: GoogleFonts.poppins(fontSize: 13),
            ),
          )
      ],
    );
  }
}
