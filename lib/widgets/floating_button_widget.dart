import 'package:flutter/material.dart';

class FloatingButtonWidget extends StatelessWidget {
  final VoidCallback onClicked;

  const FloatingButtonWidget({
    required Key? key,
    required this.onClicked,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) => FloatingActionButton(
    heroTag: UniqueKey(),
    backgroundColor: Theme.of(context).primaryColor,
    shape: RoundedRectangleBorder(
      side: BorderSide(width: 2, color: Theme.of(context).floatingActionButtonTheme.backgroundColor!),
      borderRadius: BorderRadius.circular(12),
    ),
    child: Icon(Icons.add, color: Theme.of(context).appBarTheme.titleTextStyle?.color),
    onPressed: onClicked,
  );
}