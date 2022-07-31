import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_cropper/image_cropper.dart';
import '../utilities/utils.dart';
import '../widgets/image_list_widget.dart';
import '../widgets/floating_button_widget.dart';

class PredefinedCropperScreen extends StatefulWidget {
  final bool isGallery;

  const PredefinedCropperScreen({
    required Key? key,
    required this.isGallery,
  }) : super(key: key);

  @override
  _PredefinedCropperScreenState createState() => _PredefinedCropperScreenState();
}

class _PredefinedCropperScreenState extends State<PredefinedCropperScreen> {
  List<CroppedFile> imageFiles = [];

  @override
  Widget build(BuildContext context) => Scaffold(
    body: ImageListWidget(imageFiles: imageFiles, key: null,),
    floatingActionButton: FloatingButtonWidget(onClicked: onClickedButton, key: null,),
    floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
  );

  Future onClickedButton() async {
    final file = await Utils.pickMedia(
      isGallery: widget.isGallery,
      cropImage: cropPredefinedImage,
    );

    if (file == null) return;
    setState(() => imageFiles.add(file));
  }

  static Future<CroppedFile?> cropPredefinedImage(File imageFile) async =>
      await ImageCropper().cropImage(
        // aspectRatio: CropAspectRatio(ratioX: 16, ratioY: 9),
        sourcePath: imageFile.path,
        aspectRatioPresets: [
          CropAspectRatioPreset.original,
          CropAspectRatioPreset.ratio3x2,
          CropAspectRatioPreset.ratio4x3,
          CropAspectRatioPreset.ratio7x5,
          CropAspectRatioPreset.ratio16x9,
        ],
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
    initAspectRatio: CropAspectRatioPreset.original,
    lockAspectRatio: false,
  );
}