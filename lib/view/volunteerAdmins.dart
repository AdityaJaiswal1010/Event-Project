import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter/foundation.dart';
import 'dart:async';
import 'dart:io' show Platform;

import 'package:flutter_nfc_kit/flutter_nfc_kit.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:ndef/ndef.dart' as ndef;
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:flutter_typeahead/flutter_typeahead.dart';

import '../constant/key.dart'; // Ensure this file has the required constants

class VolunteerAdmins extends StatefulWidget {
  @override
  _VolunteerAdminsState createState() => _VolunteerAdminsState();
}

class _VolunteerAdminsState extends State<VolunteerAdmins> with SingleTickerProviderStateMixin {
  bool _isScanning = false;
  NFCAvailability _availability = NFCAvailability.not_supported;
  NFCTag? _tag;
  String? _result;
  String? _selectedEvent;
  String _selectedTimeType = 'In-Time'; // Default to In-Time
  
  late List<String> _events = [];
  final List<String> _timeTypes = ['In-Time', 'Out-Time'];
  final TextEditingController _typeAheadController = TextEditingController();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  @override
  void initState() {
    super.initState();
    initPlatformState();
  _fetchStallMap();
  }

  Future<void> _fetchStallMap() async {
    try {
      DocumentSnapshot<Map<String, dynamic>> documentSnapshot = await _firestore.collection('stallMap').doc('HdFbY9S1XyLHqKGuOLAE').get();
      Map<String, dynamic>? stallMap = documentSnapshot.data()?['stallMap'];

      if (stallMap != null) {
        setState(() {
          _events = stallMap.values.map((value) => value.toString()).toList();
        });
        Fluttertoast.showToast(msg: 'Stall map fetched successfully');
      } else {
        Fluttertoast.showToast(msg: 'Stall map is empty');
      }
    } catch (e) {
      Fluttertoast.showToast(msg: 'Failed to fetch stall map: $e');
    }
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

      // Store data in Firestore
      if (_selectedEvent != null) {
        await onScanCardButtonPressed(_tag!.id, _selectedEvent!, _selectedTimeType == 'In-Time');
        // Show success popup
        showDialog(
          context: context,
          builder: (BuildContext context) {
            return AlertDialog(
              title: Text("Success"),
              content: Text("Data added successfully!"),
              actions: [
                TextButton(
                  child: Text("OK"),
                  onPressed: () {
                    Navigator.of(context).pop();
                  },
                ),
              ],
            );
          },
        );
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(FontAwesomeIcons.idCard, color: Colors.white),
            SizedBox(width: 10),
            Text('Scan Card', style: Theme.of(context).textTheme.headline1,),
          ],
        ),
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              TypeAheadFormField(
                textFieldConfiguration: TextFieldConfiguration(
                  controller: _typeAheadController,
                  decoration: InputDecoration(
                    labelText: 'Select Event',
                  ),
                ),
                suggestionsCallback: (pattern) {
                  return _events.where((event) => event.toLowerCase().contains(pattern.toLowerCase()));
                },
                itemBuilder: (context, suggestion) {
                  return ListTile(
                    title: Text(suggestion.toString()),
                  );
                },
                onSuggestionSelected: (suggestion) {
                  _typeAheadController.text = suggestion.toString();
                  setState(() {
                    _selectedEvent = suggestion.toString();
                  });
                },
              ),
              SizedBox(height: 20),
              DropdownButton<String>(
                value: _selectedTimeType,
                onChanged: (String? newValue) {
                  setState(() {
                    _selectedTimeType = newValue!;
                  });
                },
                items: _timeTypes.map<DropdownMenuItem<String>>((String value) {
                  return DropdownMenuItem<String>(
                    value: value,
                    child: Text(value),
                  );
                }).toList(),
              ),
              SizedBox(height: 40),
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
                style: Theme.of(context).textTheme.headline1!.copyWith(color: Colors.black),
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

                              // Ensure _tag is not null before accessing _tag!.id
                              if (data.containsKey('User') && data['User'] is Map) {
                                Map<String, dynamic> userMap = data['User'];
                                String specificId = _tag!.id; // the actual ID you want to check

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
                                        return Column(children: [
                                          Text("ID exists:"),
                                          Text("${userData['candidate_name']}"),
                                          Text(userData['father_name']),
                                          Text(userData['mother_name']),
                                          Text(userData['dob']),
                                          ElevatedButton(onPressed: () {
                                            onScanCardButtonPressed(userMap[specificId].toString(), _selectedEvent!, _selectedTimeType == 'In-Time');
                                          }, child: Text("Add")),
                                        ]);
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
    );
  }
Future<void> onScanCardButtonPressed(String userId, String eventId, bool isInTime) async {
  final userDocRef = FirebaseFirestore.instance.collection('users').doc(userId);

  // Get the user document
  DocumentSnapshot userDocSnapshot = await userDocRef.get();
  Map<String, dynamic> userData = userDocSnapshot.data() as Map<String, dynamic>;

  List<dynamic> events = userData['events'] ?? [];

  bool eventExists = false;

  // Iterate through the events to find if the event already exists
  for (var i = 0; i < events.length; i++) {
    var event = events[i];
    if (event['eventId'] == eventId) {
      eventExists = true;
      if (isInTime) {
        Timestamp currentTime = Timestamp.now();
        event['inTime'] = currentTime;
        event['outTime'] = null; // Clear outTime when a new inTime is recorded
        event['totalTimeSpent'] = 0;
        print('In-Time set: ${event['inTime']}');
      } else if (event['inTime'] != null && event['outTime'] == null) {
        event['outTime'] = Timestamp.now();
        // Calculate the total time spent
        var inTime = (event['inTime'] as Timestamp).toDate();
        var outTime = (event['outTime'] as Timestamp).toDate();
        event['totalTimeSpent'] = outTime.difference(inTime).inSeconds;
        print('Out-Time set: ${event['outTime']}');
        print('Total Time Spent: ${event['totalTimeSpent']} seconds');
      } else {
        throw Exception('In time must be recorded before out time.');
      }
      events[i] = event; // Ensure the updated event is put back in the list
      break;
    }
  }

  // If the event doesn't exist and isInTime is true, add it
  if (!eventExists && isInTime) {
    Timestamp currentTime = Timestamp.now();
    events.add({
      'eventId': eventId,
      'inTime': currentTime,
      'outTime': null,
      'totalTimeSpent': 0,
    });
    print('New In-Time event added: ${events.last['inTime']}');
  } else if (!eventExists && !isInTime) {
    // If event doesn't exist and isInTime is false, do not allow out time
    throw Exception('In time must be recorded before out time.');
  }

  // Update the user document with the updated events array
  await userDocRef.update({'events': events});
  print('User document updated with events: $events');
}


  void main() {
    runApp(MaterialApp(
      home: VolunteerAdmins(),
    ));
  }
}
