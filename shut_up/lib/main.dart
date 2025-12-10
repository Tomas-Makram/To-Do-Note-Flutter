import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:shut_up/Screens/welcome_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  try {
    await Firebase.initializeApp(
      options: const FirebaseOptions(
        apiKey: "AIzaSyBWYOt-bofEFWmg68e4SHJayZQPXtzALv0",
        appId: "1:796833122032:android:ed21d7f1f5f1b3d2342435",
        messagingSenderId: "796833122032",
        projectId: "shut-up-app-3d55f",
        authDomain: "shut-up-app-3d55f.firebaseapp.com",
        storageBucket: "shut-up-app-3d55f.appspot.com",
        databaseURL: "https://shut-up-app-3d55f-default-rtdb.firebaseio.com/",
      ),
    );
    
    print('✅ Firebase initialized successfully!');

  } catch (e) {
    print('❌ Initialization error: $e');
  }
  
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Shut Up',
      theme: ThemeData(
        primarySwatch: Colors.deepOrange,
        useMaterial3: true,
      ),
      debugShowCheckedModeBanner: false,
      home: const WelcomeScreen(),
    );
  }
}