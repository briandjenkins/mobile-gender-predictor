import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_progress_hud/flutter_progress_hud.dart';
import 'package:image_cropper/image_cropper.dart';
import 'package:image_size_getter/file_input.dart';
import 'package:image_size_getter/image_size_getter.dart';

import '../screens/ResultScreen.dart';
import '../services/HttpService.dart';

class ImageListWidget extends StatelessWidget {
  final List<CroppedFile> imageFiles;

  const ImageListWidget({
    required Key? key,
    required this.imageFiles,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return GridView.count(
      physics: BouncingScrollPhysics(),
      padding: EdgeInsets.all(12),
      crossAxisCount: 2,
      crossAxisSpacing: 12,
      mainAxisSpacing: 12,
      children: imageFiles.map((imageFile) {
        final size = ImageSizeGetter.getSize(FileInput(File(imageFile.path)));
        return Dismissible(
            key: UniqueKey(),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: Container(
                color: Theme.of(context).primaryColor,
                child: InkWell(
                    onTap: () {
                      ProgressHUD.of(context)!.show();
                      Future classifier = HttpService.classify(File(imageFile.path));
                      classifier.then((response) {
                        print(response.statusCode);
                        response.stream.transform(utf8.decoder).listen((value) {
                          print(value);
                          Map<String, dynamic> genderJson = json.decode(value);
                          // Navigate to screen, which will display the classification result.
                          ProgressHUD.of(context)!.dismiss();
                          Navigator.push(
                            context,
                            MaterialPageRoute(builder: (context) => ResultScreen(gender: genderJson['gender'])),
                          );
                        });
                      });
                      print("now what!");
                    },
                    child: Stack(children: <Widget>[
                      Center(
                        child: SingleChildScrollView(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              Padding(
                                padding: const EdgeInsets.all(25.0),
                                child: Image.file(File(imageFile.path)),
                              ),
                            ],
                          ),
                        ),
                      ),
                      Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.end,
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            Padding(
                              padding: const EdgeInsets.all(5.0),
                              child: Text('${size.width}px X ${size.height}px',
                                  style: TextStyle(fontSize: 16, color: Theme.of(context).appBarTheme.titleTextStyle?.color), textAlign: TextAlign.center),
                            )
                          ],
                        ),
                      ),
                    ])),
              ),
            ),
            //the widget you want the swipe to be detected on
            direction: DismissDirection.up, // or whatever
            confirmDismiss: (direction) {
              if (direction == DismissDirection.up) {
                imageFiles.remove(imageFile);
                ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                  content: Text('Image removed.'),
                  action: SnackBarAction(
                    label: 'Dissmiss',
                    textColor: Colors.limeAccent,
                    onPressed: () {
                      ScaffoldMessenger.of(context).hideCurrentSnackBar();
                    },
                  ),
                ));
              }
              return Future.value(true); // always deny the actual dismiss, else it will expect the widget to be removed
            });
      }).toList(),
    );
  }
}
