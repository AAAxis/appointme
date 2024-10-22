import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:driver_app/mainScreens/navigation.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

final FirebaseAuth _auth = FirebaseAuth.instance;
final FirebaseFirestore _firestore = FirebaseFirestore.instance;

class RegistrationScreen extends StatefulWidget {
  const RegistrationScreen({Key? key}) : super(key: key);

  @override
  _RegistrationScreenState createState() => _RegistrationScreenState();
}

class _RegistrationScreenState extends State<RegistrationScreen> {
  final TextEditingController nameController = TextEditingController();
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();

  String errorMessage = '';
  String? selectedBusinessType; // To hold the selected business type
  final List<String> businessTypes = [
    'Barber Shop',
    'Nail Salon',
    'Gym',
    'Boxing',
    'Massage'
  ];

  @override
  void initState() {
    super.initState();
    // Set the default selected business type to "Barber Shop"
    selectedBusinessType = businessTypes[0]; // or "Barber Shop"
  }

  Future<void> registerWithEmail() async {
    final name = nameController.text.trim();
    final email = emailController.text.trim();
    final password = passwordController.text.trim();

    if (name.isEmpty || email.isEmpty || password.isEmpty || selectedBusinessType == null) {
      setState(() {
        errorMessage = "Please fill in all fields.";
      });
      return;
    }

    try {
      // Create the user account with Firebase Authentication
      UserCredential userCredential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      if (userCredential.user != null) {
        final String uid = userCredential.user!.uid;

        // Update the display name
        await userCredential.user!.updateDisplayName(name);

        // Calculate the trialEndDate as 14 days from now
        DateTime trialEndDate = DateTime.now().add(Duration(days: 14));

        // Create the business document in Firestore
        await _firestore.collection('businesses').add({
          'address': 'N/A',
          'background': 'https://polskoydm.pythonanywhere.com/static/background.png',
          'business_name': name,
          'email': email,
          'image_url': 'https://polskoydm.pythonanywhere.com/static/index.png',
          'phone': 'N/A',
          'service': selectedBusinessType,
          'uid': uid,
          'status': 'kKe8EGkty2uA0Dk2ROD5',
          'created': FieldValue.serverTimestamp(),
          'sub_expiration': Timestamp.fromDate(trialEndDate),
        });

        // Add default services to Firestore
        List<Map<String, dynamic>> services = [
          {
            'name': 'Women Cut',
            'price': 120,
            'image_url': 'https://polskoydm.pythonanywhere.com/static/womencut.jpeg'
          },
          {
            'name': 'Classic Cut',
            'price': 70,
            'image_url': 'https://polskoydm.pythonanywhere.com/static/mencut.jpeg'
          },
          {
            'name': 'Coloring',
            'price': 130,
            'image_url': 'https://polskoydm.pythonanywhere.com/static/coloring.jpeg'
          },
          {
            'name': 'Beard Trim',
            'price': 80,
            'image_url': 'https://polskoydm.pythonanywhere.com/static/beardtrim.jpeg'
          },
        ];

        for (var service in services) {
          await _firestore.collection('services').add({
            'name': service['name'],
            'price': service['price'],
            'image': service['image_url'],
            'userId': uid,
          });
        }

        // Define default working hours (8 AM to 8 PM)
        Map<String, Map<String, dynamic>> defaultWorkingHours = {
          'monday': {'from': '08:00', 'to': '20:00', 'working': true},
          'tuesday': {'from': '08:00', 'to': '20:00', 'working': true},
          'wednesday': {'from': '08:00', 'to': '20:00', 'working': true},
          'thursday': {'from': '08:00', 'to': '20:00', 'working': true},
          'friday': {'from': '08:00', 'to': '20:00', 'working': true},
          'saturday': {'from': '08:00', 'to': '20:00', 'working': true},
          'sunday': {'from': '08:00', 'to': '20:00', 'working': true},
        };

        // Store default working hours in Firestore
        await _firestore.collection('working_hours').doc(uid).set({
          'workingHours': defaultWorkingHours,
        });

        // Navigate to the main app or another screen after registration
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => Navigation()),
        );
      }
    } catch (e) {
      setState(() {
        errorMessage = e.toString();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[200],
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                "Create Account",
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Colors.black,
                ),
              ),
              SizedBox(height: 20),
              TextField(
                controller: nameController,
                decoration: InputDecoration(
                  labelText: "Name",
                  prefixIcon: Icon(Icons.person),
                  border: OutlineInputBorder(),
                  filled: true,
                  fillColor: Colors.white,
                ),
              ),
              SizedBox(height: 16),
              TextField(
                controller: emailController,
                decoration: InputDecoration(
                  labelText: "Email",
                  prefixIcon: Icon(Icons.email),
                  border: OutlineInputBorder(),
                  filled: true,
                  fillColor: Colors.white,
                ),
              ),
              SizedBox(height: 16),
              TextField(
                controller: passwordController,
                decoration: InputDecoration(
                  labelText: "Password",
                  prefixIcon: Icon(Icons.lock),
                  border: OutlineInputBorder(),
                  filled: true,
                  fillColor: Colors.white,
                ),
                obscureText: true,
              ),
              SizedBox(height: 16),
              // Dropdown for selecting business type
              DropdownButtonFormField<String>(
                value: selectedBusinessType,
                decoration: InputDecoration(
                  labelText: 'Business Type',
                  border: OutlineInputBorder(),
                  filled: true,
                  fillColor: Colors.white,
                ),
                onChanged: (String? newValue) {
                  setState(() {
                    selectedBusinessType = newValue;
                  });
                },
                items: businessTypes.map<DropdownMenuItem<String>>((String type) {
                  return DropdownMenuItem<String>(
                    value: type,
                    child: Text(type),
                  );
                }).toList(),
              ),
              SizedBox(height: 20),
              ElevatedButton(
                onPressed: registerWithEmail,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue,
                  padding: EdgeInsets.symmetric(horizontal: 32, vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(30),
                  ),
                ),
                child: Text(
                  "Register",
                  style: TextStyle(color: Colors.white),
                ),
              ),
              SizedBox(height: 20),
              if (errorMessage.isNotEmpty)
                Text(
                  errorMessage,
                  style: TextStyle(color: Colors.red),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
