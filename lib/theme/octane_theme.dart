import 'package:flutter/material.dart';

class OctaneTheme {
  static ThemeData get lightTheme {
    return ThemeData(
      primarySwatch: Colors.blue,
      brightness: Brightness.light,
      primaryColor: Color(0xffff6c0e),
      disabledColor: Colors.red,
      scaffoldBackgroundColor: Colors.white,
      fontFamily: 'Montserrat', //3
      buttonTheme: ButtonThemeData(
        // 4
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18.0)),
        buttonColor: Color(0xffe0e0e0),
      ),
      textTheme: const TextTheme(
        headline1: TextStyle(fontSize: 72.0, fontWeight: FontWeight.bold),
        headline6: TextStyle(fontSize: 36.0, fontStyle: FontStyle.italic),
        bodyText2: TextStyle(fontSize: 18.0, fontFamily: 'Hind'),
      ),
      sliderTheme: SliderThemeData(
          activeTrackColor: Color(0xff5b656d),
          thumbColor: Color(0xff323e48),
          inactiveTrackColor: Color(0xff848b91),
      ),
    );
  }
}
