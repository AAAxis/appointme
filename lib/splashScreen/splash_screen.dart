import 'dart:async';
import 'package:app_tracking_transparency/app_tracking_transparency.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:driver_app/authentication/hello.dart';
import 'package:driver_app/mainScreens/inpurchase.dart';
import 'package:driver_app/mainScreens/navigation.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class MySplashScreen extends StatefulWidget {
  const MySplashScreen({Key? key}) : super(key: key);

  @override
  State<MySplashScreen> createState() => _MySplashScreenState();
}

class _MySplashScreenState extends State<MySplashScreen> {

  Future<void> _requestPermissionManually() async {
    final trackingStatus = await AppTrackingTransparency.requestTrackingAuthorization();
    print('Manual tracking permission request status: $trackingStatus');

    final prefs = await SharedPreferences.getInstance();

    if (trackingStatus == TrackingStatus.authorized) {
      await prefs.setBool('trackingPermissionStatus', true);
    } else {
      await prefs.setBool('trackingPermissionStatus', false);
    }
  }

  @override
  void initState() {
    super.initState();
    _checkCurrentUser();
  }

  void _checkCurrentUser() {
    Timer(Duration(seconds: 3), () async {
      User? user = FirebaseAuth.instance.currentUser;

      if (user != null) {
        // User is logged in, check trial expiration
        final userQuery = await FirebaseFirestore.instance
            .collection('businesses')
            .where('uid', isEqualTo: user.uid)
            .get();

        if (userQuery.docs.isNotEmpty) {
          final userDoc = userQuery.docs.first.data();
          Timestamp expirationTimestamp = userDoc['sub_expiration']; // Get expiration date
          DateTime expirationDate = expirationTimestamp.toDate(); // Convert to DateTime

          // Get the current date
          DateTime currentDate = DateTime.now();

          // Check if the current date is after the expiration date
          if (currentDate.isAfter(expirationDate)) {
            // Trial has expired, navigate to subscription page
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (context) => InAppPurchasePage()), // Replace with your Subscription page
            );
          } else {
            // Trial is still active, navigate to appointments page
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (context) => Navigation()),
            );
          }
        } else {
          // If no user document found, handle it (e.g., show an error or sign out the user)
          _requestPermissionManually();
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => LoginScreen()), // Replace with LoginScreen
          );
        }
      } else {
        // No user logged in, navigate to login screen
        _requestPermissionManually();
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => LoginScreen()),
        );
      }
    });
  }



  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onVerticalDragEnd: (_) {
        _requestPermissionManually();
      },
      child: Material(
        child: Container(
          color: Colors.white,
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                ClipRRect(
                  child: SizedBox(
                    width: 250,
                    height: 250,
                    child: Image.asset("images/Preview.png"),
                  ),
                ),
                const SizedBox(height: 30,),
                Text(
                  "Swipe to Continue >>",
                  style: TextStyle(
                    color: Colors.black, // Change the color to your preference
                    fontSize: 16,
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
