import 'package:flutter/material.dart';

import 'CustomCropperScreen.dart';
import 'PredefinedCropperScreen.dart';
import 'SquareCropperScreen.dart';
class CropperScreen extends StatefulWidget {
  @override
  _CropperScreenState createState() => _CropperScreenState();
}

class _CropperScreenState extends State<CropperScreen>
    with SingleTickerProviderStateMixin {
  late TabController controller;
  bool isGallery = true;
  int index = 1;
  final PageStorageBucket bucket = PageStorageBucket();

  @override
  void initState() {
    super.initState();
    controller = TabController(length: 1, vsync: this);
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(
      title: Text("Crop Image"),
      centerTitle: false,
      actions: [
        Row(
          children: [
            Text(
              isGallery ? 'Gallery' : 'Camera',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            Switch(
              value: isGallery,
              onChanged: (value) => setState(() => isGallery = value),
            ),
          ],
        ),
      ],

    ),
    body: Column(
      children: [
        Container(
          color: Theme.of(context).primaryColor,
          child: TabBar(
            controller: controller,
            indicatorWeight: 3,
            labelStyle: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
            tabs: [
              Tab(text: 'Images'),
            ],
          ),
        ),
        Expanded(
          child: TabBarView(
            controller: controller,
            children: [
              IndexedStack(
                index: index,
                children: [
                  SquareCropperScreen(isGallery: isGallery, key: null,),
                  CustomCropperScreen(isGallery: isGallery, key: null,),
                  PredefinedCropperScreen(isGallery: isGallery, key: null,),
                ],
              ),
            ],
          ),
        ),
      ],
    ),
    bottomNavigationBar: buildBottomBar(),
  );

  Widget buildBottomBar() {
    final style = TextStyle(color: Theme.of(context).accentColor);

    return BottomNavigationBar(
      backgroundColor: Colors.black,
      selectedItemColor: Colors.white,
      unselectedItemColor: Colors.white70,
      currentIndex: index,
      items: [
        BottomNavigationBarItem(
          icon: Text('Cropper', style: style),
          label: 'Square',
        ),
        BottomNavigationBarItem(
          icon: Text('Cropper', style: style),
          label: 'Custom',
        ),
        BottomNavigationBarItem(
          icon: Text('Cropper', style: style),
          label: 'Predefined',
        ),
      ],
      onTap: (int index) => setState(() => this.index = index),
    );
  }
}