import 'package:driver_app/mainScreens/navigation.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class EditBankScreen extends StatelessWidget {
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
        title: Text('Edit Bank Info'),
      ),
      body: BankInfoForm(),
    );
  }
}

class BankInfoForm extends StatefulWidget {
  @override
  _BankInfoFormState createState() => _BankInfoFormState();
}

class _BankInfoFormState extends State<BankInfoForm> {
  final TextEditingController _bankNameController = TextEditingController();
  final TextEditingController _transitNumberController = TextEditingController();
  final TextEditingController _branchController = TextEditingController();

  bool dataExists = false;

  @override
  void initState() {
    super.initState();
    _loadBankInfo();
  }

  void _loadBankInfo() async {
    try {
      User? user = FirebaseAuth.instance.currentUser;

      if (user != null) {
        String uid = user.uid; // Get UID from the authenticated user
        DocumentSnapshot snapshot = await FirebaseFirestore.instance
            .collection('bank')
            .doc(uid)
            .get();

        if (snapshot.exists) {
          setState(() {
            dataExists = true;
            _bankNameController.text = snapshot['bankName'];
            _transitNumberController.text = snapshot['transitNumber'];
            _branchController.text = snapshot['branch'];
          });
        }
      }
    } catch (e) {
      print('Error loading bank information: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          TextFormField(
            controller: _bankNameController,
            readOnly: dataExists,
            decoration: InputDecoration(
              labelText: 'Bank Name',
              prefixIcon: Icon(Icons.account_balance),
            ),
          ),
          SizedBox(height: 20),
          TextFormField(
            controller: _transitNumberController,
            keyboardType: TextInputType.number,
            readOnly: dataExists,
            decoration: InputDecoration(
              labelText: 'Transit Number',
              prefixIcon: Icon(Icons.format_list_numbered),
            ),
          ),
          SizedBox(height: 20),
          TextFormField(
            controller: _branchController,
            readOnly: dataExists,
            decoration: InputDecoration(
              labelText: 'Branch',
              prefixIcon: Icon(Icons.location_on),
            ),
          ),
          SizedBox(height: 20),
          ElevatedButton(
            onPressed: () {
              if (dataExists) {
                _deleteBankInfo();
              } else {
                _saveBankInfo();
              }
            },
            style: ButtonStyle(
              side: MaterialStateProperty.all(BorderSide(color: Colors.black)),
              backgroundColor: MaterialStateProperty.all(Colors.white),
              elevation: MaterialStateProperty.all(0),
            ),
            child: Text(dataExists ? 'Delete' : 'Save', style: TextStyle(color: Colors.black)),
          ),
        ],
      ),
    );
  }

  void _saveBankInfo() async {
    try {
      User? user = FirebaseAuth.instance.currentUser;

      if (user == null) {
        print('User not authenticated.');
        return;
      }

      String uid = user.uid;
      String bankName = _bankNameController.text;
      String transitNumber = _transitNumberController.text;
      String branch = _branchController.text;

      await FirebaseFirestore.instance
          .collection('bank')
          .doc(uid)
          .set({
        'bankName': bankName,
        'transitNumber': transitNumber,
        'branch': branch,
      });

      print('Bank information saved to Firestore');

      setState(() {
        dataExists = true;
      });
    } catch (e) {
      print('Error saving bank information: $e');
    }
  }

  void _deleteBankInfo() async {
    try {
      User? user = FirebaseAuth.instance.currentUser;

      if (user != null) {
        String uid = user.uid;
        await FirebaseFirestore.instance
            .collection('bank')
            .doc(uid)
            .delete();

        print('Bank information deleted from Firestore');

        setState(() {
          _bankNameController.clear();
          _transitNumberController.clear();
          _branchController.clear();
          dataExists = false;
        });
      }
    } catch (e) {
      print('Error deleting bank information: $e');
    }
  }
}
