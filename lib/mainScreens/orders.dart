import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart'; // For date formatting

class OrdersPage extends StatefulWidget {
  @override
  _OrdersPageState createState() => _OrdersPageState();
}

class _OrdersPageState extends State<OrdersPage> {
  List<DocumentSnapshot> orders = [];
  final String uid = FirebaseAuth.instance.currentUser!.uid;
  DateTime selectedDate = DateTime.now();
  String? selectedHour;
  TextEditingController employeeController = TextEditingController();
  TextEditingController phoneController = TextEditingController();
  TextEditingController serviceController = TextEditingController();

  @override
  void initState() {
    super.initState();
    fetchOrders();
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

  DateTime? selectedDateTime; // Nullable because it may not be selected yet

  String get formattedDateT {
    if (selectedDateTime == null) return ''; // Return an empty string if no date is selected
    return DateFormat('yyyy-MM-dd').format(selectedDateTime!); // Format the selected date
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

    return GridView.count(
      crossAxisCount: 7,
      children: dayWidgets,
      shrinkWrap: true, // Allows GridView to fit inside a column
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
              title: Text('Select Appointment Details'),
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
                          ? null
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
  }

  void clearFields() {
    employeeController.clear();
    phoneController.clear();
    serviceController.clear();
    selectedHour = null; // Reset hour selection
  }

  // New method to build the appointments list with swipe-to-delete functionality
  Widget buildAppointmentsList() {
    return Expanded(
      child: ListView.builder(
        itemCount: orders.length,
        itemBuilder: (context, index) {
          final order = orders[index];
          return Dismissible(
            key: Key(order.id), // Unique key for each item
            background: Container(color: Colors.red, alignment: Alignment.centerRight, padding: EdgeInsets.symmetric(horizontal: 20), child: Icon(Icons.delete, color: Colors.white)),
            onDismissed: (direction) async {
              // Remove the item from Firestore
              await FirebaseFirestore.instance.collection('orders').doc(order.id).delete();
              // Remove the item from the local list
              setState(() {
                orders.removeAt(index);
              });
              // Show a snackbar message
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('Appointment deleted')),
              );
            },
            child: ListTile(
              title: Text(order['employee'] ?? 'Unknown Employee'),
              subtitle: Text(
                  'Service: ${order['service'] ?? 'N/A'}, Phone: ${order['phone'] ?? 'N/A'}, Date: ${order['datetime'] ?? 'N/A'}'),
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
        actions: [
          IconButton(
            icon: Icon(Icons.arrow_back),
            onPressed: () {
              setState(() {
                selectedDate =
                    DateTime(selectedDate.year, selectedDate.month - 1);
              });
            },
          ),
          IconButton(
            icon: Icon(Icons.arrow_forward),
            onPressed: () {
              setState(() {
                selectedDate =
                    DateTime(selectedDate.year, selectedDate.month + 1);
              });
            },
          ),
        ],
      ),
      body: Column(
        children: [
          Text(
            DateFormat('MMMM yyyy').format(selectedDate),
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          buildCalendar(),
          SizedBox(height: 20),
          if (selectedHour != null) ...[
            Text('Selected DateTime: ${DateFormat('yyyy-MM-dd').format(selectedDate)} $selectedHour'),
            ElevatedButton(
              onPressed: () => showHourSelectionDialog(context), // Open dialog
              child: Text('Add Appointment'),
            ),
          ],
          buildAppointmentsList(), // Display the list of appointments
        ],
      ),
    );
  }
}
