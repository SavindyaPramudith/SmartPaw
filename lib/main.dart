import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'mainscreen.dart';
import 'login.dart';


void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false, //Hides the debug banner
      title: 'Smart Dog Collar', //app title
      theme: ThemeData(primarySwatch: Colors.blue),
      home: LoginScreen(), //Sets the initial screen
    );
  }
}



