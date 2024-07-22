import 'package:app/constant/key.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';

class AddNewStall extends StatefulWidget {
  const AddNewStall({Key? key}) : super(key: key);

  @override
  State<AddNewStall> createState() => _AddNewStallState();
}

class _AddNewStallState extends State<AddNewStall> {
  final TextEditingController _stallNumberController = TextEditingController();
  final TextEditingController _stallNameController = TextEditingController();

  @override
  void dispose() {
    _stallNumberController.dispose();
    _stallNameController.dispose();
    super.dispose();
  }

  Future<void> _submitData() async {
    String stallNumber = _stallNumberController.text;
    String stallName = _stallNameController.text;

    if (stallNumber.isEmpty || stallName.isEmpty) {
      Fluttertoast.showToast(msg: 'Please fill out all fields');
      return;
    }

    try {
      // Simulating a DB query
      bool success = await _performDbQuery(stallNumber, stallName);

      if (success) {
        Fluttertoast.showToast(msg: 'Stall added successfully');
      } else {
        Fluttertoast.showToast(msg: 'Failed to add stall');
      }
    } catch (e) {
      Fluttertoast.showToast(msg: 'An error occurred: $e');
    }
  }

  Future<bool> _performDbQuery(String stallNumber, String stallName) async {
    final stallMapDocRef=FirebaseFirestore.instance.collection(stallMap).doc(stallMapId);
    DocumentSnapshot stallMapDocSnapshot = await stallMapDocRef.get();
    Map<String,dynamic> mapData = stallMapDocSnapshot.data() as Map<String,dynamic>;
    Map<String,dynamic> mapValues= mapData[stallMap];
    // List<dynamic> stalls = mapData['stallArray'];
    mapValues[stallNumber]=stallName;
    await stallMapDocRef.update({
      stallMap: mapValues
    });
    return true;

  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Add New Stall'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Add New Stall',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 20),
            TextField(
              controller: _stallNumberController,
              decoration: InputDecoration(
                labelText: 'Stall Number',
                border: OutlineInputBorder(),
              ),
              keyboardType: TextInputType.number,
            ),
            SizedBox(height: 20),
            TextField(
              controller: _stallNameController,
              decoration: InputDecoration(
                labelText: 'Stall Name',
                border: OutlineInputBorder(),
              ),
            ),
            SizedBox(height: 30),
            Center(
              child: ElevatedButton(
                onPressed: _submitData,
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
                  child: Text('Submit'),
                ),
                style: ElevatedButton.styleFrom(
                  textStyle: TextStyle(fontSize: 16),
                  primary: Colors.green, // Use your preferred color
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
