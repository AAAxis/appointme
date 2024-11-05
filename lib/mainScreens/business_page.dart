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
  List<Map<String, dynamic>> servicesData = []; // Store fetched services
  String? selectedService; // Store selected service name as a string
  String? userId; // State variable to hold the UID
  List<Map<String, dynamic>> employeesData = []; // Store fetched employees
  String? selectedEmployee; // Store selected employee name as a string
  String? selectedHour; // Selected hour
  String? selectedDay; // Selected day

  @override
  void initState() {
    super.initState();
    fetchServicesData();
    fetchEmployeesData(); // Fetch employees data
    fetchBarbershopData();
    selectedHour = generateHours()[0]; // Preselect first available hour
    selectedDay = generateFutureDays()[0]; // Preselect first available day
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
          employeesData = querySnapshot.docs.map((doc) =>
          doc.data() as Map<String, dynamic>).toList();
          if (employeesData.isNotEmpty) {
            selectedEmployee = employeesData[0]['name']; // Preselect the first employee name
          }
        });
      } else {
        print("No user is currently signed in.");
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
          servicesData = querySnapshot.docs.map((doc) =>
          doc.data() as Map<String, dynamic>).toList();
          if (servicesData.isNotEmpty) {
            selectedService = servicesData[0]['name']; // Preselect the first service name
          }
        });
      } else {
        print("No user is currently signed in.");
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
        } else {
          print('No such document!');
        }
      } else {
        print("No user is currently signed in.");
      }
    } catch (e) {
      print("Error fetching barbershop data: $e");
    }
  }


  List<String> generateHours() {
    List<String> hours = [];
    for (int hour = 8; hour <= 20; hour++) {
      hours.add('${hour % 24}:00'); // Add hours from 8 AM to 8 PM
    }
    return hours;
  }

  List<String> generateFutureDays() {
    List<String> days = [];
    DateTime now = DateTime.now();
    for (int i = 0; i < 7; i++) {
      DateTime futureDate = now.add(Duration(days: i));
      days.add(DateFormat('EEEE, MMM d, yyyy').format(futureDate)); // Include year in the format
    }
    return days;
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

          Container(
            decoration: BoxDecoration(
              image: DecorationImage(
                image: AssetImage('images/tesla.jpeg'), // Use AssetImage for local image
                fit: BoxFit.cover,
              ),
            ),

          ),

          SingleChildScrollView(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                SizedBox(height: 80),
                // Centered Rounded Image
                Container(
                  padding: EdgeInsets.all(16),
                  alignment: Alignment.center,
                  child: ClipOval(
                    child: Image.network(
                      barbershopData!['image_url'],
                      width: 100,
                      height: 100,
                      fit: BoxFit.cover,
                    ),
                  ),
                ),
                // Centered Barbershop name and service
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Text(
                    barbershopData!['business_name'],
                    style: TextStyle(fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Colors.white),
                    textAlign: TextAlign.center,
                  ),
                ),
                SizedBox(height: 10),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Text(
                    barbershopData!['service'] ?? 'No type provided',
                    style: TextStyle(color: Colors.white),
                    textAlign: TextAlign.center,
                  ),

                ),
                SizedBox(height: 20),
                Positioned(
                  left: 0,
                  right: 0,
                  bottom: 10,
                  // Adjust this value to position the buttons higher or lower
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    // Center the buttons horizontally
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
                      SizedBox(width: 10), // Space between buttons
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
                      SizedBox(width: 10), // Space between buttons
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
                ),

              ],
            ),
          ),
          // Action buttons overlay on top of the background

        ],
      ),
      // Combined Bottom AppBar for dropdowns and order button
      bottomNavigationBar: Container(
        padding: EdgeInsets.all(16),
        color: Colors.black12,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Dropdown for services
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                // Action buttons overlay on top of the background

                Expanded(
                  child: DropdownButton<String>(
                    hint: Text("Select a Service", style: TextStyle(color: Colors.black)),
                    value: selectedService,
                    items: servicesData.map((service) {
                      return DropdownMenuItem<String>(
                        value: service['name'], // Store only the name
                        child: Row(
                          children: [
                            Icon(Icons.star, color: Colors.black), // Icon for service
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
                        selectedService = newValue; // Update selected service name
                      });
                    },
                  ),
                ),
              ],
            ),
            // Dropdown for employees
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                Expanded(
                  child: DropdownButton<String>(
                    hint: Text("Select an Employee", style: TextStyle(color: Colors.black)),
                    value: selectedEmployee,
                    items: employeesData.map((employee) {
                      return DropdownMenuItem<String>(
                        value: employee['name'], // Store only the name
                        child: Row(
                          children: [
                            Icon(Icons.person, color: Colors.black), // Icon for employee
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
                        selectedEmployee = newValue; // Update selected employee name
                      });
                    },
                  ),
                ),
              ],
            ),
            // Dropdown for days
            // Dropdown for days
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                Expanded(
                  child: DropdownButton<String>(
                    hint: Text("Select a Day", style: TextStyle(color: Colors.black)),
                    value: selectedDay,
                    items: generateFutureDays().map((day) {
                      return DropdownMenuItem<String>(
                        value: day,
                        child: Row(
                          children: [
                            Icon(Icons.calendar_today, color: Colors.black), // Icon for day
                            SizedBox(width: 8),
                            Text(
                              day,
                              style: TextStyle(color: Colors.black),
                            ),
                          ],
                        ),
                      );
                    }).toList(),
                    onChanged: (newValue) {
                      setState(() {
                        selectedDay = newValue; // Update selected day
                      });
                    },
                  ),
                ),
              ],
            ),     // Dropdown for hours
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                Expanded(
                  child: DropdownButton<String>(
                    hint: Text("Select an Hour", style: TextStyle(color: Colors.black)),
                    value: selectedHour,
                    items: generateHours().map((hour) {
                      return DropdownMenuItem<String>(
                        value: hour,
                        child: Row(
                          children: [
                            Icon(Icons.access_time, color: Colors.black), // Icon for hour
                            SizedBox(width: 8),
                            Text(
                              hour,
                              style: TextStyle(color: Colors.black),
                            ),
                          ],
                        ),
                      );
                    }).toList(),
                    onChanged: (newValue) {
                      setState(() {
                        selectedHour = newValue; // Update selected hour
                      });
                    },
                  ),
                ),
              ],
            ),

            // Full-width Square Order button
            SizedBox(height: 20),

      SizedBox(
      width: double.infinity,
        child: ElevatedButton(
          onPressed: () async {
            if (selectedService != null && selectedEmployee != null && selectedHour != null && selectedDay != null) {
              // Proceed to order
              try {
                // Ensure the selectedDay includes the year when parsing
                DateTime selectedDateTime = DateFormat('EEEE, MMM d, yyyy').parse(selectedDay!);
                DateTime orderDateTime = DateTime(
                  selectedDateTime.year,
                  selectedDateTime.month,
                  selectedDateTime.day,
                  int.parse(selectedHour!.split(':')[0]), // Get hour
                );


                // Format the DateTime to "yyyy-MM-dd HH:mm"
                String formattedDateTime = DateFormat('yyyy-MM-dd HH:mm').format(orderDateTime);

                // Save order with formatted DateTime
                DocumentReference orderRef = await FirebaseFirestore.instance.collection('orders').add({
                  'store': userId, // Store the user's UID
                  'service': selectedService, // Store the selected service name
                  'employee': selectedEmployee, // Store the selected employee name
                  'datetime': formattedDateTime,

                     });

                // Navigate to the next page and pass the document ID
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => OrderUpdatePage()
                  ),
                );

              } catch (e) {
                print("Error saving order: $e");
                ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed to save order')));
              }
            } else {
              ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Please select all options')));
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