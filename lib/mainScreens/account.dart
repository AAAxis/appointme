import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:driver_app/authentication/email_login.dart';
import 'package:driver_app/mainScreens/bank.dart';
import 'package:driver_app/mainScreens/notifications.dart';
import 'package:driver_app/mainScreens/qr_code.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';

import 'working_hours.dart';

class AccountPage extends StatefulWidget {
  @override
  _AccountPageState createState() => _AccountPageState();
}

class _AccountPageState extends State<AccountPage> {
  final GlobalKey<FormState> formKey = GlobalKey<FormState>();
  String? userEmail;
  String? businessName;
  String? businessImage; // Variable to hold the business image URL

  @override
  void initState() {
    super.initState();
    fetchUserData(); // Call to fetch user data
  }

  // Fetch user email, business name, and image from Firestore
  Future<void> fetchUserData() async {
    final User? user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      setState(() {
        userEmail = user.email;
      });

      // Fetch business information from Firestore using the UID stored in the document
      final QuerySnapshot<Map<String, dynamic>> businessSnapshot = await FirebaseFirestore.instance
          .collection('businesses')
          .where('uid', isEqualTo: user.uid) // Use the correct field name for UID
          .get();

      if (businessSnapshot.docs.isNotEmpty) {
        final businessDoc = businessSnapshot.docs.first; // Get the first matching document
        setState(() {
          businessName = businessDoc.data()['business_name'] ?? 'No business name';
          businessImage = businessDoc.data()['image_url'] ?? null; // Fetch the business image
        });
      } else {
        setState(() {
          businessName = 'No business data found';
        });
      }
    }
  }

  Future<void> signOutAndClearPrefs(BuildContext context) async {
    await FirebaseAuth.instance.signOut();
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (context) => EmailLoginScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: ListView(
        children: [
          // Display the business image if available
          businessImage != null
              ? Image.network(
            businessImage!,
            width: 400.0,
            height: 250.0,
            fit: BoxFit.cover, // Adjusts the image to cover the space
          )
              : Container(
            width: 400.0,
            height: 250.0,
            color: Colors.grey, // Placeholder color
            child: Center(child: Text("No image available")),
          ),

          SizedBox(height: 20.0),
          ListTile(
            leading: const Icon(Icons.savings_outlined, color: Colors.black),
            title: const Text(
              "My Bank",
              style: TextStyle(color: Colors.black),
            ),
            onTap: () {
              Navigator.pop(context);
              Navigator.push(
                context,
                MaterialPageRoute(builder: (c) => EditBankScreen()),
              );
            },
          ),

          ListTile(
            leading: const Icon(Icons.store_mall_directory_rounded, color: Colors.black),
            title: const Text(
              "My Store",
              style: TextStyle(color: Colors.black),
            ),
            onTap: () async {
              final User? user = FirebaseAuth.instance.currentUser; // Get current user
              if (user != null) {
                final String url = 'https://appointia.vercel.app/barbershop/${user.uid}'; // Dynamic UID insertion
                final Uri uri = Uri.parse(url);
                await launch(uri.toString());
              } else {
                // Handle the case where the user is not signed in
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text("User not signed in")),
                );
              }
            },
          ),

          ListTile(
            leading: const Icon(Icons.timelapse, color: Colors.black),
            title: const Text(
              "Working Hours",
              style: TextStyle(color: Colors.black),
            ),
            onTap: () {
              Navigator.pop(context);
              Navigator.push(
                context,
                MaterialPageRoute(builder: (c) => SchedulePage()),
              );
            },
          ),
          ListTile(
            leading: const Icon(Icons.qr_code, color: Colors.black),
            title: const Text(
              "QR Code",
              style: TextStyle(color: Colors.black),
            ),
            onTap: () {
              Navigator.pop(context);
              Navigator.push(
                context,
                MaterialPageRoute(builder: (c) => YourScreen()),
              );
            },
          ),
          ListTile(
            leading: const Icon(Icons.notification_add_outlined, color: Colors.black),
            title: const Text(
              "Notifications",
              style: TextStyle(color: Colors.black),
            ),
            onTap: () {
              Navigator.pop(context);
              Navigator.push(
                context,
                MaterialPageRoute(builder: (c) => NotificationScreen()),
              );
            },
          ),
          const Divider(
            height: 10,
            color: Colors.grey,
            thickness: 2,
          ),
          ListTile(
            leading: const Icon(Icons.exit_to_app, color: Colors.black),
            title: const Text(
              "Sign Out",
              style: TextStyle(color: Colors.black),
            ),
            onTap: () {
              signOutAndClearPrefs(context);
            },
          ),

          // Display the signed-in user's email and business name
          SizedBox(height: 80.0),
          Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0),
                  child: Text(
                    "Signed in as: ${userEmail ?? 'Not signed in'}",
                    textAlign: TextAlign.center,
                  ),
                ),
                SizedBox(height: 10.0), // Space between the two texts
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0),
                  child: Text(
                    "Business: ${businessName ?? 'Fetching business name...'}",
                    textAlign: TextAlign.center,
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
