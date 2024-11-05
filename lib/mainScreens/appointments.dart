import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class AppointmentsPage extends StatefulWidget {
  @override
  _AppointmentsPageState createState() => _AppointmentsPageState();
}

class _AppointmentsPageState extends State<AppointmentsPage> {
  final String userId = FirebaseAuth.instance.currentUser?.uid ?? "";
  String selectedFilter = 'All';

  // Function to calculate the start of the current week
  DateTime getStartOfWeek(DateTime date) => date.subtract(Duration(days: date.weekday - 1));

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('My Appointments'),
      ),
      body: Column(
        children: [
          // Dropdown for filtering
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: DropdownButton<String>(
              value: selectedFilter,
              onChanged: (value) {
                setState(() {
                  selectedFilter = value!;
                });
              },
              items: [
                DropdownMenuItem(value: 'All', child: Text('All')),
                DropdownMenuItem(value: 'Today', child: Text('Today')),
                DropdownMenuItem(value: 'This Week', child: Text('This Week')),
              ],
            ),
          ),
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('orders')
                  .where('store', isEqualTo: userId)
                  .snapshots(),
              builder: (context, snapshot) {
                print(userId); // Print userId to the console

                if (!snapshot.hasData) {
                  return Center(child: CircularProgressIndicator());
                }

                List<QueryDocumentSnapshot> appointments = snapshot.data!.docs;

                // Apply filter based on selectedFilter
                DateTime now = DateTime.now();
                appointments = appointments.where((doc) {
                  final data = doc.data() as Map<String, dynamic>;
                  final dateTimeStr = data['datetime'];
                  if (dateTimeStr == null) return false;

                  try {
                    final appointmentDate = DateTime.parse(dateTimeStr);

                    if (selectedFilter == 'Today') {
                      return appointmentDate.day == now.day &&
                          appointmentDate.month == now.month &&
                          appointmentDate.year == now.year;
                    } else if (selectedFilter == 'This Week') {
                      DateTime startOfWeek = getStartOfWeek(now);
                      DateTime endOfWeek = startOfWeek.add(Duration(days: 6));
                      return appointmentDate.isAfter(startOfWeek) &&
                          appointmentDate.isBefore(endOfWeek);
                    }
                  } catch (e) {
                    print("Error parsing date: $e");
                    return false;
                  }
                  return true; // 'All' filter shows all appointments
                }).toList();

                if (appointments.isEmpty) {
                  return Center(child: Text("No Appointments Found"));
                }

                return ListView.builder(
                  itemCount: appointments.length,
                  itemBuilder: (context, index) {
                    final appointment = appointments[index];
                    final appointmentData = appointment.data() as Map<String, dynamic>;

                    return Dismissible(
                      key: Key(appointment.id),
                      direction: DismissDirection.endToStart,
                      background: Container(
                        color: Colors.red,
                        alignment: Alignment.centerRight,
                        padding: EdgeInsets.symmetric(horizontal: 20),
                        child: Icon(Icons.delete, color: Colors.white),
                      ),
                      onDismissed: (direction) async {
                        await FirebaseFirestore.instance
                            .collection('orders')
                            .doc(appointment.id)
                            .delete();
                        ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text('Appointment deleted')));
                      },
                      child: Card(
                        margin: EdgeInsets.symmetric(vertical: 8, horizontal: 16),
                        color: Colors.blueAccent.withOpacity(0.2),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(15)),
                        child: ListTile(
                          leading: CircleAvatar(
                            backgroundColor: Colors.blueAccent,
                            child: Icon(Icons.calendar_today, color: Colors.white),
                          ),
                          title: Text(
                            appointmentData['service'] ?? 'Service',
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              SizedBox(height: 4),
                              Text("Employee: ${appointmentData['employee'] ?? 'N/A'}"),
                              SizedBox(height: 4),
                              Text("Date & Time: ${appointmentData['datetime'] ?? 'N/A'}"),
                            ],
                          ),
                          trailing: Icon(Icons.arrow_forward_ios,
                              size: 16, color: Colors.grey),
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          )
        ],
      ),
    );
  }
}
