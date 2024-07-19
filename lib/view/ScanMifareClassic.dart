import 'package:app/constant/key.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter/foundation.dart';
import 'dart:async';
import 'dart:io' show Platform;
import 'package:intl/intl.dart';

import 'package:flutter_nfc_kit/flutter_nfc_kit.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:ndef/ndef.dart' as ndef;
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

class ScanMifareClassic extends StatefulWidget {
  @override
  _ScanMifareClassicState createState() => _ScanMifareClassicState();
}

class _ScanMifareClassicState extends State<ScanMifareClassic> with SingleTickerProviderStateMixin {
  bool _isScanning = false;
  NFCAvailability _availability = NFCAvailability.not_supported;
  NFCTag? _tag;
  String? _result;

  @override
  void initState() {
    super.initState();
    initPlatformState();
  }

  Future<void> initPlatformState() async {
    try {
      _availability = await FlutterNfcKit.nfcAvailability;
    } on PlatformException {
      _availability = NFCAvailability.not_supported;
    }

    if (!mounted) return;
  }

  void _startScanning() async {
    setState(() {
      _isScanning = true;
    });

    try {
      NFCTag tag = await FlutterNfcKit.poll();
      setState(() {
        _tag = tag;
      });

      await FlutterNfcKit.setIosAlertMessage("Working on it...");

      if (tag.standard == "ISO 14443-4 (Type B)") {
        String result1 = await FlutterNfcKit.transceive("00B0950000");
        String result2 = await FlutterNfcKit.transceive("00A4040009A00000000386980701");
        setState(() {
          _result = '1: $result1\n2: $result2\n';
        });
      } else if (tag.type == NFCTagType.iso18092) {
        String result1 = await FlutterNfcKit.transceive("060080080100");
        setState(() {
          _result = '1: $result1\n';
        });
      } else if (tag.type == NFCTagType.mifare_ultralight ||
          tag.type == NFCTagType.mifare_classic ||
          tag.type == NFCTagType.iso15693) {
        var ndefRecords = await FlutterNfcKit.readNDEFRecords();
        var ndefString = '';
        for (int i = 0; i < ndefRecords.length; i++) {
          ndefString += '${i + 1}: ${ndefRecords[i]}\n';
        }
        setState(() {
          _result = ndefString;
        });
      } else if (tag.type == NFCTagType.webusb) {
        var r = await FlutterNfcKit.transceive("00A4040006D27600012401");
        print(r);
      }
    } catch (e) {
      setState(() {
        _result = 'error: $e';
      });
    }

    setState(() {
      _isScanning = false;
    });

    // Navigate to the next page or show scan result
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Scan complete!')),
    );
  }

  Widget buildUserDetails(Map<String, dynamic> userData) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          "User Details",
          style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
        ),
        SizedBox(height: 10),
        Text("Name: ${userData['candidate_name']}"),
        Text("Father's Name: ${userData['father_name']}"),
        Text("Mother's Name: ${userData['mother_name']}"),
        Text("DOB: ${userData['dob']}"),
      ],
    );
  }



Widget buildEventDetails(List<dynamic> events) {
  final DateFormat formatter = DateFormat('yyyy-MM-dd HH:mm:ss');

  return SingleChildScrollView(
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          "Event Details",
          style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
        ),
        SizedBox(height: 10),
        ...events.map((event) => Card(
              margin: EdgeInsets.symmetric(vertical: 10),
              child: ListTile(
                leading: Icon(Icons.event),
                title: Text("Event: ${event['eventId']}"),
                subtitle: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text("In Time: ${event['inTime'] != null && event['inTime'] is Timestamp ? formatter.format((event['inTime'] as Timestamp).toDate()) : 'N/A'}"),
                    Text("Out Time: ${event['outTime'] != null && event['outTime'] is Timestamp ? formatter.format((event['outTime'] as Timestamp).toDate()) : 'N/A'}"),
                    Text("Total Time Spent: ${formatDuration(event['totalTimeSpent'])}"),
                  ],
                ),
              ),
            ))
      ],
    ),
  );
}

