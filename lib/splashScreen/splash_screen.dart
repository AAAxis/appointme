import 'dart:async';
import 'package:app_tracking_transparency/app_tracking_transparency.dart';
import 'package:driver_app/authentication/email_login.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:driver_app/mainScreens/navigation.dart';
import 'package:url_launcher/url_launcher.dart'; // Add this to handle the link

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
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => Navigation()),
        );
      } else {
        _requestPermissionManually();
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => EmailLoginScreen()),
        );
      }
    });
  }

  Future<void> _launchURL() async {
    const _url = 'https://buymeacoffee.com/theholylabs';

      await launch(_url);

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
