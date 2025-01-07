import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class EmployeeDetailsScreen extends StatefulWidget {
  @override
  _EmployeeDetailsScreenState createState() => _EmployeeDetailsScreenState();
}

class _EmployeeDetailsScreenState extends State<EmployeeDetailsScreen> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  List<Map<String, dynamic>> employees = []; // List to store fetched employees
  List<Map<String, dynamic>> services = []; // List to store fetched services
  String message = ''; // Message to display when no employees are found
  final String hardcodedImageUrl = 'https://polskoydm.pythonanywhere.com/static/images.jpeg'; // Hardcoded image URL

  @override
  void initState() {
    super.initState();
    fetchEmployeeDetails();
  }

  void fetchEmployeeDetails() {
    final currentUserId = _auth.currentUser!.uid;

    _firestore
        .collection('employees')
        .where('userId', isEqualTo: currentUserId)
        .snapshots()
        .listen((snapshot) {
      if (snapshot.docs.isNotEmpty) {
        employees = snapshot.docs.map((doc) {
          Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
          data['id'] = doc.id;
          return data;
        }).toList();
        setState(() {
          message = '';
        });
      } else {
        setState(() {
          employees = [];
          message = 'No employees found';
        });
      }
    }, onError: (error) {
      print('Error fetching employee details: $error');
      setState(() {
        message = 'Error fetching employee details. Please try again later.';
      });
    });
  }

  Future<void> fetchServiceDetails() async {
    final currentUserId = _auth.currentUser!.uid; // Get the current user's UID
    try {
      final serviceSnapshot = await _firestore
          .collection('services')
          .where('userId', isEqualTo: currentUserId) // Filter services by UID
          .get();

      services = serviceSnapshot.docs.map((doc) {
        Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
        data['id'] = doc.id;
        return data;
      }).toList();

      print('Fetched services: $services'); // Debugging print
      setState(() {}); // Update the UI whenever services change
    } catch (error) {
      print('Error fetching service details: $error');
    }
  }

  void addEmployee() async {
    final TextEditingController nameController = TextEditingController();
    final TextEditingController phoneController = TextEditingController();
    List<String> selectedServiceIds = []; // Variable to store selected service IDs

    // Fetch services once the dialog is opened
    await fetchServiceDetails();

    // Show the dialog to add employee
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text("Add Employee"),
          content: StatefulBuilder(
            builder: (context, setState) {
              return SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    TextField(
                      controller: nameController,
                      decoration: InputDecoration(labelText: 'Name'),
                    ),
                    TextField(
                      controller: phoneController,
                      decoration: InputDecoration(labelText: 'Phone'),
                      keyboardType: TextInputType.phone,
                    ),
                    // Display services with bubbles
                    services.isEmpty
                        ? Container(
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      child: Text(
                        'Fetching services...',
                        style: TextStyle(fontStyle: FontStyle.italic),
                      ),
                    )
                        : Wrap( // Use Wrap for a more compact arrangement of the bubbles
                      spacing: 8.0, // Horizontal space between bubbles
                      runSpacing: 8.0, // Vertical space between bubbles
                      children: services.map((service) {
                        final isSelected = selectedServiceIds.contains(service['id']);
                        return GestureDetector(
                          onTap: () {
                            setState(() {
                              if (isSelected) {
                                selectedServiceIds.remove(service['id']); // Unselect the service
                              } else {
                                selectedServiceIds.add(service['id']); // Select the service
                              }
                            });
                          },
                          child: Container(
                            margin: const EdgeInsets.symmetric(vertical: 4), // Reduced margin
                            padding: const EdgeInsets.all(8), // Reduced padding
                            decoration: BoxDecoration(
                              color: isSelected ? Colors.green : Colors.grey, // Background color based on selection
                              borderRadius: BorderRadius.circular(15), // Adjusted corner radius for smaller bubbles
                              border: Border.all(color: isSelected ? Colors.black : Colors.red),
                            ),
                            child: Text(
                              service['name'],
                              style: TextStyle(
                                color: isSelected ? Colors.white : Colors.black, // Text color based on selection
                                fontSize: 12, // Reduced text size to fit smaller bubbles
                              ),
                            ),
                          ),
                        );
                      }).toList(),
                    ),

                  ],
                ),
              );
            },
          ),
          actions: <Widget>[
            TextButton(
              onPressed: () {
                Navigator.of(context).pop(); // Close the dialog
              },
              child: Text("Cancel"),
            ),
            TextButton(
              onPressed: () async {
                if (nameController.text.isNotEmpty &&
                    phoneController.text.isNotEmpty &&
                    selectedServiceIds.isNotEmpty) { // Ensure at least one service is selected
                  // Create the employee data with the hardcoded image URL
                  Map<String, dynamic> employeeData = {
                    'name': nameController.text,
                    'phone': phoneController.text,
                    'userId': _auth.currentUser!.uid,
                    'services': selectedServiceIds, // Store as a list of service IDs
                  };

                  await _firestore.collection('employees').add(employeeData);

                  // Close the dialog after successfully adding the employee
                  Navigator.of(context).pop();
                  fetchEmployeeDetails(); // Refresh the employee details
                } else {
                  // Optional: Show an alert if any field is empty
                  showDialog(
                    context: context,
                    builder: (BuildContext context) {
                      return AlertDialog(
                        title: Text("Error"),
                        content: Text("Please fill in all fields and select at least one service."),
                        actions: <Widget>[
                          TextButton(
                            onPressed: () {
                              Navigator.of(context).pop(); // Close error dialog
                            },
                            child: Text("OK"),
                          ),
                        ],
                      );
                    },
                  );
                }
              },
              child: Text("Add"),
            ),
          ],
        );
      },
    );
  }

  Future<void> deleteEmployee(String employeeId) async {
    try {
      await _firestore.collection('employees').doc(employeeId).delete();
      fetchEmployeeDetails(); // Refresh the employee list after deletion
    } catch (error) {
      print('Error deleting employee: $error');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Employees'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: message.isNotEmpty
            ? Center(child: Text(message, style: TextStyle(fontSize: 18, color: Colors.black)))
            : employees.isEmpty
            ? Center(child: CircularProgressIndicator())
            : ListView.builder(
          itemCount: employees.length,
          itemBuilder: (context, index) {
            final employee = employees[index];
            return Card(
              margin: const EdgeInsets.symmetric(vertical: 8),
              child: ListTile(
                contentPadding: const EdgeInsets.all(16),
                leading: // Hardcoded image display
                Image.asset(
                  'images/images.jpeg',  // Replace with your actual image path
                  height: 100,
                  fit: BoxFit.cover,
                ),

                title: Text(employee['name']),
                subtitle: Text(
                  '${employee['phone']} (Service IDs: ${employee['services']?.join(", ") ?? 'None'})',
                ),
                trailing: IconButton(
                  icon: Icon(Icons.delete, color: Colors.red),
                  onPressed: () {
                    deleteEmployee(employee['id']);
                  },
                ),
              ),
            );
          },
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: addEmployee,
        backgroundColor: Colors.blue,
        child: Icon(Icons.add),
      ),
    );
  }
}
