// import 'package:firebase_messaging/firebase_messaging.dart';
// import 'package:flutter/material.dart';
// import 'package:google_fonts/google_fonts.dart';
// import 'package:firebase_database/firebase_database.dart';
// import 'package:hopin/user_home/home_page.dart';
// import 'package:hopin/app_open/auth_choose_view.dart';
// import 'package:hopin/authentication/reset_pass.dart';
//
// class Login extends StatefulWidget {
//   const Login({super.key});
//
//   @override
//   State<Login> createState() => _LoginState();
// }
//
// class _LoginState extends State<Login> {
//   final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
//   final TextEditingController _phoneEmailController = TextEditingController();
//   final TextEditingController _passwordController = TextEditingController();
//   final FirebaseDatabase _database = FirebaseDatabase.instance;
//
//   int _failedAttempts = 0;
//   bool _isLockedOut = false;
//   bool _obscurePassword = true;
//
//   Future<void> _login() async {
//     debugPrint("Login button clicked");
//
//     if (_isLockedOut) {
//       debugPrint("Login blocked - User is currently locked out.");
//       _showLockoutDialog();
//       return;
//     }
//
//     if (!_formKey.currentState!.validate()) {
//       debugPrint("Form validation failed.");
//       return;
//     }
//
//     String phoneEmail = _phoneEmailController.text.trim();
//     String password = _passwordController.text;
//
//     debugPrint("Entered Email/Phone: $phoneEmail");
//     debugPrint("Entered Password: $password");
//
//     if (phoneEmail.isEmpty || password.isEmpty) {
//       ScaffoldMessenger.of(context).showSnackBar(
//         SnackBar(
//           content: Text(
//             "Fields cannot be empty!",
//             style: GoogleFonts.poppins(color: Colors.red),
//           ),
//         ),
//       );
//       return;
//     }
//
//     try {
//       // Lockout check from Firebase
//       DatabaseReference lockRef = _database.ref().child("LockedUsers").child(phoneEmail.replaceAll('.', '_'));
//       DatabaseEvent lockEvent = await lockRef.once();
//
//       if (lockEvent.snapshot.value != null) {
//         Map lockData = lockEvent.snapshot.value as Map;
//         int lockedAt = lockData['lockedAt'];
//         int currentTime = DateTime.now().millisecondsSinceEpoch;
//
//         if (currentTime - lockedAt < 10 * 60 * 1000) {
//           _showAlreadyLockedDialog();
//           return;
//         } else {
//           await lockRef.remove();
//         }
//       }
//
//       // Fetch Users
//       DatabaseReference usersRef = _database.ref().child("Users");
//       DatabaseEvent event = await usersRef.once();
//       debugPrint("Users data fetched from Firebase.");
//
//       bool userFound = false;
//       String phoneNumber = '';
//       String userKey = '';
//
//       if (event.snapshot.value != null) {
//         Map<dynamic, dynamic> users = event.snapshot.value as Map<dynamic, dynamic>;
//
//         users.forEach((key, user) {
//           if ((user["phone"] == phoneEmail || user["email"] == phoneEmail) &&
//               user["password"] == password) {
//             userFound = true;
//             phoneNumber = user["phone"];
//             userKey = key; // Save the matching key
//           }
//         });
//       } else {
//         debugPrint("No users data found in the database.");
//       }
//
//       if (userFound) {
//         String? fcmToken = await FirebaseMessaging.instance.getToken();
//         debugPrint("FCM Token: $fcmToken");
//
//         if (fcmToken != null && userKey.isNotEmpty) {
//           await usersRef.child(userKey).update({
//             'fcmToken': fcmToken,
//           });
//           debugPrint("FCM Token updated for user with key: $userKey");
//         }
//
//         setState(() {
//           _failedAttempts = 0;
//           _isLockedOut = false;
//         });
//
//         Navigator.pushReplacement(
//           context,
//           MaterialPageRoute(builder: (context) => HomePage(phoneNumber: phoneNumber)),
//         );
//       } else {
//         debugPrint("Invalid credentials entered.");
//         setState(() {
//           _failedAttempts++;
//         });
//
//         if (_failedAttempts >= 3) {
//           await lockRef.set({'lockedAt': DateTime.now().millisecondsSinceEpoch});
//           _isLockedOut = true;
//           _showLockoutDialog();
//         } else {
//           ScaffoldMessenger.of(context).showSnackBar(
//             SnackBar(
//               content: Text(
//                 "Invalid credentials!",
//                 style: GoogleFonts.poppins(color: Colors.red),
//               ),
//             ),
//           );
//         }
//       }
//     } catch (e, stacktrace) {
//       debugPrint("Login Error: $e");
//       debugPrint("Stacktrace: $stacktrace");
//
//       ScaffoldMessenger.of(context).showSnackBar(
//         SnackBar(
//           content: Text(
//             "An error occurred: $e",
//             style: GoogleFonts.poppins(color: Colors.red),
//           ),
//         ),
//       );
//     }
//   }
//
//   void _showLockoutDialog() {
//     showDialog(
//       context: context,
//       builder: (context) => AlertDialog(
//         title: Text(
//           "Account Locked",
//           style: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.red),
//         ),
//         content: Text(
//           "You have entered incorrect credentials 3 times. Your account is locked for 10 minutes.",
//           style: GoogleFonts.poppins(fontSize: 14, color: Color(0xff154314)),
//         ),
//         actions: [
//           TextButton(
//             onPressed: () {
//               Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => const authHome()));
//             },
//             child: Text(
//               "Go Back",
//               style: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.red),
//             ),
//           ),
//         ],
//       ),
//     );
//   }
//
//   void _showAlreadyLockedDialog() {
//     showDialog(
//       context: context,
//       builder: (context) => AlertDialog(
//         title: Text(
//           "Account Locked",
//           style: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xff154314)),
//         ),
//         content: Text(
//           "This account is locked. Please try again after 10 minutes.",
//           style: GoogleFonts.poppins(fontSize: 14, color: Color(0xff154314)),
//         ),
//         actions: [
//           TextButton(
//             onPressed: () {
//               Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => const authHome()));
//             },
//             child: Text(
//               "Go Back",
//               style: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xff154314)),
//             ),
//           ),
//         ],
//       ),
//     );
//   }
//
//   void _resetPassword() {
//     Navigator.push(
//       context,
//       MaterialPageRoute(builder: (context) => ResetPasswordScreen()),
//     );
//   }
//
//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       backgroundColor: const Color(0xFFEFE5DC),
//       body: SafeArea(
//         child: Center(
//           child: SingleChildScrollView(
//             padding: const EdgeInsets.symmetric(horizontal: 24.0),
//             child: Form(
//               key: _formKey,
//               child: Column(
//                 children: [
//                   Image.asset('assets/images/hopin_logo.png', height: 70),
//                   const SizedBox(height: 20),
//                   Text(
//                     "HopIn",
//                     style: GoogleFonts.poppins(fontSize: 30, fontWeight: FontWeight.bold, color: const Color(0xFF154314)),
//                   ),
//                   const SizedBox(height: 20),
//                   Text(
//                     "Login to your account",
//                     style: GoogleFonts.poppins(fontSize: 22, fontWeight: FontWeight.bold, color: const Color(0xFF154314)),
//                   ),
//                   const SizedBox(height: 30),
//                   TextFormField(
//                     key: const Key('phone_email_field'),
//                     controller: _phoneEmailController,
//                     decoration: InputDecoration(
//                       prefixIcon: const Icon(Icons.person, color: Color(0xFF154314)),
//                       hintText: "Phone/ Email",
//                       hintStyle: GoogleFonts.poppins(fontSize: 14),
//                     ),
//                   ),
//                   const SizedBox(height: 20),
//                   TextFormField(
//                     key: const Key('password_field'),
//                     controller: _passwordController,
//                     obscureText: _obscurePassword,
//                     decoration: InputDecoration(
//                       prefixIcon: const Icon(Icons.lock, color: Color(0xFF154314)),
//                       hintText: "Password",
//                       hintStyle: GoogleFonts.poppins(fontSize: 14),
//                       suffixIcon: IconButton(
//                         icon: Icon(
//                           _obscurePassword ? Icons.visibility_off : Icons.visibility,
//                           color: Color(0xFF154314),
//                         ),
//                         onPressed: () {
//                           setState(() {
//                             _obscurePassword = !_obscurePassword;
//                           });
//                         },
//                       ),
//                     ),
//                   ),
//                   const SizedBox(height: 10),
//                   Align(
//                     alignment: Alignment.centerRight,
//                     child: TextButton(
//                       key: const Key('forgot_password_button'),
//                       onPressed: _resetPassword,
//                       child: Text("Forgot Password?", style: GoogleFonts.poppins(color: Color(0xFF154314))),
//                     ),
//                   ),
//                   const SizedBox(height: 20),
//                   SizedBox(
//                     width: double.infinity,
//                     height: 50,
//                     child: ElevatedButton(
//                       key: const Key('login_button'),
//                       style: ElevatedButton.styleFrom(
//                         backgroundColor: const Color(0xFF154314),
//                         shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
//                       ),
//                       onPressed: _login,
//                       child: Text("Login", style: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.w600, color: Colors.white)),
//                     ),
//                   ),
//                   const SizedBox(height: 10),
//                   TextButton(
//                     key: const Key('go_back_button'),
//                     onPressed: () {
//                       Navigator.pushReplacement(
//                         context,
//                         MaterialPageRoute(builder: (context) => const authHome()),
//                       );
//                     },
//                     child: Text(
//                       "Go back? Click Here!",
//                       style: GoogleFonts.poppins(fontSize: 14, fontWeight: FontWeight.w600, color: Color(0xFF154314)),
//                     ),
//                   ),
//                 ],
//               ),
//             ),
//           ),
//         ),
//       ),
//     );
//   }
// }


