import 'package:driver_app/mainScreens/confirm.dart';
import 'package:driver_app/mainScreens/drawer.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:intl/intl.dart';

class BarbershopPage extends StatefulWidget {
  const BarbershopPage({Key? key}) : super(key: key);

  @override
  _BarbershopPageState createState() => _BarbershopPageState();
}

class _BarbershopPageState extends State<BarbershopPage> {
  Map<String, dynamic>? barbershopData;
  List<Map<String, dynamic>> servicesData = [];
  String? selectedService;
  String? userId;
  List<Map<String, dynamic>> employeesData = [];
  String? selectedEmployee;
  String? selectedHour;
  String? selectedDay;
  int currentBackgroundIndex = 0;

  List<String> backgroundAssets = [
    'images/ford.jpeg',
    'images/tesla.jpeg',
    'images/chevy.jpeg',
  ];

  List<String> backgroundLinks = [
    'https://polskoydm.pythonanywhere.com/static/ford.jpeg',
    'https://polskoydm.pythonanywhere.com/static/tesla.jpeg',
    'https://polskoydm.pythonanywhere.com/static/chevy.jpeg',
  ];

  @override
  void initState() {
    super.initState();
    fetchServicesData();
    fetchEmployeesData();
    fetchBarbershopData();
    selectedHour = generateHours()[0];
    selectedDay = generateFutureDays()[0];
  }

