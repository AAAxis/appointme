import 'dart:io';
import 'package:driver_app/mainScreens/navigation.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';

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
  final ImagePicker _picker = ImagePicker(); // Image picker for selecting images
  XFile? selectedImage; // Variable to store the selected image

  @override
  void initState() {
    super.initState();
    fetchEmployeeDetails();
  }

  void fetchEmployeeDetails() {
    final currentUserId = _auth.currentUser!.uid;

    // Use Firestore's snapshot method to listen for real-time updates
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
          message = 'No employees found for this user.';
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
        return StatefulBuilder(
          // Use StatefulBuilder to manage the state within the dialog
          builder: (BuildContext context, StateSetter setState) {
            return AlertDialog(
              title: Text("Add Employee"),
              content: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Image selection
                    selectedImage == null
                        ? TextButton(
                      onPressed: () async {
                        selectedImage = await _picker.pickImage(source: ImageSource.gallery);
                        setState(() {}); // Update the state inside the dialog
                      },
                      child: Text("Select Image"),
                    )
                        : Column(
                      children: [
                        Image.file(
                          File(selectedImage!.path),
                          height: 100,
                          fit: BoxFit.cover,
                        ),
                        TextButton(
                          onPressed: () async {
                            selectedImage = await _picker.pickImage(source: ImageSource.gallery);
                            setState(() {}); // Update the state inside the dialog
                          },
                          child: Text("Change Image"),
                        ),
                      ],
                    ),
                    TextField(
                      controller: nameController,
                      decoration: InputDecoration(labelText: 'Employee Name'),
                    ),
                    TextField(
                      controller: phoneController,
                      decoration: InputDecoration(labelText: 'Phone'),
                      keyboardType: TextInputType.phone,
                    ),
                    // Display services with checkboxes
                    services.isEmpty
                        ? Container(
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      child: Text('Fetching services...', style: TextStyle(fontStyle: FontStyle.italic)),
                    )
                        : Column(
                      children: services.map((service) {
                        return CheckboxListTile(
                          title: Text(service['name']), // Display service name
                          value: selectedServiceIds.contains(service['id']), // Checkbox value
                          onChanged: (bool? selected) {
                            setState(() {
                              if (selected == true) {
                                selectedServiceIds.add(service['id']); // Add service ID
                              } else {
                                selectedServiceIds.remove(service['id']); // Remove service ID
                              }
                            });
                          },
                        );
                      }).toList(),
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
                    if (selectedImage != null &&
                        nameController.text.isNotEmpty &&
                        phoneController.text.isNotEmpty &&
                        selectedServiceIds.isNotEmpty) { // Ensure at least one service is selected
                      String uploadImageUrl = await uploadImage(selectedImage!);

                      if (uploadImageUrl.isNotEmpty) {
                        // Create the employee data with attached services
                        Map<String, dynamic> employeeData = {
                          'image': uploadImageUrl,
                          'name': nameController.text,
                          'phone': phoneController.text,
                          'userId': _auth.currentUser!.uid,
                          'services': selectedServiceIds, // Store as a list of service IDs
                        };

                        await _firestore.collection('employees').add(employeeData);
                        Navigator.of(context).pop();
                        fetchEmployeeDetails(); // Refresh the employee details
                      } else {
                        setState(() {
                          message = 'Failed to upload image. Please try again.';
                        });
                      }
                    }
                  },
                  child: Text("Add"),
                ),
              ],
            );
          },
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

  Future<String> uploadImage(XFile image) async {
    try {
      final storageRef = FirebaseStorage.instance.ref();
      final fileName = DateTime.now().millisecondsSinceEpoch.toString();
      final imageRef = storageRef.child('employees/$fileName');

      await imageRef.putFile(File(image.path));

      String downloadUrl = await imageRef.getDownloadURL();
      return downloadUrl;
    } catch (error) {
      print('Error uploading image: $error');
      return '';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Employee Details'),
        leading: IconButton(
          icon: Icon(Icons.arrow_back),
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => Navigation()),
            );
          },
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: message.isNotEmpty
            ? Center(child: Text(message, style: TextStyle(fontSize: 18, color: Colors.red)))
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
                leading: Image.network(
                  employee['image'],
                  width: 50,
                  height: 50,
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
