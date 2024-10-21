import 'package:driver_app/authentication/hello.dart';
import 'package:driver_app/mainScreens/navigation.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'package:firebase_storage/firebase_storage.dart';

class ProfileScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: Icon(Icons.arrow_back),
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => Navigation()),
            );
          },
        ),
        title: Text('Edit Profile'),
      ),
      body: ProfileForm(),
    );
  }
}

class ProfileForm extends StatefulWidget {
  @override
  _ProfileFormState createState() => _ProfileFormState();
}

class _ProfileFormState extends State<ProfileForm> {
  final TextEditingController _addressController = TextEditingController();
  final TextEditingController _instagramController = TextEditingController();
  final TextEditingController _serviceController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _businessNameController = TextEditingController();

  bool dataExists = false;
  String? logoUrl; // To store the logo URL
  File? _logoImage; // To store the uploaded logo image
  bool isLoading = false;

  // For email verification
  User? user;
  bool emailVerified = false;

  // Visibility status
  bool websiteVisible = true; // Default value for website visibility

  @override
  void initState() {
    super.initState();
    _loadBusinessInfo();
  }

  void _loadBusinessInfo() async {
    try {
      user = FirebaseAuth.instance.currentUser;

      if (user != null) {
        String uid = user!.uid;

        // Query to find the document by UID in the businesses collection
        QuerySnapshot snapshot = await FirebaseFirestore.instance
            .collection('businesses')
            .where('uid', isEqualTo: uid)
            .get();

        if (snapshot.docs.isNotEmpty) {
          var doc = snapshot.docs.first;

          final data = doc.data() as Map<String, dynamic>;

          _addressController.text = data['address'] ?? 'N/A';
          _instagramController.text = data['instagram'] ?? 'N/A';
          _serviceController.text = data['service'] ?? 'N/A';
          _phoneController.text = data['phone'] ?? 'N/A';
          _businessNameController.text = data['business_name'] ?? 'N/A';
          logoUrl = data['image_url'] ?? null; // Store the logo URL
          websiteVisible = data['status'] ?? true; // Load the visibility status

          // Check email verification status
          emailVerified = user!.emailVerified;

          // Logging fetched data
          print("Fetched data: ${doc.data()}");
          setState(() {
            dataExists = true; // Set dataExists to true if data is loaded
          });
        } else {
          print("No document found for UID: $uid");
        }
      }
    } catch (e) {
      print('Error loading business information: $e');
    }
  }

  Future<void> _pickLogoImage() async {
    final ImagePicker picker = ImagePicker();
    final XFile? image = await picker.pickImage(source: ImageSource.gallery);

    if (image != null) {
      setState(() {
        _logoImage = File(image.path);
      });

      // Show a loading animation
      setState(() {
        isLoading = true;
      });

      try {
        // Upload the file to Firebase Storage
        String uid = FirebaseAuth.instance.currentUser!.uid;
        Reference storageRef = FirebaseStorage.instance
            .ref()
            .child('logos/$uid/logo.png');

        // Upload the file to Firebase Storage
        UploadTask uploadTask = storageRef.putFile(_logoImage!);

        // Wait for the upload to complete
        TaskSnapshot taskSnapshot = await uploadTask;

        // Get the download URL
        String downloadUrl = await taskSnapshot.ref.getDownloadURL();

        setState(() {
          logoUrl = downloadUrl;  // Save the logo URL
          isLoading = false;      // Hide the loading animation
        });

        // You can also save the download URL to Firestore at this point
        _saveLogoUrl(downloadUrl);
      } catch (e) {
        setState(() {
          isLoading = false; // Hide the loading animation in case of error
        });
        print('Error uploading image: $e');
      }
    }
  }

