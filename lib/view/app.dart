import 'dart:async';
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:app/view/AddNewStall.dart';
import 'package:app/view/StallLocationMap.dart';
import 'package:app/view/qrCodeView.dart';
import 'package:app/view/volunteerAdmins.dart';
import 'package:app/view/ScanMifareClassic.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  runApp(App());
}

class App extends StatefulWidget {
  static Future<Widget> withDependency() async {
    return App();
  }

  @override
  State<App> createState() => _AppState();
}

class _AppState extends State<App> {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: _Home(),
      theme: ThemeData(
        primaryColor: Color(0xFF00BFA5),
        hintColor: Color(0xFF004D40),
        scaffoldBackgroundColor: Color(0xFFE0F2F1),
        appBarTheme: AppBarTheme(
          color: Color(0xFF004D40),
        ),
        textTheme: TextTheme(
          headline1: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
          button: TextStyle(
            fontSize: 18,
            color: Colors.white,
          ),
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            primary: Color(0xFF00BFA5),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
            elevation: 5,
          ),
        ),
      ),
    );
  }
}

class _Home extends StatefulWidget {
  @override
  State<_Home> createState() => _HomeState();
}

class _HomeState extends State<_Home> {
  final PageController _pageController = PageController();
  int _currentPage = 0;
  List<String> _sponsorImages = [];

  @override
  void initState() {
    super.initState();
    _fetchSponsorImages();
    Timer.periodic(Duration(seconds: 3), (Timer timer) {
      if (_currentPage < _sponsorImages.length - 1) {
        _currentPage++;
      } else {
        _currentPage = 0;
      }

      _pageController.animateToPage(
        _currentPage,
        duration: Duration(milliseconds: 300),
        curve: Curves.easeIn,
      );
    });
  }

  Future<void> _fetchSponsorImages() async {
  try {
    // Fetch the document
    DocumentSnapshot document = await FirebaseFirestore.instance
        .collection('sponsors')
        .doc('r3z4n6BakiznKdWnIluv')
        .get();

    // Check if the document exists
    if (document.exists) {
      // Extract the 'images' field from the document
      List<dynamic> images = document.get('images');
      
      // Ensure 'images' is a list and handle it
      if (images is List) {
        setState(() {
          // Update the _sponsorImages list with the fetched URLs
          _sponsorImages = images.map((image) => image.toString()).toList();
        });
      }
    } else {
      print("Document does not exist");
    }
  } catch (e) {
    print("Error fetching sponsor images: $e");
  }
}


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(FontAwesomeIcons.ticketAlt, color: Colors.white),
            SizedBox(width: 10),
            Text('Event App', style: Theme.of(context).textTheme.headline1),
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
                SizedBox(
                  height: 150,
                  child: _sponsorImages.isEmpty
                      ? Center(child: CircularProgressIndicator())
                      : PageView.builder(
                          controller: _pageController,
                          itemCount: _sponsorImages.length,
                          itemBuilder: (context, index) {
                            return Image.network(
                              _sponsorImages[index],
                              fit: BoxFit.contain,
                            );
                          },
                        ),
                ),
                SizedBox(height: 20),
                Container(
                  height: 200,
                  width: 200,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(20),
                    image: DecorationImage(
                      image: AssetImage('assets/scanning.gif'),
                      fit: BoxFit.cover,
                    ),
                  ),
                ),
                SizedBox(height: 40),
                Text(
                  'Welcome to the Event',
                  style: Theme.of(context).textTheme.headline1!.copyWith(color: Colors.black),
                ),
                SizedBox(height: 40),
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      _buildRoundedSquareButton(
                        context,
                        'Scan Card',
                        FontAwesomeIcons.idCard,
                        ScanMifareClassic(),
                      ),
                      SizedBox(width: 20),
                      _buildRoundedSquareButton(
                        context,
                        'Volunteer Admins',
                        FontAwesomeIcons.users,
                        VolunteerAdmins(),
                      ),
                      SizedBox(width: 20),
                      _buildRoundedSquareButton(
                        context,
                        'Add New Stall',
                        FontAwesomeIcons.plus,
                        AddNewStall(),
                      ),
                      SizedBox(width: 20),
                      _buildRoundedSquareButton(
                        context,
                        'QR Code Scan',
                        FontAwesomeIcons.qrcode,
                        QrCodeView(),
                      ),
                      SizedBox(width: 20),
                      _buildRoundedSquareButton(
                        context,
                        'View Stalls',
                        FontAwesomeIcons.mapMarkerAlt,
                        StallLocationMap(),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildRoundedSquareButton(BuildContext context, String text, IconData icon, Widget page) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => page),
        );
      },
      child: Column(
        children: [
          Container(
            height: 100,
            width: 100,
            decoration: BoxDecoration(
              color: Theme.of(context).primaryColor,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Center(
              child: Icon(icon, color: Colors.white, size: 40),
            ),
          ),
          SizedBox(height: 10),
          Text(
            text,
            style: Theme.of(context).textTheme.button!.copyWith(color: Colors.black),
          ),
        ],
      ),
    );
  }
}
