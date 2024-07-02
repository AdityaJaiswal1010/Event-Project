// import 'package:flutter/foundation.dart';
// import 'package:flutter/material.dart';
// import 'dart:async';
// import 'dart:io' show Platform;

// import 'package:flutter/services.dart';
// import 'package:flutter_nfc_kit/flutter_nfc_kit.dart';
// import 'package:cloud_firestore/cloud_firestore.dart';
// import 'package:ndef/ndef.dart' as ndef;

// class ScanMifareClassic extends StatefulWidget {
//   const ScanMifareClassic({Key? key}) : super(key: key);

//   @override
//   State<ScanMifareClassic> createState() => _ScanMifareClassicState();
// }

// class _ScanMifareClassicState extends State<ScanMifareClassic> with SingleTickerProviderStateMixin {
//   String _platformVersion = '';
//   String firebaseInstanceId = '';
//   TextEditingController regnoController = TextEditingController();
//   NFCAvailability _availability = NFCAvailability.not_supported;
//   NFCTag? _tag;
//   String? _result, _writeResult, mainData;
//   late TabController _tabController;
//   List<ndef.NDEFRecord>? _records;
//   String tagId='';

//   @override
//   void dispose() {
//     _tabController.dispose();
//     super.dispose();
//   }

//   @override
//   void initState() {
//     super.initState();
//     _platformVersion = !kIsWeb
//         ? '${Platform.operatingSystem} ${Platform.operatingSystemVersion}'
//         : 'Web';
//     initPlatformState();
//     _tabController = TabController(length: 2, vsync: this);
//     _records = [];
//   }

//   Future<void> initPlatformState() async {
//     try {
//       _availability = await FlutterNfcKit.nfcAvailability;
//     } on PlatformException {
//       _availability = NFCAvailability.not_supported;
//     }

//     if (!mounted) return;

//     setState(() {
//       // Update state with platform availability
//     });
//   }

//   Future<void> _scanNFC() async {
//     try {
//       NFCTag tag = await FlutterNfcKit.poll();
//       setState(() {
//         _tag = tag;
//       });

//       await FlutterNfcKit.setIosAlertMessage("Working on it...");

//       if (tag.standard == "ISO 14443-4 (Type B)") {
//         String result1 = await FlutterNfcKit.transceive("00B0950000");
//         String result2 = await FlutterNfcKit.transceive("00A4040009A00000000386980701");
//         setState(() {
//           _result = '1: $result1\n2: $result2\n';
//         });
//       } else if (tag.type == NFCTagType.iso18092) {
//         String result1 = await FlutterNfcKit.transceive("060080080100");
//         setState(() {
//           _result = '1: $result1\n';
//         });
//       } else if (tag.type == NFCTagType.mifare_ultralight ||
//           tag.type == NFCTagType.mifare_classic ||
//           tag.type == NFCTagType.iso15693) {
//         var ndefRecords = await FlutterNfcKit.readNDEFRecords();
//         var ndefString = '';
//         for (int i = 0; i < ndefRecords.length; i++) {
//           ndefString += '${i + 1}: ${ndefRecords[i]}\n';
//         }
//         setState(() {
//           _result = ndefString;
//         });
//       } else if (tag.type == NFCTagType.webusb) {
//         var r = await FlutterNfcKit.transceive("00A4040006D27600012401");
//         print(r);
//       }
//     } catch (e) {
//       setState(() {
//         _result = 'error: $e';
//       });
//     }

//     if (!kIsWeb) {
//       await Future.delayed(Duration(seconds: 1));
//     }
//     await FlutterNfcKit.finish(iosAlertMessage: "Finished!");
//   }

//   @override
//   Widget build(BuildContext context) {
//     return MaterialApp(
//       home: Scaffold(
//         appBar: AppBar(
//           title: Center(
//             child: Row(
//               children: [
//                 Text('    Verify'),
//               ],
//             ),
//           ),
//         ),
//         body: Scrollbar(
//           child: SingleChildScrollView(
//             child: Center(
//               child: Column(
//                 mainAxisAlignment: MainAxisAlignment.center,
//                 children: <Widget>[
//                   const SizedBox(height: 20),
//                   const SizedBox(height: 10),
//                   ElevatedButton(
//                     onPressed: _scanNFC,
//                     child: Text('Click here to verify your tag'),
//                   ),
//                   const SizedBox(height: 10),
//                   Padding(
//                     padding: const EdgeInsets.symmetric(horizontal: 20),
//                     child: _tag != null
//                         ? Text('ID: ${_tag!.id}')
//                         : const Text('No tag polled yet.'),
//                   ),
//                   FutureBuilder<DocumentSnapshot>(
//                     future: FirebaseFirestore.instance.collection('RegisteredTag').doc('Dm1EJYCnuBuGcU7P9ag5').get(),
//                     builder: (context, snapshot) {
//                       if (snapshot.connectionState == ConnectionState.waiting) {
//                         return CircularProgressIndicator();
//                       } else if (snapshot.hasError) {
//                         return Text("Error: ${snapshot.error}");
//                       } else if (!snapshot.hasData || !snapshot.data!.exists) {
//                         return Text("Unregistered Tag");
//                       } else {
//                         Map<String, dynamic> data = snapshot.data!.data() as Map<String, dynamic>;

