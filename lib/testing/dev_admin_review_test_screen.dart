import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:hopin/firebase_options.dart';

class DevAdminReviewTestScreen extends StatefulWidget {
  const DevAdminReviewTestScreen({super.key});

  @override
  State<DevAdminReviewTestScreen> createState() => _DevAdminReviewTestScreenState();
}

class _DevAdminReviewTestScreenState extends State<DevAdminReviewTestScreen> {
  String selectedFilter = 'All';
  List<Map<String, dynamic>> allRatings = [];
  bool loading = true;

  @override
  void initState() {
    super.initState();
    initFirebaseAndFetchData();
  }

  Future<void> initFirebaseAndFetchData() async {
    await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
    final ref = FirebaseDatabase.instance.ref("ratings");
    final snapshot = await ref.get();


    if (snapshot.exists) {
      Map<dynamic, dynamic> data = snapshot.value as Map;
      List<Map<String, dynamic>> results = [];

      data.forEach((phone, userRatings) {
        if (userRatings is Map) {
          userRatings.forEach((_, ratingData) {
            results.add({
              'phone': phone,
              'rating': ratingData['rating'],
              'review': ratingData['review'],
              'timestamp': ratingData['timestamp'],
            });
          });
        }
      });

      setState(() {
        allRatings = results;
        loading = false;
      });
    } else {
      setState(() => loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    List<Map<String, dynamic>> filtered = selectedFilter == 'All'
        ? allRatings
        : allRatings.where((r) => r['rating'].toString() == selectedFilter).toList();


    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color(0xff154314),
        title: const Text('Admin Review Test'),
      ),
      body: loading
          ? const Center(child: CircularProgressIndicator())
          : Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            child: DropdownButtonFormField<String>(
              value: selectedFilter,
              decoration: const InputDecoration(border: OutlineInputBorder()),
              items: ['All', '5', '4', '3', '2', '1'].map((v) {
                return DropdownMenuItem(value: v, child: Text(v == 'All' ? 'All Ratings' : '$v Stars'));
              }).toList(),
              onChanged: (val) => setState(() => selectedFilter = val!),
            ),
          ),
          Expanded(
            child: ListView.builder(
              itemCount: filtered.length,
              itemBuilder: (_, i) {
                final r = filtered[i];
                return Card(
                  margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  child: ListTile(
                    title: Text('${r['review']}', style: GoogleFonts.poppins()),
                    subtitle: Text('Rating: ${r['rating']} ⭐', style: GoogleFonts.poppins()),
                    trailing: Text('${r['phone']}', style: GoogleFonts.poppins(fontSize: 12)),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}