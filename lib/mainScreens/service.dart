import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

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
  XFile? selectedImage;

  final List<String> predefinedImageUrls = [
    'https://polskoydm.pythonanywhere.com/static/mencut.jpeg',
    'https://polskoydm.pythonanywhere.com/static/womencut.jpeg',
    'https://polskoydm.pythonanywhere.com/static/beardtrim.jpeg',
    'https://polskoydm.pythonanywhere.com/static/coloring.jpeg',
  ];

  // Preselect the first image URL
  String? selectedImageUrl;

  @override
  void initState() {
    super.initState();
    fetchServiceDetails();
    selectedImageUrl = predefinedImageUrls[0]; // Preselect the first image
  }

  Future<void> fetchServiceDetails() async {
    try {
      QuerySnapshot querySnapshot = await _firestore
          .collection('services')
          .where('userId', isEqualTo: _auth.currentUser!.uid)
          .get();

      setState(() {
        services = querySnapshot.docs.map((doc) {
          return {
            'id': doc.id,
            'image': doc['image'],
            'name': doc['name'],
            'price': doc['price'],
          };
        }).toList();
        message = services.isEmpty ? 'No services found.' : '';
      });
    } catch (e) {
      setState(() {
        message = 'Failed to load services.';
      });
    }
  }

  Future<void> deleteService(String id) async {
    await _firestore.collection('services').doc(id).delete();
    fetchServiceDetails();
  }

  Future<String> uploadImage(XFile image) async {
    // Implement your image upload logic here
    // This function should return the uploaded image URL
    return "uploaded_image_url"; // Placeholder
  }

  Future<void> addService() async {
    final TextEditingController nameController = TextEditingController();
    final TextEditingController priceController = TextEditingController(text: '1'); // Default price is 1

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return StatefulBuilder( // Using StatefulBuilder to maintain state within the dialog
          builder: (context, setState) {
            return AlertDialog(
              title: Text("Add Service"),
              content: Container(
                width: double.maxFinite,
                constraints: BoxConstraints(
                  maxHeight: 450,
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
                        itemCount: predefinedImageUrls.length + 1, // +1 for custom image picker
                        itemBuilder: (context, index) {
                          return index < predefinedImageUrls.length
                              ? GestureDetector(
                            onTap: () {
                              setState(() {
                                selectedImageUrl = predefinedImageUrls[index]; // Select predefined image
                                selectedImage = null; // Reset custom image selection
                              });
                            },
                            child: Container(
                              height: 30,
                              width: 30,
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(8), // Fixed radius
                                border: selectedImageUrl == predefinedImageUrls[index]
                                    ? Border.all(color: Colors.blue, width: 2) // Show blue border for selected image
                                    : Border.all(color: Colors.transparent, width: 2), // No border for unselected
                              ),
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(8), // Fixed radius
                                child: Image.network(
                                  predefinedImageUrls[index],
                                  fit: BoxFit.cover,
                                ),
                              ),
                            ),
                          )
                              : GestureDetector(
                            onTap: () async {
                              XFile? pickedImage = await _picker.pickImage(source: ImageSource.gallery);
                              if (pickedImage != null) {
                                setState(() {
                                  selectedImage = pickedImage; // Set custom image
                                  selectedImageUrl = null; // Reset predefined image selection
                                });
                              }
                            },
                            child: Container(
                              height: 30,
                              width: 30,
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(8),
                                border: selectedImage != null
                                    ? Border.all(color: Colors.blue, width: 2) // Blue border when custom image is selected
                                    : Border.all(color: Colors.transparent, width: 2), // Transparent border when not selected
                              ),
                              child: Icon(Icons.add, size: 30), // Add icon
                            ),
                          );
                        },
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
                    if ((selectedImageUrl != null || selectedImage != null) &&
                        nameController.text.isNotEmpty &&
                        priceController.text.isNotEmpty) {
                      String uploadImageUrl;

                      if (selectedImage != null) {
                        uploadImageUrl = await uploadImage(selectedImage!);
                      } else {
                        uploadImageUrl = selectedImageUrl!; // Use predefined image URL
                      }

                      Map<String, dynamic> serviceData = {
                        'image': uploadImageUrl,
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
      },
    );


  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(

        title: Text('Services Library'),
      ),
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
