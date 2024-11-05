import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:driver_app/authentication/hello.dart';
import 'package:driver_app/mainScreens/appointments.dart';
import 'package:driver_app/mainScreens/bank.dart';
import 'package:driver_app/mainScreens/employess.dart';
import 'package:driver_app/mainScreens/invoice.dart';
import 'package:driver_app/mainScreens/notifications.dart';

import 'package:driver_app/mainScreens/profile.dart';
import 'package:driver_app/mainScreens/service.dart';

import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

import 'package:shared_preferences/shared_preferences.dart';
import 'business_page.dart';
import 'working_hours.dart';

class BusinessInfo {
  final String businessName;
  final String docId;

  BusinessInfo({required this.businessName, required this.docId});
}

class CustomDrawer extends StatelessWidget {
  CustomDrawer();

  Future<void> signOutAndClearPrefs(BuildContext context) async {
    await FirebaseAuth.instance.signOut();
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (context) => LoginScreen()),
    );
  }

  Future<BusinessInfo> fetchBusinessName(String userId) async {
    // Fetch business name from Firestore where uid matches userId
    try {
      final querySnapshot = await FirebaseFirestore.instance
          .collection('businesses')
          .where('uid', isEqualTo: userId)
          .get();

      if (querySnapshot.docs.isNotEmpty) {
        final doc = querySnapshot.docs.first;
        final businessName = doc.data()['business_name'] ?? 'Your Business Name';
        final docId = doc.id; // Get the document ID

        return BusinessInfo(businessName: businessName, docId: docId);
      } else {
        return BusinessInfo(businessName: 'Your Business Name', docId: ''); // Fallback if no document found
      }
    } catch (e) {
      print('Error fetching business name: $e');
      return BusinessInfo(businessName: 'Name', docId: ''); // Fallback in case of error
    }
  }

  @override
  Widget build(BuildContext context) {
    // Get the current user
    final User? user = FirebaseAuth.instance.currentUser;

    return FutureBuilder<BusinessInfo>(
      future: user != null
          ? fetchBusinessName(user.uid)
          : Future.value(BusinessInfo(businessName: '', docId: '')),
      builder: (context, snapshot) {
        // Get the business name and document ID from the snapshot data
        BusinessInfo businessInfo = snapshot.data ?? BusinessInfo(businessName: '', docId: '');

        return Drawer(
          child: ListView(
            padding: EdgeInsets.zero,
            children: [
              DrawerHeader(
                decoration: BoxDecoration(
                  color: Colors.blue,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (user?.photoURL != null)

                    SizedBox(height: 10.0),
                    Text(
                      businessInfo.businessName, // Access the business name from the BusinessInfo object
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                      ),
                    ),
                  ],
                ),
              ),
              ListTile(
                leading: const Icon(Icons.person, color: Colors.black),
                title: const Text(
                  "Edir Profile",
                  style: TextStyle(color: Colors.black),
                ),
                onTap: () {
                  Navigator.pop(context);
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (c) => ProfileScreen()),
                  );
                },
              ),
              ListTile(
                leading: const Icon(Icons.calendar_today_rounded, color: Colors.black),
                title: const Text(
                  "My Appointments",
                  style: TextStyle(color: Colors.black),
                ),
                onTap: () {
                  Navigator.pop(context);
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => AppointmentsPage(), // Correctly pass docId
                    ),
                  );
                },
              ),
              ListTile(
                leading: const Icon(Icons.access_time_rounded, color: Colors.black),
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
                leading: const Icon(Icons.people_alt_outlined, color: Colors.black),
                title: const Text(
                  "My Employees",
                  style: TextStyle(color: Colors.black),
                ),
                onTap: () {
                  Navigator.pop(context);
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (c) => EmployeeDetailsScreen()),
                  );
                },
              ),



              ListTile(
                leading: const Icon(Icons.library_books_rounded, color: Colors.black),
                title: const Text(
                  "Services Library",
                  style: TextStyle(color: Colors.black),
                ),
                onTap: () {
                  Navigator.pop(context);
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (c) => ServiceDetailsScreen()),
                  );
                },
              ),
              ListTile(
                leading: const Icon(Icons.credit_card, color: Colors.black),
                title: const Text(
                  "Checkout",
                  style: TextStyle(color: Colors.black),
                ),
                onTap: () {
                  Navigator.pop(context);
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (c) => InvoiceGenerator()),
                  );
                },
              ),
              ListTile(
                leading: const Icon(Icons.notifications_none_rounded, color: Colors.black),
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
            ],
          ),
        );
      },
    );
  }
}
