import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/gestures.dart'; // Import for TapGestureRecognizer
import 'package:driver_app/mainScreens/navigation.dart';
import 'package:url_launcher/url_launcher.dart'; // Import for URL launcher
final FirebaseAuth _auth = FirebaseAuth.instance;

class EmailLoginScreen extends StatefulWidget {
  const EmailLoginScreen({Key? key}) : super(key: key);

  @override
  _EmailLoginScreenState createState() => _EmailLoginScreenState();
}

void _launchURL() async {
  const url = 'https://appointmaster.vercel.app'; // Replace with your desired URL
    await launch(url);

}


class _EmailLoginScreenState extends State<EmailLoginScreen> {
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  String errorMessage = '';

  Future<void> signInWithEmail() async {
    final email = emailController.text.trim();
    final password = passwordController.text.trim();

    if (email.isEmpty || password.isEmpty) {
      setState(() {
        errorMessage = "Please enter both email and password.";
      });
      return;
    }

    try {
      final signInMethods = await _auth.fetchSignInMethodsForEmail(email);

      if (signInMethods.contains('google.com')) {
        // Handle Google account linking logic
      }

      UserCredential userCredential = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      if (userCredential.user != null) {
        if (userCredential.user!.emailVerified) {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => Navigation()),
          );
        } else {
          setState(() {
            errorMessage = "Please verify your email address.";
          });
        }
      }
    } catch (e) {
      setState(() {
        errorMessage = e.toString();
      });
    }
  }

  // Launch the registration URL
  void _launchRegistrationUrl() async {
    const url = 'https://appointmaster.vercel.app/register/'; // Replace with your registration URL
    await launch(url);
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[200], // Background color
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                "Welcome Back!",
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Colors.black,
                ),
              ),
              SizedBox(height: 20),
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
              SizedBox(height: 20),
              Center(
                child: Row(
                  mainAxisSize: MainAxisSize.min, // Makes the row take the minimum width it needs
                  children: [
                    ElevatedButton(
                      onPressed: signInWithEmail,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blue, // Background color
                        padding: EdgeInsets.symmetric(horizontal: 32, vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(30),
                        ),
                      ),
                      child: Text(
                        "Sign In",
                        style: TextStyle(color: Colors.white), // Text color set to white
                      ),
                    ),

                    SizedBox(width: 20), // Space between the two buttons
                    OutlinedButton(
                      onPressed: _launchURL,
                      style: OutlinedButton.styleFrom(
                        padding: EdgeInsets.symmetric(horizontal: 32, vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(30),
                        ),
                        side: BorderSide(color: Colors.green, width: 2), // Outline color and width
                      ),
                      child: Text(
                        "Skip",
                        style: TextStyle(color: Colors.green), // Text color to match the outline
                      ),
                    ),
                  ],
                ),
              ),

              SizedBox(height: 20),
              if (errorMessage.isNotEmpty)
                Text(
                  errorMessage,
                  style: TextStyle(color: Colors.red),
                ),
              SizedBox(height: 20),
              RichText(
                text: TextSpan(
                  style: TextStyle(
                    color: Colors.black, // Default text color
                  ),
                  children: <TextSpan>[
                    TextSpan(text: "Don't have an account? "),
                    TextSpan(
                      text: "Register here.",
                      style: TextStyle(
                        color: Colors.blue, // Change "Register here" text color to blue
                        decoration: TextDecoration.underline,
                      ),
                      recognizer: TapGestureRecognizer()
                        ..onTap = () {
                          _launchRegistrationUrl(); // Link to registration
                        },
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
