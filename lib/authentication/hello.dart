import 'dart:io'; // For platform detection
import 'package:driver_app/authentication/email_login.dart';
import 'package:driver_app/mainScreens/navigation.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:cloud_firestore/cloud_firestore.dart'; // Firestore to store user data
import 'package:the_apple_sign_in/the_apple_sign_in.dart'; // Apple Sign-In package

class LoginScreen extends StatefulWidget {
  @override
  _LoginScreenState createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final TextEditingController _businessNameController = TextEditingController();
  String? businessName;
  String? errorMessage;
  String? selectedBusinessType;
  final List<String> businessTypes = [
    'Barber Shop',
    'Nail Salon',
    'Gym',
    'Boxing',
    'Massage',
  ];

  Future<void> promptForBusinessName() async {
    await showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text("Business Name"),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: _businessNameController,
                decoration: InputDecoration(hintText: "Enter Business Name"),
              ),
              SizedBox(height: 10),
              DropdownButtonFormField<String>(
                value: selectedBusinessType,
                hint: Text("Select Business Type"),
                items: businessTypes.map((type) {
                  return DropdownMenuItem<String>(
                    value: type,
                    child: Text(type),
                  );
                }).toList(),
                onChanged: (newValue) {
                  setState(() {
                    selectedBusinessType = newValue;
                  });
                },
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                setState(() {
                  businessName = _businessNameController.text.trim();
                });
                Navigator.of(context).pop();
              },
              child: Text("Submit"),
            ),
          ],
        );
      },
    );
  }

  Future<void> checkAndRegisterUser(User? user) async {
    if (user == null) return;

    final userQuery = await _firestore
        .collection('businesses')
        .where('uid', isEqualTo: user.uid)
        .get();

    DateTime trialEndDate;

    if (userQuery.docs.isEmpty) {
      if (businessName == null || businessName!.isEmpty || selectedBusinessType == null) {
        await promptForBusinessName();
      }

      // Trial period of 14 days
      trialEndDate = DateTime.now().add(Duration(days: 14));

      // Store business data
      final businessRef = await _firestore.collection('businesses').add({
        'business_name': businessName,
        'email': user.email,
        'uid': user.uid,
        'phone': 'N/A',
        'service': selectedBusinessType,
        'address': 'N/A',
        'status': 'disabled',
        'image_url': 'https://polskoydm.pythonanywhere.com/static/index.png',
        'background': 'https://polskoydm.pythonanywhere.com/static/background.png',
        'created': FieldValue.serverTimestamp(),
        'sub_expiration': Timestamp.fromDate(trialEndDate),
      });

      // Predefine some services for the user
      List<Map<String, dynamic>> services = [
        {
          'name': 'Women Cut',
          'price': 120,
          'image_url': 'https://polskoydm.pythonanywhere.com/static/womencut.jpeg'
        },
        {
          'name': 'Classic Cut',
          'price': 70,
          'image_url': 'https://polskoydm.pythonanywhere.com/static/mencut.jpeg'
        },
        {
          'name': 'Coloring',
          'price': 130,
          'image_url': 'https://polskoydm.pythonanywhere.com/static/coloring.jpeg'
        },
        {
          'name': 'Beard Trim',
          'price': 80,
          'image_url': 'https://polskoydm.pythonanywhere.com/static/beardtrim.jpeg'
        },
      ];

      // Add services to Firestore
      for (var service in services) {
        await _firestore.collection('services').add({
          'name': service['name'],
          'price': service['price'],
          'image': service['image_url'],
          'userId': user.uid,
        });
      }

      // Set default working hours (8 AM to 8 PM)
      Map<String, dynamic> defaultWorkingHours = {
        'monday': {'from': '08:00', 'to': '20:00', 'working': true},
        'tuesday': {'from': '08:00', 'to': '20:00', 'working': true},
        'wednesday': {'from': '08:00', 'to': '20:00', 'working': true},
        'thursday': {'from': '08:00', 'to': '20:00', 'working': true},
        'friday': {'from': '08:00', 'to': '20:00', 'working': true},
        'saturday': {'from': '08:00', 'to': '20:00', 'working': true},
        'sunday': {'from': '08:00', 'to': '20:00', 'working': true},
      };

      // Add working hours to Firestore under a 'working_hours' collection
      await _firestore.collection('working_hours').doc(user.uid).set({
        'uid': user.uid,
        'workingHours': defaultWorkingHours,
      });

    } else {
      final businessData = userQuery.docs.first.data();
      final expirationDate = (businessData['sub_expiration'] as Timestamp).toDate();
      trialEndDate = expirationDate;

      final currentDate = DateTime.now();

      if (currentDate.isAfter(expirationDate)) {
        setState(() {
          errorMessage = "Trial period expired.";
        });
        return;
      }
    }

    // Navigate to the main app
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (context) => Navigation()),
    );
  }

  Future<void> signInWithGoogle() async {
    try {
      final GoogleSignIn googleSignIn = GoogleSignIn();
      final GoogleSignInAccount? googleUser = await googleSignIn.signIn();
      if (googleUser == null) return;

      final GoogleSignInAuthentication googleAuth = await googleUser.authentication;
      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      UserCredential userCredential = await _auth.signInWithCredential(credential);
      await checkAndRegisterUser(userCredential.user);
    } catch (e) {
      setState(() {
        errorMessage = "Google Sign-in failed: $e";
      });
    }
  }

  Future<void> signInWithApple() async {
    try {
      if (await TheAppleSignIn.isAvailable()) {
        final AuthorizationResult result = await TheAppleSignIn.performRequests(
            [AppleIdRequest(requestedScopes: [Scope.email, Scope.fullName])]
        );

        switch (result.status) {
          case AuthorizationStatus.authorized:
            final appleCredential = result.credential!;
            OAuthProvider oAuthProvider = OAuthProvider("apple.com");
            final credential = oAuthProvider.credential(
              idToken: String.fromCharCodes(appleCredential.identityToken!),
              accessToken: String.fromCharCodes(appleCredential.authorizationCode!),
            );

            UserCredential userCredential = await _auth.signInWithCredential(credential);
            await checkAndRegisterUser(userCredential.user);
            break;
          case AuthorizationStatus.error:
            setState(() {
              errorMessage = "Apple Sign-in failed.";
            });
            break;
          case AuthorizationStatus.cancelled:
            print("User cancelled Apple Sign-In");
            break;
        }
      } else {
        setState(() {
          errorMessage = "Apple Sign-In is not available on this device.";
        });
      }
    } catch (e) {
      setState(() {
        errorMessage = "Apple Sign-In failed: $e";
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          Positioned.fill(
            child: Image.asset(
              'images/background.jpeg',
              fit: BoxFit.cover,
            ),
          ),

          if (errorMessage != null)
            Positioned(
              top: 60,
              left: 20,
              right: 20,
              child: Text(
                errorMessage!,
                style: TextStyle(color: Colors.red, fontSize: 16),
                textAlign: TextAlign.center,
              ),
            ),

          Positioned(
            bottom: 60,
            left: 20,
            right: 20,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (Platform.isAndroid)
                  ElevatedButton.icon(
                    onPressed: signInWithGoogle,
                    icon: Icon(Icons.login, color: Colors.white),
                    label: Text("Sign in with Google",
                        style: TextStyle(color: Colors.white)),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10)),
                      padding: EdgeInsets.symmetric(vertical: 15),
                    ),
                  ),

                SizedBox(height: 10),

                if (Platform.isIOS)
                  ElevatedButton.icon(
                    onPressed: signInWithApple,
                    icon: Icon(Icons.apple, color: Colors.white),
                    label: Text("Sign in with Apple",
                        style: TextStyle(color: Colors.white)),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.black,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10)),
                      padding: EdgeInsets.symmetric(vertical: 15),
                    ),
                  ),

                SizedBox(height: 10),

                ElevatedButton.icon(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => EmailLoginScreen()),
                    );
                  },
                  icon: Icon(Icons.email, color: Colors.white),
                  label: Text("Sign in with Email",
                      style: TextStyle(color: Colors.white)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blueAccent,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10)),
                    padding: EdgeInsets.symmetric(vertical: 15),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
