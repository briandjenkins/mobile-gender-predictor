import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_progress_hud/flutter_progress_hud.dart';
import 'package:gender_classifier/utilities/image_utils.dart';
import 'package:image_cropper/image_cropper.dart';
import '../utilities/utils.dart';
import '../widgets/image_list_widget.dart';
import '../widgets/floating_button_widget.dart';

class CustomCropperScreen extends StatefulWidget {
  final bool isGallery;

  const CustomCropperScreen({
    required Key? key,
    required this.isGallery,
  }) : super(key: key);

  @override
  _CustomCropperScreenState createState() => _CustomCropperScreenState();
}

class _CustomCropperScreenState extends State<CustomCropperScreen> {
  List<CroppedFile> imageFiles = [];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: ProgressHUD(
        borderColor: Colors.orange,
        barrierEnabled: true,
        backgroundColor: Theme.of(context).primaryColor,
        child: ImageListWidget(
          imageFiles: imageFiles,
          key: null,
        ),
      ),
      floatingActionButton: FloatingButtonWidget(
        onClicked: onClickedButton,
        key: null,
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
    );
  }

  Future onClickedButton() async {
    final file = await Utils.pickMedia(
      isGallery: widget.isGallery,
      cropImage: cropCustomImage,
    );

    if (file == null) return;
    setState(() {
      imageFiles.add(file);
      //getAssetImage(imageFiles);
    });
  }

  static Future<CroppedFile?> cropCustomImage(File imageFile) async => await ImageCropper().cropImage(
        aspectRatio: CropAspectRatio(ratioX: 3, ratioY: 2),
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

  // Future<CroppedFile?> getAssetImage(List<CroppedFile> imageFiles) async {
  //   File? f = await ImageUtils.imageToFile(imageName: 'images/131422', ext: 'jpg');
  //   CroppedFile cf = CroppedFile(f!.path);
  //   imageFiles.add(cf);
  //   return cf;
  // }
}
