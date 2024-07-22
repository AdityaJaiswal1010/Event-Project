import 'package:app/view/app.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/widgets.dart';
//just first push
void main() async {
  WidgetsFlutterBinding.ensureInitialized();
   await Firebase.initializeApp();
  runApp(await App.withDependency());
}

