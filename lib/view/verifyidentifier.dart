import 'dart:async';
    import 'dart:io' show Platform, sleep;

    import 'package:flutter/foundation.dart';
    import 'package:flutter/material.dart';
    import 'package:flutter/services.dart';
    import 'package:flutter_nfc_kit/flutter_nfc_kit.dart';
    import 'package:logging/logging.dart';
    import 'package:cloud_firestore/cloud_firestore.dart';
import "package:contacts_service/contacts_service.dart";
import 'package:firebase_core/firebase_core.dart';
    import 'package:ndef/ndef.dart' as ndef;

    class Sensors extends StatefulWidget {
      @override
      _MyAppState createState() => _MyAppState();
    }

    class _MyAppState extends State<Sensors> with SingleTickerProviderStateMixin {
      String _platformVersion = '';
        TextEditingController regnoController=TextEditingController();

      NFCAvailability _availability = NFCAvailability.not_supported;
      NFCTag? _tag;
      String? _result, _writeResult;
      late TabController _tabController;
      List<ndef.NDEFRecord>? _records;

      @override
      void dispose() {
        _tabController.dispose();
        super.dispose();
      }

      @override
      void initState() {
        super.initState();
        if (!kIsWeb)
          _platformVersion =
              '${Platform.operatingSystem} ${Platform.operatingSystemVersion}';
        else
          _platformVersion = 'Web';
        initPlatformState();
        _tabController = new TabController(length: 2, vsync: this);
        _records = [];
      }

      // Platform messages are asynchronous, so we initialize in an async method.
      Future<void> initPlatformState() async {
        NFCAvailability availability;
        try {
          availability = await FlutterNfcKit.nfcAvailability;
        } on PlatformException {
          availability = NFCAvailability.not_supported;
        }

        // If the widget was removed from the tree while the asynchronous platform
        // message was in flight, we want to discard the reply rather than calling
        // setState to update our non-existent appearance.
        if (!mounted) return;

        setState(() {
          // _platformVersion = platformVersion;
          _availability = availability;
        });
      }

      @override
      Widget build(BuildContext context) {
        return MaterialApp(
          home: Scaffold(
            appBar: AppBar(
              title: const Text('Verify'),
            ),
            body: Scrollbar(
                child: SingleChildScrollView(
                    child: Center(
                        child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: <Widget>[
                  const SizedBox(height: 20),
                  TextField(
                      controller: regnoController,
                      decoration: InputDecoration(
                    border: OutlineInputBorder(),
                    labelText: 'Reg No',
                  ),
                    ),
                  // Text('Running on: $_platformVersion\nNFC: $_availability'),
                  const SizedBox(height: 10),
                  ElevatedButton(
                    onPressed: () async {
                      try {
                        NFCTag tag = await FlutterNfcKit.poll();
                        setState(() {
                          _tag = tag;
                        });
                        await FlutterNfcKit.setIosAlertMessage("Working on it...");
                        if (tag.standard == "ISO 14443-4 (Type B)") {
                          String result1 =
                              await FlutterNfcKit.transceive("00B0950000");
                          String result2 = await FlutterNfcKit.transceive(
                              "00A4040009A00000000386980701");
                          setState(() {
                            _result = '1: $result1\n2: $result2\n';
                          });
                        } else if (tag.type == NFCTagType.iso18092) {
                          String result1 =
                              await FlutterNfcKit.transceive("060080080100");
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
                          var r = await FlutterNfcKit.transceive(
                              "00A4040006D27600012401");
                          print(r);
                        }
                      } catch (e) {
                        setState(() {
                          _result = 'error: $e';
                        });
                      }

                      // Pretend that we are working
                      if (!kIsWeb) sleep(new Duration(seconds: 1));
                      await FlutterNfcKit.finish(iosAlertMessage: "Finished!");
                      FirebaseFirestore.instance.collection('tagmap').doc('jYBWvFrpb1QjIwBHhql7').update({
                        'Mapping':{regnoController.text.toString():_tag!.id}
                      });
                    },
                    child: Text('Click here to verify your tag'),
                    
                  ),
                  const SizedBox(height: 10),
                  
                  Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: _tag != null
                          ? Text(
                              'ID: ${_tag!.id}')
                          : const Text('No tag polled yet.')),
                ]
                
                )))),
                
          ),
        );
      }
    }