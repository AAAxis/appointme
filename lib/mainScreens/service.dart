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
  XFile? selectedImage;

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
          message = 'No services found for this user.';
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
    final TextEditingController priceController = TextEditingController();

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text("Add Service"),
          content: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                selectedImage == null
                    ? TextButton(
                  onPressed: () async {
                    selectedImage = await _picker.pickImage(source: ImageSource.gallery);
                    setState(() {});
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
                        setState(() {});
                      },
                      child: Text("Change Image"),
                    ),
                  ],
                ),
                TextField(
                  controller: nameController,
                  decoration: InputDecoration(labelText: 'Service'),
                ),
                TextField(
                  controller: priceController,
                  decoration: InputDecoration(labelText: 'Price'),
                  keyboardType: TextInputType.number,
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
                    priceController.text.isNotEmpty) {
                  String uploadImageUrl = await uploadImage(selectedImage!);

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
  }

  Future<void> deleteService(String serviceId) async {
    try {
      await _firestore.collection('services').doc(serviceId).delete();
      fetchServiceDetails();
    } catch (error) {
      print('Error deleting service: $error');
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
      appBar: AppBar(
        title: Text('Service Details'),
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
                    service['image'],
                    height: 50,
                    width: 50,
                    fit: BoxFit.cover,
                  ),
                ),
                DataCell(Text(service['name'])),
                DataCell(Text('\$${service['price'].toStringAsFixed(2)}')),
                DataCell(
                  IconButton(
                    icon: Icon(Icons.delete, color: Colors.red),
                    onPressed: () {
                      deleteService(service['id']);
                    },
                  ),
                ),
              ]);
            }).toList(),
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: addService,
        backgroundColor: Colors.blue,
        child: Icon(Icons.add),
      ),
    );
  }
}
