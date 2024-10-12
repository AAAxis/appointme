import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class OrdersPage extends StatefulWidget {
  @override
  _OrdersPageState createState() => _OrdersPageState();
}

class _OrdersPageState extends State<OrdersPage> {
  List<DocumentSnapshot> orders = [];
  final String uid = FirebaseAuth.instance.currentUser!.uid;
  String? selectedDateTime;
  TextEditingController employeeController = TextEditingController();
  TextEditingController phoneController = TextEditingController();
  TextEditingController serviceController = TextEditingController();

  @override
  void initState() {
    super.initState();
    fetchOrders();
  }

  Future<void> fetchOrders() async {
    QuerySnapshot<Map<String, dynamic>> snapshot = await FirebaseFirestore.instance
        .collection('orders')
        .where('store', isEqualTo: uid)
        .get();

    setState(() {
      orders = snapshot.docs;
    });
  }

  Future<void> deleteOrder(String orderId) async {
    await FirebaseFirestore.instance.collection('orders').doc(orderId).delete();
    fetchOrders(); // Refresh the list after deletion
  }

  Future<void> updateOrderStatus(String orderId, bool isConfirmed) async {
    await FirebaseFirestore.instance.collection('orders').doc(orderId).update({
      'status': isConfirmed ? 'confirmed' : 'pending', // Update status based on checkbox
    });
    fetchOrders(); // Refresh the list after update
  }

  Future<void> addAppointment() async {
    await FirebaseFirestore.instance.collection('orders').add({
      'datetime': selectedDateTime,
      'employee': employeeController.text,
      'phone': phoneController.text,
      'service': serviceController.text,
      'status': 'confirmed', // Automatically setting the status to confirmed
      'store': uid,
    });
    fetchOrders(); // Refresh the list after adding
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: Icon(Icons.more_time_outlined), // Replace this with your custom icon
          onPressed: () {
            // Logic for the custom icon button
            // For example, you can open a drawer or navigate to another page
          },
        ),
        title: Text('Appointments'),

      ),

      body: Padding(
        padding: const EdgeInsets.only(top: 16.0), // Top margin
        child: orders.isEmpty
            ? Center(child: Text('No appointments found.'))
            : ListView.builder(
          itemCount: orders.length,
          itemBuilder: (context, index) {
            final order = orders[index];
            bool isConfirmed = order['status'] == 'confirmed'; // Check if status is confirmed
            String appointmentDate = order['datetime']; // Extract date

            return Dismissible(
              key: Key(order.id),
              direction: DismissDirection.endToStart,
              onDismissed: (direction) {
                deleteOrder(order.id);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Appointment deleted')),
                );
              },
              background: Container(
                color: Colors.red,
                alignment: Alignment.centerRight,
                padding: EdgeInsets.symmetric(horizontal: 20.0),
                child: Icon(Icons.delete, color: Colors.white),
              ),
              child: ListTile(
                leading: Checkbox(
                  value: isConfirmed,
                  onChanged: (bool? value) {
                    // Handle checkbox state change
                    setState(() {
                      updateOrderStatus(order.id, value ?? false); // Update Firestore status
                    });
                  },
                ),
                title: Text(order['employee'] ?? 'No Employee'),
                subtitle: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(order['service'] ?? 'No Service'),

                  ],
                ),
                trailing:     Text(appointmentDate), // Display appointment date
              ),
            );
          },
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          // Handle adding an appointment
          showAddAppointmentDialog(context);
        },
        child: Icon(Icons.add),
      ),
    );
  }

  void showAddAppointmentDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text('Add Appointment'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              DropdownButtonFormField<String>(
                decoration: InputDecoration(labelText: 'Select DateTime'),
                value: selectedDateTime,
                items: <String>[
                  '2024-09-28T00:40',
                  '2024-10-01T14:30',
                  '2024-10-03T09:00',
                ].map((String value) {
                  return DropdownMenuItem<String>(
                    value: value,
                    child: Text(value),
                  );
                }).toList(),
                onChanged: (value) {
                  setState(() {
                    selectedDateTime = value!;
                  });
                },
              ),
              TextField(
                controller: employeeController,
                decoration: InputDecoration(labelText: 'Employee'),
              ),
              TextField(
                controller: phoneController,
                decoration: InputDecoration(labelText: 'Phone'),
              ),
              TextField(
                controller: serviceController,
                decoration: InputDecoration(labelText: 'Service'),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop(); // Close the dialog
              },
              child: Text('Cancel'),
            ),
            TextButton(
              onPressed: () {
                addAppointment(); // Add the appointment to Firebase
                Navigator.of(context).pop(); // Close the dialog after adding
              },
              child: Text('Add'),
            ),
          ],
        );
      },
    );
  }
}
