import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';

Future<void> cloneDocument() async {
  final db = FirebaseFirestore.instance;

  try {
    final originalPersonalDocRef= db.collection('users').doc('5ni3VkoLAV9sxCfa9o4z');
    final originalPersonalDocSnapshot= await originalPersonalDocRef.get();
    final originalDocRef = db.collection('forms').doc('v0DKwwLBqCk4hrWV8xbo');
    final originalDocSnapshot = await originalDocRef.get();

    if (originalDocSnapshot.exists) {
      await db.collection('users').doc().set(originalPersonalDocSnapshot.data()!);
      await db.collection('forms').doc().set(originalDocSnapshot.data()!);
      print('Document cloned successfully.');
    } else {
      print('Original document does not exist.');
    }
  } catch (e) {
    print('Error cloning document: $e');
  }
}


class CloneDbData extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Clone Firestore Document'),
      ),
      body: Center(
        child: ElevatedButton(
          onPressed: () async {
            await cloneDocument();
            // Show a Snackbar or dialog here if you want to notify the user
            ScaffoldMessenger.of(context).showSnackBar(SnackBar(
              content: Text("Document cloned successfully"),
            ));
          },
          child: Text('Clone Document'),
        ),
      ),
    );
  }
}