String formatDuration(int seconds) {
  final Duration duration = Duration(seconds: seconds);
  String twoDigits(int n) => n.toString().padLeft(2, '0');
  final String twoDigitMinutes = twoDigits(duration.inMinutes.remainder(60));
  final String twoDigitSeconds = twoDigits(duration.inSeconds.remainder(60));
  return "${twoDigits(duration.inHours)}:$twoDigitMinutes:$twoDigitSeconds";
}


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(FontAwesomeIcons.idCard, color: Colors.white),
            SizedBox(width: 10),
            Text('Scan Card', style: Theme.of(context).textTheme.headline6),
          ],
        ),
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: SingleChildScrollView(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  height: 200,
                  width: 200,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(20),
                    image: DecorationImage(
                      image: AssetImage('assets/innerScan.gif'), // Replace with your asset path
                      fit: BoxFit.cover,
                    ),
                  ),
                ),
                SizedBox(height: 40),
                Text(
                  'Hold your card near the device to scan',
                  style: Theme.of(context).textTheme.headline6!.copyWith(color: Colors.black),
                  textAlign: TextAlign.center,
                ),
                SizedBox(height: 40),
                _isScanning
                    ? CircularProgressIndicator()
                    : ElevatedButton.icon(
                        onPressed: _startScanning,
                        icon: Icon(FontAwesomeIcons.play, color: Colors.white),
                        label: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 10.0),
                          child: Text('Start Scanning', style: Theme.of(context).textTheme.button),
                        ),
                        style: ElevatedButton.styleFrom(
                          textStyle: TextStyle(fontSize: 20),
                          minimumSize: Size(250, 60), // Enlarging the button
                        ),
                      ),
                SizedBox(height: 20),
                _tag != null
                    ? Column(
                        children: [
                          Text('ID: ${_tag!.id}'),
                          SizedBox(height: 10),
                          FutureBuilder<DocumentSnapshot>(
                            future: FirebaseFirestore.instance.collection(registeredTag).doc(registeredTagDoc).get(),
                            builder: (context, snapshot) {
                              if (snapshot.connectionState == ConnectionState.waiting) {
                                return CircularProgressIndicator();
                              } else if (snapshot.hasError) {
                                return Text("Error: ${snapshot.error}");
                              } else if (!snapshot.hasData || !snapshot.data!.exists) {
                                return Text("Unregistered Tag");
                              } else {
                                Map<String, dynamic> data = snapshot.data!.data() as Map<String, dynamic>;
          
                                if (data.containsKey('User') && data['User'] is Map) {
                                  Map<String, dynamic> userMap = data['User'];
                                  String specificId = _tag!.id;
          
                                  if (userMap.containsKey(specificId)) {
                                    return FutureBuilder<DocumentSnapshot>(
                                      future: FirebaseFirestore.instance.collection(users).doc(userMap[specificId].toString()).get(),
                                      builder: (context, userSnapshot) {
                                        if (userSnapshot.connectionState == ConnectionState.waiting) {
                                          return CircularProgressIndicator();
                                        } else if (userSnapshot.hasError) {
                                          return Text("Error: ${userSnapshot.error}");
                                        } else if (!userSnapshot.hasData || !userSnapshot.data!.exists) {
                                          return Text("User does not exist");
                                        } else {
                                          Map<String, dynamic> userData = userSnapshot.data!.data() as Map<String, dynamic>;
                                          return Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              buildUserDetails(userData),
                                              if (userData.containsKey('events') && userData['events'] is List)
                                                buildEventDetails(userData['events']),
                                            ],
                                          );
                                        }
                                      },
                                    );
                                  } else {
                                    return Text("User does not exist");
                                  }
                                } else {
                                  return Text("Unregistered Tag");
                                }
                              }
                            },
                          ),
                        ],
                      )
                    : Container(),
                SizedBox(height: 20),
                ElevatedButton(
                  onPressed: () {
                    Navigator.pop(context);
                  },
                  child: Text('Back'),
                ),
                SizedBox(height: 20),
                ElevatedButton(
                  onPressed: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Functionality yet to build'),
                      ),
                    );
                  },
                  child: Text('View Result'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

void main() {
  runApp(MaterialApp(
    home: ScanMifareClassic(),
  ));
}