import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:geolocator/geolocator.dart';
import 'package:hopin/user_home/home_page.dart';
import 'package:hopin/app_open/auth_choose_view.dart';
import 'package:hopin/authentication/reset_pass.dart';

class Login extends StatefulWidget {
  const Login({super.key});

  @override
  State<Login> createState() => _LoginState();
}

class _LoginState extends State<Login> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final TextEditingController _phoneEmailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final FirebaseDatabase _database = FirebaseDatabase.instance;

  int _failedAttempts = 0;
  bool _isLockedOut = false;
  bool _obscurePassword = true;

  // Method to update user location in Firebase
  Future<void> updateUserLocation(String phoneNumber) async {
    try {
      // Get the current location
      Position position = await Geolocator.getCurrentPosition(desiredAccuracy: LocationAccuracy.high);

      // Store location in Firebase under the user's phone number
      DatabaseReference userRef = FirebaseDatabase.instance.ref("Locations/$phoneNumber");
      await userRef.set({
        'latitude': position.latitude,
        'longitude': position.longitude,
      });

      // Start listening to location updates
      Geolocator.getPositionStream(locationSettings: LocationSettings(
        accuracy: LocationAccuracy.high,
        distanceFilter: 10,
      )).listen((Position position) {
        // Update the real-time location in Firebase
        userRef.update({
          'latitude': position.latitude,
          'longitude': position.longitude,
        });
      });
    } catch (e) {
      print("Error updating location: $e");
    }
  }

  Future<void> _login() async {
    if (_isLockedOut) {
      _showLockoutDialog();
      return;
    }

    if (!_formKey.currentState!.validate()) {
      return;
    }

    String phoneEmail = _phoneEmailController.text.trim();
    String password = _passwordController.text;

    if (phoneEmail.isEmpty || password.isEmpty) {
      _showSnackbar("Fields cannot be empty!");
      return;
    }

    try {
      // Check if the user is already locked
      final lockRef = _database.ref("LockedUsers/${phoneEmail.replaceAll('.', '_')}");
      final lockSnapshot = await lockRef.get();

      if (lockSnapshot.exists) {
        int lockedAt = (lockSnapshot.value as Map)['lockedAt'];
        int currentTime = DateTime.now().millisecondsSinceEpoch;

        if (currentTime - lockedAt < 10 * 60 * 1000) {
          _showAlreadyLockedDialog();
          return;
        } else {
          await lockRef.remove();
        }
      }

      // Fetch Users data
      final usersRef = _database.ref("Users");
      final event = await usersRef.once();

      bool userFound = false;
      String phoneNumber = '';
      String userKey = '';

      if (event.snapshot.value != null) {
        Map<dynamic, dynamic> users = event.snapshot.value as Map<dynamic, dynamic>;

        users.forEach((key, user) {
          if ((user["phone"] == phoneEmail || user["email"] == phoneEmail) && user["password"] == password) {
            userFound = true;
            phoneNumber = user["phone"];
            userKey = key;
          }
        });
      }

      if (userFound) {
        final String? fcmToken = await FirebaseMessaging.instance.getToken();
        if (fcmToken != null && userKey.isNotEmpty) {
          // Update the FCM token under the existing user using their userKey
          await usersRef.child(userKey).update({'fcmToken': fcmToken});
          debugPrint('FCM token updated for user with phone: $phoneNumber');
        } else {
          debugPrint('❌ FCM token or userKey is null');
        }


        // Update location after login
        await updateUserLocation(phoneNumber);

        setState(() {
          _failedAttempts = 0;
          _isLockedOut = false;
        });

        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => HomePage(phoneNumber: phoneNumber)),
        );
      } else {
        setState(() {
          _failedAttempts++;
        });

        if (_failedAttempts >= 3) {
          await lockRef.set({'lockedAt': DateTime.now().millisecondsSinceEpoch});
          _isLockedOut = true;
          _showLockoutDialog();
        } else {
          _showSnackbar("Invalid credentials!");
        }
      }
    } catch (e) {
      _showSnackbar("An error occurred: $e");
    }
  }

  void _showSnackbar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          message,
          style: GoogleFonts.poppins(color: Colors.red),
        ),
      ),
    );
  }

  void _showLockoutDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          "Account Locked",
          style: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.red),
        ),
        content: Text(
          "You have entered incorrect credentials 3 times.\nYour account is locked for 10 minutes.",
          style: GoogleFonts.poppins(fontSize: 14, color: Color(0xff154314)),
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => const authHome()));
            },
            child: Text(
              "Go Back",
              style: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.red),
            ),
          ),
        ],
      ),
    );
  }

  void _showAlreadyLockedDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          "Account Locked",
          style: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xff154314)),
        ),
        content: Text(
          "This account is locked. Please try again after 10 minutes.",
          style: GoogleFonts.poppins(fontSize: 14, color: Color(0xff154314)),
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => const authHome()));
            },
            child: Text(
              "Go Back",
              style: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xff154314)),
            ),
          ),
        ],
      ),
    );
  }

  void _resetPassword() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => ResetPasswordScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFEFE5DC),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24.0),
            child: Form(
              key: _formKey,
              child: Column(
                children: [
                  Image.asset('assets/images/hopin_logo.png', height: 70),
                  const SizedBox(height: 20),
                  Text(
                    "HopIn",
                    style: GoogleFonts.poppins(fontSize: 30, fontWeight: FontWeight.bold, color: const Color(0xFF154314)),
                  ),
                  const SizedBox(height: 20),
                  Text(
                    "Login to your account",
                    style: GoogleFonts.poppins(fontSize: 22, fontWeight: FontWeight.bold, color: const Color(0xFF154314)),
                  ),
                  const SizedBox(height: 30),
                  TextFormField(
                    key: const Key('phone_email_field'),
                    controller: _phoneEmailController,
                    decoration: InputDecoration(
                      prefixIcon: const Icon(Icons.person, color: Color(0xFF154314)),
                      hintText: "Phone/Email",
                      hintStyle: GoogleFonts.poppins(fontSize: 14),
                    ),
                  ),
                  const SizedBox(height: 20),
                  TextFormField(
                    key: const Key('password_field'),
                    controller: _passwordController,
                    obscureText: _obscurePassword,
                    decoration: InputDecoration(
                      prefixIcon: const Icon(Icons.lock, color: Color(0xFF154314)),
                      hintText: "Password",
                      hintStyle: GoogleFonts.poppins(fontSize: 14),
                      suffixIcon: IconButton(
                        icon: Icon(
                          _obscurePassword ? Icons.visibility_off : Icons.visibility,
                          color: Color(0xFF154314),
                        ),
                        onPressed: () {
                          setState(() {
                            _obscurePassword = !_obscurePassword;
                          });
                        },
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),
                  Align(
                    alignment: Alignment.centerRight,
                    child: TextButton(
                      key: const Key('forgot_password_button'),
                      onPressed: _resetPassword,
                      child: Text(
                        "Forgot Password?",
                        style: GoogleFonts.poppins(color: Color(0xFF154314)),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton(
                      key: const Key('login_button'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF154314),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      ),
                      onPressed: _login,
                      child: Text(
                        "Login",
                        style: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.w600, color: Colors.white),
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),
                  TextButton(
                    key: const Key('go_back_button'),
                    onPressed: () {
                      Navigator.pushReplacement(
                        context,
                        MaterialPageRoute(builder: (context) => const authHome()),
                      );
                    },
                    child: Text(
                      "Go back? Click Here!",
                      style: GoogleFonts.poppins(fontSize: 14, fontWeight: FontWeight.w600, color: Color(0xFF154314)),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
