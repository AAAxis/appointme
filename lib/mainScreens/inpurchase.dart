import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:intl/intl.dart'; // Import for date formatting

class SubscriptionScreen extends StatefulWidget {
  @override
  _SubscriptionScreenState createState() => _SubscriptionScreenState();
}

class _SubscriptionScreenState extends State<SubscriptionScreen> {
  String? _selectedProductId;
  String? _selectedPlanUrl;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  String? _status;
  DateTime? _expirationDate;

  Future<List<Map<String, dynamic>>> _fetchSubscriptionPlans() async {
    QuerySnapshot querySnapshot = await _firestore.collection('subscriptions').get();

    // Map the documents to a list of maps
    return querySnapshot.docs.map((doc) {
      return {
        "id": doc.id, // Use Firestore document ID
        "price": doc['price'],
        "description": doc['description'],
        "days": doc['days'],
        "title": doc['title'],
        "url": doc['url'], // Fetch the URL from the document
      };
    }).toList();
  }

  void _fetchBusinessDetails(String uid) async {
    try {
      // Query the businesses collection where uid matches the authenticated user's UID
      QuerySnapshot snapshot = await _firestore
          .collection('businesses')
          .where('uid', isEqualTo: uid)
          .get();

      if (snapshot.docs.isNotEmpty) {
        // Assuming you want the first matching document
        final data = snapshot.docs.first.data() as Map<String, dynamic>?;

        if (data != null) {
          setState(() {
            // Access the 'status' and 'sub_expiration' fields
            _status = data['status'] as String?;
            _expirationDate = (data['sub_expiration'] as Timestamp?)?.toDate();
            _selectedProductId = _status; // Preselect based on user's status
          });
        }
      } else {
        _showSnackBar("No business found for this user.");
      }
    } catch (e) {
      _showSnackBar("Failed to fetch business details: $e");
    }
  }

  void _showSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
  }

  void _launchURL(String url) async {
    if (await canLaunch(url)) {
      await launch(url);
    } else {
      _showSnackBar("Could not launch $url");
    }
  }

  @override
  void initState() {
    super.initState();
    final user = _auth.currentUser;
    if (user != null) {
      _fetchBusinessDetails(user.uid); // Fetch business details for the authenticated user
    } else {
      _showSnackBar("No authenticated user found.");
    }
  }
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Subscription Plans")),
      body: FutureBuilder<List<Map<String, dynamic>>>(
        future: _fetchSubscriptionPlans(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return Center(child: Text("Error: ${snapshot.error}"));
          } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return Center(child: Text("No subscription plans available."));
          }

          final subscriptionPlans = snapshot.data!;

          return ListView(
            padding: const EdgeInsets.all(16.0), // Add padding to the entire ListView
            children: [
              // Display subscription plans
              ...subscriptionPlans.map((plan) {
                return RadioListTile<String>(
                  title: Text(plan['title']),
                  subtitle: Text(plan['description']),
                  value: plan['id'], // Unique value for each plan
                  groupValue: _selectedProductId, // Current selection state
                  onChanged: (value) {
                    setState(() {
                      _selectedProductId = value; // Update the selected product ID
                      _selectedPlanUrl = plan['url']; // Get the URL associated with the selected plan
                    });
                  },
                  secondary: Text("\$${plan['price']}"), // Show price
                );
              }).toList(),

              // Display the expiration date if it is available
              if (_expirationDate != null)
                Padding(
                  padding: const EdgeInsets.only(top: 16.0), // Add some space above the text
                  child: Text(
                    "Expiration Date: ${DateFormat('yyyy-MM-dd').format(_expirationDate!)}",
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                ),
            ],
          );
        },
      ),
      floatingActionButton: Container(
        margin: const EdgeInsets.all(16.0),
        child: ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.black, // Black background color
            padding: EdgeInsets.symmetric(horizontal: 24.0, vertical: 12.0), // Button padding
          ),
          onPressed: (_selectedProductId == 'kKe8EGkty2uA0Dk2ROD5') || _selectedPlanUrl == null
              ? null // Disable the button if the selected ID matches or URL is null
              : () {
            // Launch the URL from the selected subscription plan
            _launchURL(_selectedPlanUrl!); // Open the URL
          },
          child: Text(
            "Submit", // Button text
            style: TextStyle(
              color: Colors.white, // Set text color to white
            ),
          ),
        ),
      ),
    );
  }

}
