import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gender_classifier/screens/HomeScreen.dart';
import 'package:gender_classifier/theme/octane_theme.dart';
import 'package:json_theme/json_theme.dart';
import 'package:flutter/services.dart'; // For rootBundle
import 'dart:convert'; // For jsonDecode



void main() async {

  WidgetsFlutterBinding.ensureInitialized();
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  final themeStr = await rootBundle.loadString('assets/themes/appainter_theme.json');
  final themeJson = jsonDecode(themeStr);
  final theme = ThemeDecoder.decodeThemeData(themeJson)!;

  runApp(ProviderScope(
    child: MyApp(theme: theme),
  ));
}

class MyApp extends StatelessWidget {
  final ThemeData theme;

  const MyApp({Key? key, required this.theme}) : super(key: key);
  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    // Close soft keyboard when a tap occurs outside of an input widget.
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () {
        FocusScope.of(context).requestFocus(FocusNode());
      },
      child: MaterialApp(
        title: 'Flutter Demo',
        theme: theme,
        // home: MyHomePage(title: 'Flutter Demo Home Page'),
        home: HomeScreen(),
      ),
    );
  }
}
