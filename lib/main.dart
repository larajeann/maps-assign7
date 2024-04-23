import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'firebase_options.dart';
import 'locationMapScreen.dart';
import 'mapScreen.dart';

void main() async{
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
   options: DefaultFirebaseOptions.currentPlatform,
 );
  runApp(const WebAPI());
}

class WebAPI extends StatelessWidget {
  const WebAPI({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: MapsScreen(),
    );
  }
}