import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_cropper/image_cropper.dart';
import '../utilities/utils.dart';
import '../widgets/image_list_widget.dart';
import '../widgets/floating_button_widget.dart';

class SquareCropperScreen extends StatefulWidget {
  final bool isGallery;

  const SquareCropperScreen({
    required Key? key,
    required this.isGallery,
  }) : super(key: key);

  @override
  _SquareCropperScreenState createState() => _SquareCropperScreenState();
}

class _SquareCropperScreenState extends State<SquareCropperScreen> {

  BuildContext? buildContext2;

  List<CroppedFile> imageFiles = [];

  @override
  Widget build(BuildContext context) => Scaffold(
    body: ImageListWidget(imageFiles: imageFiles, key: null,),
    floatingActionButton: FloatingButtonWidget(onClicked: onClickedButton, key: null, ),
    floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
  );

  Future onClickedButton() async {
    final file = await Utils.pickMedia(
      isGallery: widget.isGallery,
      cropImage: cropCustomImage,
    );

    if (file == null) return;
    setState(() => imageFiles.add(file));
  }

  static Future<CroppedFile?> cropCustomImage(File imageFile) async =>
      await ImageCropper().cropImage(
        aspectRatio: CropAspectRatio(ratioX: 16, ratioY: 9),
        sourcePath: imageFile.path,
        uiSettings: [
          androidUiSettings(),
          iosUiSettings(),
        ],
      );

  static IOSUiSettings iosUiSettings() => IOSUiSettings(
    aspectRatioLockEnabled: false,
  );

  static AndroidUiSettings androidUiSettings() => AndroidUiSettings(
    toolbarTitle: 'Crop Image',
    toolbarColor: Colors.blue,
    toolbarWidgetColor: Colors.white,
    lockAspectRatio: false,
  );
}