  void _saveLogoUrl(String url) async {
    User? user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      String uid = user.uid;

      QuerySnapshot snapshot = await FirebaseFirestore.instance
          .collection('businesses')
          .where('uid', isEqualTo: uid)
          .get();

      if (snapshot.docs.isNotEmpty) {
        String documentId = snapshot.docs.first.id;

        await FirebaseFirestore.instance.collection('businesses').doc(documentId).set({
          'image_url': url,
        }, SetOptions(merge: true));

        print('Logo URL saved to Firestore');
      }
    }
  }

  // Method to update website visibility status
  void _updateVisibilityStatus(bool value) async {
    setState(() {
      websiteVisible = value;
    });

    User? user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      String uid = user.uid;

      QuerySnapshot snapshot = await FirebaseFirestore.instance
          .collection('businesses')
          .where('uid', isEqualTo: uid)
          .get();

      if (snapshot.docs.isNotEmpty) {
        String documentId = snapshot.docs.first.id;

        await FirebaseFirestore.instance.collection('businesses').doc(documentId).set({
          'status': websiteVisible, // Save visibility status
        }, SetOptions(merge: true));

        print('Visibility status updated to: $websiteVisible');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: ListView(
        children: [
          SizedBox(height: 20),
          // Logo display and upload button moved higher
          _buildLogoSection(),
          SizedBox(height: 20),
          _buildTextField('Business Name', Icons.business, _businessNameController),
          SizedBox(height: 20),
          _buildTextField('Address', Icons.location_on, _addressController),
          SizedBox(height: 20),
          _buildTextField('Instagram', Icons.photo, _instagramController),
          SizedBox(height: 20),
          _buildTextField('Phone', Icons.phone, _phoneController),
          SizedBox(height: 20),
          _buildTextField('Service', Icons.business_center, _serviceController),
          SizedBox(height: 20),

          // Website visibility switch
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Deploy Website'),
              Switch(
                value: websiteVisible,
                onChanged: (value) {
                  _updateVisibilityStatus(value);
                },
              ),
            ],
          ),
          SizedBox(height: 20),


// Row to contain both buttons
          Row(

            children: [
              // Save button
              ElevatedButton(
                onPressed: () {
                  _saveBusinessInfo();
                },
                style: ButtonStyle(
                  side: MaterialStateProperty.all(BorderSide(color: Colors.black)),
                  backgroundColor: MaterialStateProperty.all(Colors.white),
                  elevation: MaterialStateProperty.all(0),
                ),
                child: Text(
                  'Save',
                  style: TextStyle(color: Colors.black),
                ),
              ),
              SizedBox(width: 10),
              // Delete Account button
              ElevatedButton.icon(
                onPressed: () {
                  _confirmDeleteAccount(context);
                },
                icon: Icon(Icons.delete), // Icon for delete button
                label: Text('Delete Account'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.white, // Set the button color to white
                ),
              ),
            ],
          ),


        ],
      ),
    );
  }

  Widget _buildTextField(String label, IconData icon, TextEditingController controller) {
    return TextFormField(
      controller: controller,
      readOnly: dataExists,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon),
      ),
    );
  }

  Widget _buildLogoSection() {
    return Center( // Center the entire logo section
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          SizedBox(height: 10), // Adjust the top spacing as needed
          logoUrl != null || _logoImage != null
              ? Stack(
            alignment: Alignment.center,
            children: [
              ClipOval(
                child: Image.network(
                  logoUrl ?? _logoImage!.path,
                  width: 140,
                  height: 140,
                  fit: BoxFit.cover,
                ),
              ),
              // Icon for picking a new image
              Positioned(
                bottom: 10,
                right: 10,
                child: GestureDetector(
                  onTap: _pickLogoImage,
                  child: Icon(Icons.camera_alt, color: Colors.white),
                ),
              ),
            ],
          )
              : GestureDetector(
            onTap: _pickLogoImage,
            child: CircleAvatar(
              radius: 70,
              backgroundColor: Colors.grey[300],
              child: Icon(Icons.camera_alt, color: Colors.grey[800]),
            ),
          ),
          SizedBox(height: 10), // Adjust the bottom spacing as needed
        ],
      ),
    );
  }

  void _saveBusinessInfo() async {
    try {
      User? user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        String uid = user.uid;

        QuerySnapshot snapshot = await FirebaseFirestore.instance
            .collection('businesses')
            .where('uid', isEqualTo: uid)
            .get();

        if (snapshot.docs.isNotEmpty) {
          String documentId = snapshot.docs.first.id;

          await FirebaseFirestore.instance.collection('businesses').doc(documentId).set({
            'address': _addressController.text,
            'instagram': _instagramController.text,
            'service': _serviceController.text,
            'phone': _phoneController.text,
            'business_name': _businessNameController.text,
            'status': websiteVisible, // Save visibility status
          }, SetOptions(merge: true));

          print('Business information saved');
        }
      }
    } catch (e) {
      print('Error saving business information: $e');
    }
  }

  void _confirmDeleteAccount(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text('Confirm Delete'),
          content: Text('Are you sure you want to delete your account? This action cannot be undone.'),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: Text('Cancel'),
            ),
            TextButton(
              onPressed: () {
                _deleteAccount();
                Navigator.of(context).pop();
              },
              child: Text('Delete'),
            ),
          ],
        );
      },
    );
  }

  void _deleteAccount() async {
    User? user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      String uid = user.uid;

      // Delete user from Firebase Auth
      await user.delete();

      // Delete user's business document from Firestore
      await FirebaseFirestore.instance
          .collection('businesses')
          .where('uid', isEqualTo: uid)
          .get()
          .then((snapshot) {
        for (var doc in snapshot.docs) {
          doc.reference.delete();
        }
      });

      print('Account deleted successfully');
      // Optionally navigate to a different screen after deletion
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => LoginScreen()),
      );
    }
  }
}
