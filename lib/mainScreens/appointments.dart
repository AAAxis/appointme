import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import 'package:driver_app/mainScreens/drawer.dart';

class AppointmentsPage extends StatefulWidget {
  @override
  _AppointmentsPageState createState() => _AppointmentsPageState();
}

class _AppointmentsPageState extends State<AppointmentsPage> {
  List<DocumentSnapshot> orders = [];
  final String uid = FirebaseAuth.instance.currentUser!.uid;
  DateTime selectedDate = DateTime.now();
  String? selectedHour = '08:00'; // Preselect 8 AM
  TextEditingController employeeController = TextEditingController();
  TextEditingController phoneController = TextEditingController();
  TextEditingController serviceController = TextEditingController(text: 'barber'); // Preselect barber

  @override
  void initState() {
    super.initState();
    fetchOrders();
    _checkEmailVerification(); // Check email verification status
  }

  Future<void> fetchOrders() async {
    QuerySnapshot<Map<String, dynamic>> snapshot = await FirebaseFirestore
        .instance
        .collection('orders')
        .where('store', isEqualTo: uid) // Filter by store (UID)
        .get();

    setState(() {
      orders = snapshot.docs; // Get all orders for the UID
    });
  }

  Future<void> _checkEmailVerification() async {
    User? user = FirebaseAuth.instance.currentUser;
    if (user != null && !user.emailVerified) {
      // Show Snackbar if email is not verified after a slight delay
      Future.delayed(Duration.zero, () {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Email is not verified.'),
            duration: Duration(seconds: 5),
            action: SnackBarAction(
              label: 'Send Email',
              onPressed: () {
                user.sendEmailVerification().then((_) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Verification email sent!'),
                      duration: Duration(seconds: 3),
                    ),
                  );
                }).catchError((error) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Error sending email: $error'),
                      duration: Duration(seconds: 3),
                    ),
                  );
                });
              },
            ),
          ),
        );
      });
    }
  }

  DateTime? selectedDateTime; // Nullable because it may not be selected yet

  String get formattedDateT {
    if (selectedDateTime == null)
      return ''; // Return an empty string if no date is selected
    return DateFormat('yyyy-MM-dd').format(
        selectedDateTime!); // Format the selected date
  }

  // Get the first day of the current month
  DateTime getFirstDayOfMonth() {
    return DateTime(selectedDate.year, selectedDate.month, 1);
  }

  // Get the number of days in the current month
  int getDaysInMonth() {
    return DateTime(selectedDate.year, selectedDate.month + 1, 0).day;
  }

  // Build the calendar view
  Widget buildCalendar() {
    int daysInMonth = getDaysInMonth();
    DateTime firstDayOfMonth = getFirstDayOfMonth();

    List<Widget> dayWidgets = [];
    // Add empty widgets for the days before the first day of the month
    for (int i = 0; i < firstDayOfMonth.weekday - 1; i++) {
      dayWidgets.add(SizedBox());
    }

    // Add widgets for each day in the month
    for (int day = 1; day <= daysInMonth; day++) {
      dayWidgets.add(
        GestureDetector(
          onTap: () {
            setState(() {
              selectedDate =
                  DateTime(selectedDate.year, selectedDate.month, day);
            });
            showHourSelectionDialog(context);
          },
          child: Container(
            alignment: Alignment.center,
            decoration: BoxDecoration(
              border: Border.all(color: Colors.grey),
              color: selectedDate.day == day ? Colors.blue : null,
            ),
            child: Text('$day'),
          ),
        ),
      );
    }

    return Column(
      children: [
        // Month navigation
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            IconButton(
              icon: Icon(Icons.chevron_left),
              onPressed: () {
                setState(() {
                  selectedDate = DateTime(selectedDate.year, selectedDate.month - 1);
                });
              },
            ),
            Text(
              DateFormat('MMMM yyyy').format(selectedDate), // Display month name
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            IconButton(
              icon: Icon(Icons.chevron_right),
              onPressed: () {
                setState(() {
                  selectedDate = DateTime(selectedDate.year, selectedDate.month + 1);
                });
              },
            ),
          ],
        ),
        GridView.count(
          crossAxisCount: 7,
          children: dayWidgets,
          shrinkWrap: true, // Allows GridView to fit inside a column
        ),
      ],
    );
  }

  // Add this function to handle the new dialog with name, phone, and service inputs.
  void showHourSelectionDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: Text('Select Appointment'),
              content: SingleChildScrollView(
                child: Column(
                  children: [
                    // Hour selection dropdown
                    DropdownButtonFormField<String>(
                      decoration: InputDecoration(labelText: 'Select Hour'),
                      value: selectedHour,
                      items: List.generate(13, (index) {
                        // Generate hours from 8 AM to 8 PM
                        int hour = 8 + index;
                        String time = '${hour.toString().padLeft(2, '0')}:00';
                        return DropdownMenuItem<String>(
                          value: time,
                          child: Text(time),
                        );
                      }),
                      onChanged: (value) {
                        setState(() {
                          selectedHour = value;
                        });
                      },
                    ),
                    // Name input field
                    TextField(
                      controller: employeeController,
                      decoration: InputDecoration(labelText: 'Name'),
                    ),
                    // Phone input field
                    TextField(
                      controller: phoneController,
                      decoration: InputDecoration(labelText: 'Phone'),
                    ),
                    // Service selection dropdown
                    DropdownButtonFormField<String>(
                      decoration: InputDecoration(labelText: 'Select Service'),
                      value: serviceController.text.isEmpty
                          ? 'barber' // Default to barber
                          : serviceController.text,
                      items: ['barber', 'nails', 'paint'].map((String service) {
                        return DropdownMenuItem<String>(
                          value: service,
                          child: Text(service),
                        );
                      }).toList(),
                      onChanged: (value) {
                        setState(() {
                          serviceController.text = value!;
                        });
                      },
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: Text('Cancel'),
                ),
                TextButton(
                  onPressed: () {
                    if (selectedHour != null &&
                        employeeController.text.isNotEmpty &&
                        phoneController.text.isNotEmpty &&
                        serviceController.text.isNotEmpty) {
                      addAppointment(); // Submit the appointment if all fields are filled
                      Navigator.of(context).pop(); // Close dialog
                    } else {
                      // Show an error if any field is empty
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Please fill all fields')),
                      );
                    }
                  },
                  child: Text('Submit'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Future<void> addAppointment() async {
    String formattedDate = DateFormat('yyyy-MM-dd').format(selectedDate);
    await FirebaseFirestore.instance.collection('orders').add({
      'datetime': '$formattedDate $selectedHour',
      'employee': employeeController.text,
      'phone': phoneController.text,
      'service': serviceController.text,
      'status': 'confirmed',
      'store': uid,
    });
    fetchOrders(); // Refresh the list after adding the appointment
    clearFields(); // Clear the input fields after submission

    // Show a Snackbar notification for successful appointment creation
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Appointment successfully created!'),
        duration: Duration(seconds: 3),
      ),
    );
  }

  void clearFields() {
    employeeController.clear();
    phoneController.clear();
    serviceController.clear();
    selectedHour = '08:00'; // Reset hour selection to 8 AM
  }

  // New method to build the appointments list with swipe-to-delete functionality
  Widget buildAppointmentsList() {
    return Expanded(
      child: ListView.builder(
        itemCount: orders.length,
        itemBuilder: (context, index) {
          final order = orders[index];

          // Choose an icon based on the service
          IconData serviceIcon;
          switch (order['service']) {
            case 'barber':
              serviceIcon = Icons.person; // Use an icon for barber
              break;
            case 'nails':
              serviceIcon = Icons.spa; // Use an icon for nails
              break;
            case 'paint':
              serviceIcon = Icons.palette; // Use an icon for paint
              break;
            default:
              serviceIcon = Icons.error; // Fallback icon
          }

          return Dismissible(
            key: Key(order.id),
            background: Container(color: Colors.red),
            onDismissed: (direction) {
              FirebaseFirestore.instance.collection('orders').doc(order.id).delete();
              fetchOrders(); // Refresh the list after deletion
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Appointment deleted!'),
                  duration: Duration(seconds: 3),
                ),
              );
            },
            child: ListTile(
              leading: Icon(serviceIcon),
              title: Text('${order['employee']}'),
              subtitle: Text('${order['datetime']}'),
            ),
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Appointments'),
      ),
      drawer: CustomDrawer(), // Assuming you have a drawer implementation
      body: Column(
        children: [
          buildCalendar(), // Calendar view
          buildAppointmentsList(), // Appointments list
        ],
      ),
    );
  }
}
