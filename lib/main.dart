import 'package:flutter/material.dart';
import 'package:weather/weather.dart';
import 'package:weather_app/PermissionScreen.dart';

import 'SplashScreen.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
        title: Strings.appTitle,
        theme: ThemeData(
          primarySwatch: Colors.blue,
        ),
        home: SplashScreen());
  }
}

class Strings {
  //jeśli jakiś tekst się powtarza można wydzielić klase w której zapiszemy Stringi
  static const String appTitle = 'Clean Air';
}
