import 'package:project_tracker/pages/intro_page.dart';
import 'package:project_tracker/pages/login_page.dart';
import 'package:project_tracker/pages/signup_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

void main() => runApp(MyApp());

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
      DeviceOrientation.portraitDown,
    ]);
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Login',
      theme: ThemeData(),
      //home: IntroPage(),
      initialRoute: '/intro',
      routes: {
        '/login': (BuildContext context) => Login(),
        '/signup': (BuildContext context) => SignUp(),
        '/intro': (BuildContext context) => IntroPage(),
      },
    );
  }
}
