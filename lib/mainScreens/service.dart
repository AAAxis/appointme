import 'dart:io';
import 'package:driver_app/mainScreens/navigation.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';

class ServiceDetailsScreen extends StatefulWidget {
  @override
  _ServiceDetailsScreenState createState() => _ServiceDetailsScreenState();
}

class _ServiceDetailsScreenState extends State<ServiceDetailsScreen> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  List<Map<String, dynamic>> services = [];
  String message = '';
  final ImagePicker _picker = ImagePicker();
  XFile? selectedImage; // Change to a single selected image

  final List<String> predefinedImageUrls = [
    // Add your predefined image URLs here
    'https://polskoydm.pythonanywhere.com/static/mencut.jpeg',
    'https://polskoydm.pythonanywhere.com/static/womencut.jpeg',
    'https://polskoydm.pythonanywhere.com/static/beardtrim.jpeg',
    'https://polskoydm.pythonanywhere.com/static/coloring.jpeg',
  ];

  @override
  void initState() {
    super.initState();
    fetchServiceDetails();
  }

  Future<void> fetchServiceDetails() async {
    final currentUserId = _auth.currentUser!.uid;

    try {
      QuerySnapshot snapshot = await _firestore
          .collection('services')
          .where('userId', isEqualTo: currentUserId)
          .get();

      if (snapshot.docs.isNotEmpty) {
        services = snapshot.docs.map((doc) {
          Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
          data['id'] = doc.id;
          return data;
        }).toList();
        setState(() {
          message = '';
        });
      } else {
        setState(() {
          services = [];
          message = 'No services found';
        });
      }
    } catch (error) {
      print('Error fetching service details: $error');
      setState(() {
        message = 'Error fetching service details. Please try again later.';
      });
    }
  }

  Future<void> addService() async {
    final TextEditingController nameController = TextEditingController();
    final TextEditingController priceController = TextEditingController(text: '1'); // Default price is 1
    double price = 1;
    String? selectedImageUrl;

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text("Add Service"),
          content: Container(
            width: double.maxFinite,
            constraints: BoxConstraints(
              maxHeight: 400,
            ),
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  GridView.builder(
                    gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 5,
                      childAspectRatio: 1,
                    ),
                    shrinkWrap: true,
                    physics: NeverScrollableScrollPhysics(),
                    itemCount: predefinedImageUrls.length + 1,
                    itemBuilder: (context, index) {
                      return index < predefinedImageUrls.length
                          ? GestureDetector(
                        onTap: () {
                          setState(() {
                            selectedImageUrl = predefinedImageUrls[index]; // Set the selected image URL
                            selectedImage = null; // Reset selected image if a predefined one is chosen
                          });
                        },
                        child: Container(
                          height: 30,
                          width: 30,
                          decoration: BoxDecoration(
                            border: selectedImageUrl == predefinedImageUrls[index]
                                ? Border.all(color: Colors.blue, width: 2) // Blue border for selected image
                                : null,
                          ),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(8), // Optional: Rounded corners for images
                            child: Image.network(
                              predefinedImageUrls[index],
                              fit: BoxFit.cover,
                            ),
                          ),
                        ),
                      )
                          : IconButton(
                        icon: Icon(Icons.add, size: 30),
                        onPressed: () async {
                          XFile? pickedImage = await _picker.pickImage(source: ImageSource.gallery);
                          if (pickedImage != null) {
                            setState(() {
                              selectedImage = pickedImage; // Save the selected image
                              selectedImageUrl = null; // Reset predefined image selection
                            });
                          }
                        },
                      );
                    },
                  ),

                  if (selectedImage != null)
                    Container(
                      height: 30,
                      width: 30,
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.blue, width: 2),
                      ),
                      child: Image.file(File(selectedImage!.path), fit: BoxFit.cover),
                    ),
                  if (selectedImageUrl != null)
                    Container(
                      height: 30,
                      width: 30,
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.blue, width: 2),
                      ),
                      child: Image.network(selectedImageUrl!, fit: BoxFit.cover),
                    ),
                  TextField(
                    controller: nameController,
                    decoration: InputDecoration(labelText: 'Service'),
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: TextField(
                          controller: priceController,
                          decoration: InputDecoration(labelText: 'Price'),
                          keyboardType: TextInputType.number, // Ensure numeric keypad opens
                        ),
                      ),
                    ],
                  ),
                ],
              ),
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
                if ((selectedImageUrl != null || selectedImage != null) && nameController.text.isNotEmpty && priceController.text.isNotEmpty) {
                  String uploadImageUrl;

                  if (selectedImage != null) {
                    uploadImageUrl = await uploadImage(selectedImage!);
                  } else {
                    uploadImageUrl = selectedImageUrl!; // Use predefined image URL
                  }

                  Map<String, dynamic> serviceData = {
                    'image': uploadImageUrl, // Store as a single image
                    'name': nameController.text,
                    'price': double.parse(priceController.text),
                    'userId': _auth.currentUser!.uid,
                  };

                  await _firestore.collection('services').add(serviceData);
                  Navigator.of(context).pop();
                  fetchServiceDetails();
                }
              },
              child: Text("Add"),
            ),
          ],
        );
      },
    );
  }

  Future<void> deleteService(String serviceId) async {
    // Show a confirmation dialog before deleting the service
    bool confirm = await showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Confirm Deletion'),
          content: Text('Are you sure you want to delete this service?'),
          actions: <Widget>[
            TextButton(
              onPressed: () {
                Navigator.of(context).pop(false);
              },
              child: Text('Cancel'),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop(true);
              },
              child: Text('Delete'),
            ),
          ],
        );
      },
    );

    // Proceed with deletion if confirmed
    if (confirm) {
      try {
        await _firestore.collection('services').doc(serviceId).delete();
        fetchServiceDetails();
      } catch (error) {
        print('Error deleting service: $error');
      }
    }
  }

  Future<String> uploadImage(XFile image) async {
    try {
      final storageRef = FirebaseStorage.instance.ref();
      final fileName = DateTime.now().millisecondsSinceEpoch.toString();
      final imageRef = storageRef.child('services/$fileName');

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
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: message.isNotEmpty
            ? Center(child: Text(message, style: TextStyle(fontSize: 18, color: Colors.black)))
            : services.isEmpty
            ? Center(child: CircularProgressIndicator())
            : SingleChildScrollView(
          child: DataTable(
            columns: [
              DataColumn(label: Text('Image')),
              DataColumn(label: Text('Service')),
              DataColumn(label: Text('Price')),
              DataColumn(label: Text('Actions')),
            ],
            rows: services.map((service) {
              return DataRow(cells: [
                DataCell(
                  Image.network(
                    service['image'], // Access the single image URL
                    height: 50,
                    width: 50,
                    fit: BoxFit.cover,
                  ),
                ),
                DataCell(Text(service['name'])),
                DataCell(Text('\$${service['price'].toString()}')),
                DataCell(
                  Row(
                    children: [

                      IconButton(
                        icon: Icon(Icons.delete),
                        onPressed: () {
                          deleteService(service['id']);
                        },
                      ),
                    ],
                  ),
                ),
              ]);
            }).toList(),
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: addService,
        child: Icon(Icons.add),
      ),
    );
  }
}
