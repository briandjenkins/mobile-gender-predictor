import 'package:flutter/material.dart';
import 'package:flutter/src/widgets/framework.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class ResultScreen extends ConsumerWidget {
  String gender;

  ResultScreen({super.key, required this.gender});

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
        )
      ]),
    );
  }
}