  Future<void> fetchEmployeesData() async {
    try {
      User? user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        userId = user.uid;
        QuerySnapshot querySnapshot = await FirebaseFirestore.instance
            .collection('employees')
            .where('userId', isEqualTo: userId)
            .get();
        setState(() {
          employeesData = querySnapshot.docs.map((doc) => doc.data() as Map<
              String,
              dynamic>).toList();
          if (employeesData.isNotEmpty) {
            selectedEmployee = employeesData[0]['name'];
          }
        });
      }
    } catch (e) {
      print("Error fetching employees data: $e");
    }
  }

  Future<void> fetchServicesData() async {
    try {
      User? user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        userId = user.uid;
        QuerySnapshot querySnapshot = await FirebaseFirestore.instance
            .collection('services')
            .where('userId', isEqualTo: userId)
            .get();
        setState(() {
          servicesData = querySnapshot.docs.map((doc) => doc.data() as Map<
              String,
              dynamic>).toList();
          if (servicesData.isNotEmpty) {
            selectedService = servicesData[0]['name'];
          }
        });
      }
    } catch (e) {
      print("Error fetching services data: $e");
    }
  }

  Future<void> fetchBarbershopData() async {
    try {
      User? user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        DocumentSnapshot docSnap = await FirebaseFirestore.instance
            .collection('businesses')
            .where('uid', isEqualTo: user.uid)
            .get()
            .then((snapshot) => snapshot.docs.first);

        if (docSnap.exists) {
          setState(() {
            barbershopData = docSnap.data() as Map<String, dynamic>?;
          });
        }
      }
    } catch (e) {
      print("Error fetching barbershop data: $e");
    }
  }

  List<String> generateHours() {
    List<String> hours = [];
    for (int hour = 8; hour <= 20; hour++) {
      hours.add('${hour % 24}:00');
    }
    return hours;
  }

  List<String> generateFutureDays() {
    List<String> days = [];
    DateTime now = DateTime.now();
    for (int i = 0; i < 7; i++) {
      DateTime futureDate = now.add(Duration(days: i));
      days.add(DateFormat('EEEE, MMM d, yyyy').format(futureDate));
    }
    return days;
  }

  void updateBackground(int index) {
    setState(() {
      currentBackgroundIndex = index;
    });

    // Update Firestore with the selected background image link
    String selectedLink = backgroundLinks[index];

    // Query the businesses collection where the uid matches
    FirebaseFirestore.instance
        .collection('businesses')
        .where('uid', isEqualTo: userId)
        .get() // Use .get() to retrieve the documents
        .then((querySnapshot) {
      if (querySnapshot.docs.isNotEmpty) {
        // Assuming the document is found and the uid is unique
        String docId = querySnapshot.docs.first.id; // Get the document ID
        // Now update the document using docId
        FirebaseFirestore.instance
            .collection('businesses')
            .doc(docId)
            .update({
          'background': selectedLink, // Update the background field
        })
            .then((_) {
          print("Background image link updated in Firestore");
        })
            .catchError((error) {
          print("Error updating link: $error");
        });
      } else {
        print("No document found with the specified UID");
      }
    }).catchError((error) {
      print("Error querying document: $error");
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('My Business'),
      ),
      drawer: CustomDrawer(),
      body: barbershopData == null
          ? const Center(child: CircularProgressIndicator())
          : Stack(
        children: [
          GestureDetector(
            onHorizontalDragUpdate: (details) {
              if (details.primaryDelta! > 0 && currentBackgroundIndex > 0) {
                updateBackground(currentBackgroundIndex - 1);
              } else if (details.primaryDelta! < 0 &&
                  currentBackgroundIndex < backgroundAssets.length - 1) {
                updateBackground(currentBackgroundIndex + 1);
              }
            },
            child: Container(
              decoration: BoxDecoration(
                image: DecorationImage(
                  image: AssetImage(backgroundAssets[currentBackgroundIndex]),
                  fit: BoxFit.cover,
                ),
              ),
            ),
          ),
          SingleChildScrollView(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                SizedBox(height: 200),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    FloatingActionButton(
                      heroTag: "phone",
                      child: Icon(Icons.phone),
                      backgroundColor: Colors.white,
                      onPressed: () {
                        final phone = barbershopData!['phone'] ?? '';
                        launch('tel:$phone');
                      },
                    ),
                    SizedBox(width: 10),
                    FloatingActionButton(
                      heroTag: "location",
                      child: Icon(Icons.location_on),
                      backgroundColor: Colors.white,
                      onPressed: () {
                        final address = barbershopData!['address'] ?? '';
                        launch(
                            'https://www.google.com/maps/search/?api=1&query=$address');
                      },
                    ),
                    SizedBox(width: 10),
                    FloatingActionButton(
                      heroTag: "instagram",
                      child: Icon(Icons.photo_camera),
                      backgroundColor: Colors.white,
                      onPressed: () {
                        final instagram = barbershopData!['instagram'] ?? '';
                        launch(instagram);
                      },
                    ),
                  ],
                ),
                SizedBox(height: 10),
                Container(
                  padding: const EdgeInsets.symmetric(
                      vertical: 2, horizontal: 15),
                  decoration: BoxDecoration(
                    color: Colors.black,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start, // Align text left
                    children: [
                      Text(
                        barbershopData!['business_name'],
                        style: TextStyle(fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: Colors.white),
                        textAlign: TextAlign.left, // Ensure text is left-aligned
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
      bottomNavigationBar: Container(
        padding: EdgeInsets.all(16),
        color: Colors.black12,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Service Dropdown
            DropdownButton<String>(
              hint: Text("Select a Service", style: TextStyle(color: Colors.black)),
              value: selectedService,
              items: servicesData.map((service) {
                return DropdownMenuItem<String>(
                  value: service['name'],
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start, // Align dropdown items to the left
                    children: [
                      Icon(Icons.star, color: Colors.black),
                      SizedBox(width: 8),
                      Text(
                        service['name'] ?? 'Unnamed Service',
                        style: TextStyle(color: Colors.black),
                      ),
                    ],
                  ),
                );
              }).toList(),
              onChanged: (newValue) {
                setState(() {
                  selectedService = newValue;
                });
              },
            ),
            // Employee Dropdown
            DropdownButton<String>(
              hint: Text("Select an Employee", style: TextStyle(color: Colors.black)),
              value: selectedEmployee,
              items: employeesData.map((employee) {
                return DropdownMenuItem<String>(
                  value: employee['name'],
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start, // Align dropdown items to the left
                    children: [
                      Icon(Icons.person, color: Colors.black),
                      SizedBox(width: 8),
                      Text(
                        employee['name'] ?? 'Unnamed Employee',
                        style: TextStyle(color: Colors.black),
                      ),
                    ],
                  ),
                );
              }).toList(),
              onChanged: (newValue) {
                setState(() {
                  selectedEmployee = newValue;
                });
              },
            ),
            // Date Dropdown
            DropdownButton<String>(
              hint: Text("Select a Day", style: TextStyle(color: Colors.black)),
              value: selectedDay,
              items: generateFutureDays().map((day) {
                return DropdownMenuItem<String>(
                  value: day,
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start, // Align dropdown items to the left
                    children: [
                      Icon(Icons.calendar_today, color: Colors.black),
                      SizedBox(width: 8),
                      Text(day, style: TextStyle(color: Colors.black)),
                    ],
                  ),
                );
              }).toList(),
              onChanged: (newValue) {
                setState(() {
                  selectedDay = newValue;
                });
              },
            ),
            // Time Dropdown
            DropdownButton<String>(
              hint: Text("Select an Hour", style: TextStyle(color: Colors.black)),
              value: selectedHour,
              items: generateHours().map((hour) {
                return DropdownMenuItem<String>(
                  value: hour,
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start, // Align dropdown items to the left
                    children: [
                      Icon(Icons.access_time, color: Colors.black),
                      SizedBox(width: 8),
                      Text(hour, style: TextStyle(color: Colors.black)),
                    ],
                  ),
                );
              }).toList(),
              onChanged: (newValue) {
                setState(() {
                  selectedHour = newValue;
                });
              },
            ),
            // Order Now Button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () async {
                  if (selectedService != null && selectedEmployee != null &&
                      selectedHour != null && selectedDay != null) {
                    try {
                      DateTime selectedDateTime = DateFormat(
                          'EEEE, MMM d, yyyy').parse(selectedDay!);
                      DateTime orderDateTime = DateTime(
                        selectedDateTime.year,
                        selectedDateTime.month,
                        selectedDateTime.day,
                        int.parse(selectedHour!.split(':')[0]),
                      );

                      String formattedDateTime = DateFormat('yyyy-MM-dd HH:mm')
                          .format(orderDateTime);

                      DocumentReference orderRef = await FirebaseFirestore
                          .instance.collection('orders').add({
                        'store': userId,
                        'service': selectedService,
                        'employee': selectedEmployee,
                        'datetime': formattedDateTime,
                      });

                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => OrderUpdatePage(),
                        ),
                      );
                    } catch (e) {
                      print("Error saving order: $e");
                      ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('Failed to save order')));
                    }
                  } else {
                    ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Please select all options')));
                  }
                },
                child: Text(
                  'Order Now',
                  style: TextStyle(fontSize: 18),
                ),
                style: ElevatedButton.styleFrom(
                  foregroundColor: Colors.white,
                  backgroundColor: Colors.blue,
                  padding: EdgeInsets.zero,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.zero,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

}
