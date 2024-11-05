import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import 'business_page.dart';

class OrderUpdatePage extends StatefulWidget {


  const OrderUpdatePage({
    Key? key,
  }) : super(key: key);

  @override
  _OrderUpdatePageState createState() => _OrderUpdatePageState();
}

class _OrderUpdatePageState extends State<OrderUpdatePage> {
  final TextEditingController phoneController = TextEditingController();

  Future<void> updateOrdersPhoneAndStatus() async {
    try {
      // Get the current user's ID from Firebase Auth
      User? user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        print("No user is currently signed in.");
        return;
      }
      String userId = user.uid;

      // Fetch all orders with the matching userId
      QuerySnapshot querySnapshot = await FirebaseFirestore.instance
          .collection('orders')
          .where('store', isEqualTo: userId)
          .get();

      // Loop through each document and update it
      for (var doc in querySnapshot.docs) {
        await doc.reference.update({
          'phone': phoneController.text,
          'status': 'confirmed',
        });
      }

      // Show success SnackBar
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Phone and status updated successfully!')),
      );

      // Navigate to a success page or previous screen
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => BarbershopPage()), // Replace with your success page
      );
      print("Phone and status updated successfully for all matching orders.");
    } catch (e) {
      print("Error updating orders: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error updating orders')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Confirm Appointment'),
      ),
      body: SingleChildScrollView(
        child: Container(


          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Image at the top
                Container(
                  margin: EdgeInsets.symmetric(vertical: 20),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(10),
                    child: Image.asset(
                      'images/phone.png', // Replace with your local image path
                      height: 150,
                      fit: BoxFit.cover,
                    ),
                  ),
                ),

                SizedBox(height: 20),
                // Phone number input field with icon
                TextField(
                  controller: phoneController,
                  decoration: InputDecoration(
                    labelText: 'Enter your phone number',
                    labelStyle: TextStyle(color: Colors.black),
                    prefixIcon: Icon(Icons.phone, color: Colors.black),
                    filled: true,

                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide.none,
                    ),
                  ),
                  keyboardType: TextInputType.phone,
                  style: TextStyle(color: Colors.black),
                ),
                SizedBox(height: 20),
                SizedBox(
                  width: double.infinity, // Makes the button full width
                  child: ElevatedButton(
                    onPressed: () {
                      // Call update function
                      if (phoneController.text.isNotEmpty) {
                        updateOrdersPhoneAndStatus();
                      } else {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('Please enter a phone number')),
                        );
                      }
                    },
                    child: Text(
                      'Confirm',
                      style: TextStyle(color: Colors.white), // White text color
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue, // Background color
                      padding: EdgeInsets.symmetric(vertical: 15), // Vertical padding
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.zero, // Square corners
                      ),
                    ),
                  ),
                ),

              ],
            ),
          ),
        ),
      ),
    );
  }
}

// Success page after update
