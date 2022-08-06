import 'package:flutter/material.dart';
import 'package:flutter/src/widgets/framework.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class ResultScreen extends ConsumerWidget {
  String gender;
  int statusCode;

  ResultScreen({super.key, required this.gender, required this.statusCode});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      body: Stack(children: <Widget>[
        Container(
          width: double.infinity,
          height: double.infinity,
          alignment: Alignment.center,
          color: Colors.blue.shade300,
          child: Center(child: (gender == "male") ? Image.asset('assets/images/male.png') : Image.asset('assets/images/female.png')),
        ),
        Container(
            child: Positioned(
          child: Align(
            alignment: Alignment.bottomCenter,
            child: Padding(
              padding: EdgeInsets.all(10),
              child: Text(
                'Response Code: $statusCode',
                style: TextStyle(color: Colors.white, fontWeight: FontWeight.normal, fontSize: 15),
              ),
            ),
          ),
        ))
      ]),
    );
  }
}