//                         // Ensure _tag is not null before accessing _tag!.id
//                         if (_tag != null && data.containsKey('User') && data['User'] is Map) {
//                           Map<String, dynamic> userMap = data['User'];
//                           String specificId = _tag!.id; // the actual ID you want to check

//                           if (userMap.containsKey(specificId)) {
//                             return FutureBuilder<DocumentSnapshot>(
//                               future: FirebaseFirestore.instance.collection('users').doc(userMap[specificId].toString()).get(),
//                               builder: (context, userSnapshot) {
//                                 if (userSnapshot.connectionState == ConnectionState.waiting) {
//                                   return CircularProgressIndicator();
//                                 } else if (userSnapshot.hasError) {
//                                   return Text("Error: ${userSnapshot.error}");
//                                 } else if (!userSnapshot.hasData || !userSnapshot.data!.exists) {
//                                   return Text("User does not exist");
//                                 } else {
//                                   Map<String, dynamic> userData = userSnapshot.data!.data() as Map<String, dynamic>;
//                                   return Text("ID exists: ${userData['candidate_name']}");
//                                 }
//                               },
//                             );
//                           } else {
//                             return Text("User does not exist");
//                           }
//                         } else {
//                           return Text("Unregistered Tag");
//                         }
//                       }
//                     },
//                   ),
//                   ElevatedButton(
//                     onPressed: () {
//                       Navigator.pop(context);
//                     },
//                     child: Text('Back'),
//                   ),
//                   ElevatedButton(
//                     onPressed: () async {
//                       ScaffoldMessenger.of(context).showSnackBar(
//                             const SnackBar(
//                               content: Text('Functionality yet to build'),
//                             ),
//                           );
//                     },
//                     child: Text('View Result'),
//                   ),
//                 ],
//               ),
//             ),
//           ),
//         ),
//       ),
//     );
//   }
// }












































// import 'package:flutter/material.dart';
// import 'package:font_awesome_flutter/font_awesome_flutter.dart';

// class ScanMifareClassic extends StatefulWidget {
//   @override
//   _ScanMifareClassicState createState() => _ScanMifareClassicState();
// }

// class _ScanMifareClassicState extends State<ScanMifareClassic> {
//   bool _isScanning = false;

//   void _startScanning() {
//     setState(() {
//       _isScanning = true;
//     });

//     // Add your scanning logic here

//     // Simulate a scan delay
//     Future.delayed(Duration(seconds: 3), () {
//       setState(() {
//         _isScanning = false;
//       });

//       // Navigate to the next page or show scan result
//       ScaffoldMessenger.of(context).showSnackBar(
//         SnackBar(content: Text('Scan complete!')),
//       );
//     });
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(
//         title: Row(
//           mainAxisAlignment: MainAxisAlignment.center,
//           children: [
//             Icon(FontAwesomeIcons.idCard, color: Colors.white),
//             SizedBox(width: 10),
//             Text('Scan Card', style: Theme.of(context).textTheme.headline1),
//           ],
//         ),
//       ),
//       body: Center(
//         child: Padding(
//           padding: const EdgeInsets.all(20.0),
//           child: Column(
//             mainAxisAlignment: MainAxisAlignment.center,
//             children: [
//               Container(
//                 height: 200,
//                 width: 200,
//                 decoration: BoxDecoration(
//                   borderRadius: BorderRadius.circular(20),
//                   image: DecorationImage(
//                     image: AssetImage('assets/innerScan.gif'), // Replace with your asset path
//                     fit: BoxFit.cover,
//                   ),
//                 ),
//               ),
//               SizedBox(height: 40),
//               Text(
//                 'Hold your card near the device to scan',
//                 style: Theme.of(context).textTheme.headline1!.copyWith(color: Colors.black),
//                 textAlign: TextAlign.center,
//               ),
//               SizedBox(height: 40),
//               _isScanning
//                   ? CircularProgressIndicator()
//                   : ElevatedButton.icon(
//                       onPressed: _startScanning,
//                       icon: Icon(FontAwesomeIcons.play, color: Colors.white),
//                       label: Padding(
//                         padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 10.0),
//                         child: Text('Start Scanning', style: Theme.of(context).textTheme.button),
//                       ),
//                       style: ElevatedButton.styleFrom(
//                         textStyle: TextStyle(fontSize: 20),
//                         minimumSize: Size(250, 60), // Enlarging the button
//                       ),
//                     ),
//             ],
//           ),
//         ),
//       ),
//     );
//   }
// }






























































import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter/foundation.dart';
import 'dart:async';
import 'dart:io' show Platform;

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
                          future: FirebaseFirestore.instance.collection('RegisteredTag').doc('Dm1EJYCnuBuGcU7P9ag5').get(),
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
                                    future: FirebaseFirestore.instance.collection('users').doc(userMap[specificId].toString()).get(),
                                    builder: (context, userSnapshot) {
                                      if (userSnapshot.connectionState == ConnectionState.waiting) {
                                        return CircularProgressIndicator();
                                      } else if (userSnapshot.hasError) {
                                        return Text("Error: ${userSnapshot.error}");
                                      } else if (!userSnapshot.hasData || !userSnapshot.data!.exists) {
                                        return Text("User does not exist");
                                      } else {
                                        Map<String, dynamic> userData = userSnapshot.data!.data() as Map<String, dynamic>;
                                        return Text("ID exists: ${userData['candidate_name']}");
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
}

void main() {
  runApp(MaterialApp(
    home: ScanMifareClassic(),
  ));
}
