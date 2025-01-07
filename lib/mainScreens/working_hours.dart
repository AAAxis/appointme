import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class Schedule {
  final String day;
  final String from;
  final String to;
  final bool working;

  Schedule({required this.day, required this.from, required this.to, required this.working});

  factory Schedule.fromMap(Map<String, dynamic> data) {
    return Schedule(
      day: data['day'],
      from: data['from'],
      to: data['to'],
      working: data['working'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'day': day,
      'from': from,
      'to': to,
      'working': working,
    };
  }
}

class SchedulePage extends StatefulWidget {
  @override
  _SchedulePageState createState() => _SchedulePageState();
}

class _SchedulePageState extends State<SchedulePage> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  late String userId;
  List<Schedule> schedules = [];

  @override
  void initState() {
    super.initState();
    userId = _auth.currentUser!.uid; // Get current authenticated user's ID
    fetchWorkingHours();
  }

  Future<void> fetchWorkingHours() async {
    try {
      DocumentSnapshot snapshot = await _firestore.collection('working_hours').doc(userId).get();
      if (snapshot.exists) {
        Map<String, dynamic> data = snapshot.data() as Map<String, dynamic>;
        if (data['workingHours'] != null) {
          schedules.clear(); // Clear previous schedules before fetching new ones
          (data['workingHours'] as Map<String, dynamic>).forEach((key, value) {
            schedules.add(Schedule(
              day: key,
              from: value['from'],
              to: value['to'],
              working: value['working'],
            ));
          });
        }
      }
      setState(() {});
    } catch (error) {
      print('Error fetching working hours: $error');
    }
  }

  Future<void> addSchedule() async {
    final TextEditingController clockInController = TextEditingController();
    final TextEditingController clockOutController = TextEditingController();
    String selectedDay = 'Monday';

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text("Add Schedule"),
          content: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                TextField(
                  controller: clockInController,
                  decoration: InputDecoration(labelText: 'Clock In (e.g., 08:00)'),
                ),
                TextField(
                  controller: clockOutController,
                  decoration: InputDecoration(labelText: 'Clock Out (e.g., 20:00)'),
                ),
                DropdownButton<String>(
                  value: selectedDay,
                  items: ['Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday'].map((day) {
                    return DropdownMenuItem<String>(
                      value: day,
                      child: Text(day),
                    );
                  }).toList(),
                  onChanged: (String? newValue) {
                    selectedDay = newValue!;
                  },
                ),
              ],
            ),
          ),
          actions: <Widget>[
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: Text("Cancel"),
            ),
            TextButton(
              onPressed: () async {
                if (clockInController.text.isNotEmpty && clockOutController.text.isNotEmpty) {
                  Schedule newSchedule = Schedule(
                    day: selectedDay,
                    from: clockInController.text,
                    to: clockOutController.text,
                    working: true, // Default to true, change as needed
                  );
                  await _firestore.collection('working_hours').doc(userId).update({
                    'workingHours.${newSchedule.day}': newSchedule.toMap(),
                  });
                  Navigator.of(context).pop();
                  fetchWorkingHours(); // Refresh the schedule list
                }
              },
              child: Text("Add"),
            ),
          ],
        );
      },
    );
  }

  Future<void> deleteSchedule(String day) async {
    await _firestore.collection('working_hours').doc(userId).update({
      'workingHours.$day': FieldValue.delete(),
    });
    fetchWorkingHours(); // Refresh the schedule list
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Datetime'),

      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: schedules.isEmpty
            ? Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                'No schedules found.',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 10),
              Text(
                'Please add a schedule.',
                style: TextStyle(fontSize: 16),
              ),
            ],
          ),
        )
            : ListView.builder(
          itemCount: schedules.length,
          itemBuilder: (context, index) {
            Schedule schedule = schedules[index];
            return Dismissible(
              key: Key(schedule.day),
              direction: DismissDirection.endToStart,
              background: Container(
                color: Colors.red,
                alignment: Alignment.centerRight,
                padding: EdgeInsets.symmetric(horizontal: 20.0),
                child: Icon(
                  Icons.delete,
                  color: Colors.white,
                ),
              ),
              confirmDismiss: (direction) async {
                return await showDialog(
                  context: context,
                  builder: (BuildContext context) {
                    return AlertDialog(
                      title: Text("Confirm"),
                      content: Text("Are you sure you want to delete this schedule?"),
                      actions: <Widget>[
                        TextButton(
                          onPressed: () => Navigator.of(context).pop(false),
                          child: Text("Cancel"),
                        ),
                        TextButton(
                          onPressed: () => Navigator.of(context).pop(true),
                          child: Text("Delete"),
                        ),
                      ],
                    );
                  },
                );
              },
              onDismissed: (direction) {
                deleteSchedule(schedule.day); // Delete schedule
              },
              child: Card(
                margin: EdgeInsets.symmetric(vertical: 8),
                child: ListTile(
                  title: Text('${schedule.day}'),
                  subtitle: Text('${schedule.working ? 'Working' : 'Not Working'}: ${schedule.from} - ${schedule.to}'),
                  trailing: Icon(
                    schedule.working ? Icons.check_circle : Icons.cancel,
                    color: schedule.working ? Colors.green : Colors.red,
                  ),
                ),
              ),
            );
          },
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: addSchedule, // Add schedule button
        child: Icon(Icons.add),
        shape: CircleBorder(),
        backgroundColor: Colors.blue,
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat, // Position the button on the right
    );
  }

}
