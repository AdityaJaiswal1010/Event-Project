// import 'package:flutter/widgets.dart';
// import 'dart:async';
// import 'package:splashscreen/splashscreen.dart';

// import 'package:flutter/material.dart';
// import 'package:font_awesome_flutter/font_awesome_flutter.dart';

// import 'app.dart';
// class MyApp extends StatelessWidget {
//   @override
//   Widget build(BuildContext context) {
//     return MaterialApp(
//       title: 'Splash Screen',
//       theme: ThemeData(
//         primarySwatch: Colors.green,
//       ),
//       home: Splash2(),
//       debugShowCheckedModeBanner: false,
//     );
//   }
// }
// class Splash2 extends StatelessWidget {
//   @override
//   Widget build(BuildContext context) {
//     return SplashScreen(
//       seconds: 6,
//       navigateAfterSeconds: new SecondScreen(),
//       title: new Text('GeeksForGeeks',textScaleFactor: 2,),
//       image: new Image.network('https://www.geeksforgeeks.org/wp-content/uploads/gfg_200X200.png'),
//       loadingText: Text("Loading"),
//       photoSize: 100.0,
//       loaderColor: Colors.blue,
//     );
//   }
// }
// class SecondScreen extends StatelessWidget {
//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(title:Text("GeeksForGeeks")),
//       body: Center(
//         child:Text("Home page",textScaleFactor: 2,)
//       ),
//     );
//   }
// }