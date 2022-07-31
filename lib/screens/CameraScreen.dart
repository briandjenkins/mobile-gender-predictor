import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:math';
import 'dart:ui';
import 'package:audioplayers/audioplayers.dart';
import 'package:path_provider/path_provider.dart';
import 'package:camerawesome/models/orientations.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_progress_hud/flutter_progress_hud.dart';
import 'package:image/image.dart' as ImageProcess;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:video_player/video_player.dart';
import 'package:camerawesome/camerawesome_plugin.dart';
import '../services/HttpService.dart';
import '../utilities/camera_orientation_utils.dart';
import '../services/ApplicationService.dart';
import 'ResultScreen.dart';

class CameraScreen extends StatefulWidget {
  final bool randomPhotoName;

  CameraScreen({this.randomPhotoName = true});

  @override
  _CameraScreen createState() => _CameraScreen();
}

class _CameraScreen extends State<CameraScreen> with TickerProviderStateMixin {
  final AudioCache player = AudioCache();
  final alarmAudioPath = "audio/178186__snapper4298__camera-click-nikon.wav";

  String? _lastPhotoPath;
  String? _lastVideoPath;
  bool _focus = false, _fullscreen = true, _isRecordingVideo = false;

  final ValueNotifier<CameraFlashes> _switchFlash = ValueNotifier(CameraFlashes.NONE);
  final ValueNotifier<double> _zoomNotifier = ValueNotifier(0);
  final ValueNotifier<Size> _photoSize = ValueNotifier(Size(30, 30));
  final ValueNotifier<Sensors> _sensor = ValueNotifier(Sensors.BACK);
  final ValueNotifier<CaptureModes> _captureMode = ValueNotifier(CaptureModes.PHOTO);
  final ValueNotifier<bool> _enableAudio = ValueNotifier(true);
  final ValueNotifier<CameraOrientations> _orientation = ValueNotifier(CameraOrientations.PORTRAIT_UP);

  /// use this to call a take picture
  final PictureController _pictureController = PictureController();

  /// use this to record a video
  final VideoController _videoController = VideoController();

  /// list of available sizes
  List<Size>? _availableSizes;

  AnimationController? _iconsAnimationController, _previewAnimationController;
  Animation<Offset>? _previewAnimation;
  Timer? _previewDismissTimer;
  // StreamSubscription<Uint8List> previewStreamSub;
  Stream<Uint8List>? previewStream;

  @override
  void initState() {
    super.initState();
    _iconsAnimationController = AnimationController(
      vsync: this,
      duration: Duration(milliseconds: 300),
    );

    _previewAnimationController = AnimationController(
      duration: const Duration(milliseconds: 1300),
      vsync: this,
    );
    _previewAnimation = Tween<Offset>(
      begin: const Offset(-2.0, 0.0),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(
        parent: _previewAnimationController!,
        curve: Curves.elasticOut,
        reverseCurve: Curves.elasticIn,
      ),
    );
  }

  @override
  void dispose() {
    _iconsAnimationController?.dispose();
    _previewAnimationController?.dispose();
    // previewStreamSub.cancel();
    _photoSize.dispose();
    _captureMode.dispose();
    super.dispose();
  }

  void _backScreen() {
    // Remove this screen and surface the image panel on the item
    // screen's stack, and, finally, refresh the item screen's UI.
    ApplicationService.file = null;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: ProgressHUD(
        borderColor: Colors.orange,
        backgroundColor: Colors.blue.shade300,
        child: WillPopScope(
          onWillPop: () async {
            _backScreen();
            //we need to return a future
            return true;
          },
          child: Stack(
            fit: StackFit.expand,
            children: <Widget>[
              _fullscreen ? buildFullscreenCamera() : buildSizedScreenCamera(),
              _buildInterface(),
              (!_isRecordingVideo)
                  ? PreviewCardWidget(
                      lastPhotoPath: _lastPhotoPath,
                      orientation: _orientation,
                      previewAnimation: _previewAnimation!,
                    )
                  : Container(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInterface() {
    return Stack(
      children: <Widget>[
        SafeArea(
          bottom: false,
          child: TopBarWidget(
              isFullscreen: _fullscreen,
              isRecording: _isRecordingVideo,
              enableAudio: _enableAudio,
              photoSize: _photoSize,
              captureMode: _captureMode,
              switchFlash: _switchFlash,
              orientation: _orientation,
              rotationController: _iconsAnimationController!,
              onFlashTap: () {
                switch (_switchFlash.value) {
                  case CameraFlashes.NONE:
                    _switchFlash.value = CameraFlashes.ON;
                    break;
                  case CameraFlashes.ON:
                    _switchFlash.value = CameraFlashes.AUTO;
                    break;
                  case CameraFlashes.AUTO:
                    _switchFlash.value = CameraFlashes.ALWAYS;
                    break;
                  case CameraFlashes.ALWAYS:
                    _switchFlash.value = CameraFlashes.NONE;
                    break;
                }
                setState(() {});
              },
              onAudioChange: () {
                this._enableAudio.value = !this._enableAudio.value;
                setState(() {});
              },
              onChangeSensorTap: () {
                _focus = !_focus;
                if (_sensor.value == Sensors.FRONT) {
                  _sensor.value = Sensors.BACK;
                } else {
                  _sensor.value = Sensors.FRONT;
                }
              },
              onResolutionTap: () => _buildChangeResolutionDialog(),
              onFullscreenTap: () {
                _fullscreen = !_fullscreen;
                setState(() {});
              }),
        ),
        BottomBarWidget(
          onZoomInTap: () {
            if (_zoomNotifier.value <= 0.9) {
              _zoomNotifier.value += 0.1;
            }
            setState(() {});
          },
          onZoomOutTap: () {
            if (_zoomNotifier.value >= 0.1) {
              _zoomNotifier.value -= 0.1;
            }
            setState(() {});
          },
          onCaptureModeSwitchChange: () {
            if (_captureMode.value == CaptureModes.PHOTO) {
              _captureMode.value = CaptureModes.VIDEO;
            } else {
              _captureMode.value = CaptureModes.PHOTO;
            }
            setState(() {});
          },
          onCaptureTap: (_captureMode.value == CaptureModes.PHOTO) ? _takePhoto : _recordVideo,
          rotationController: _iconsAnimationController!,
          orientation: _orientation,
          isRecording: _isRecordingVideo,
          captureMode: _captureMode,
        ),
      ],
    );
  }

  _takePhoto() async {
    final Directory extDir = await getTemporaryDirectory();
    final testDir = await Directory('${extDir.path}/test').create(recursive: true);
    final String filePath = widget.randomPhotoName ? '${testDir.path}/${DateTime.now().millisecondsSinceEpoch}.jpg' : '${testDir.path}/photo_test.jpg';
    await _pictureController.takePicture(filePath);
    // lets just make our phone vibrate
    HapticFeedback.heavyImpact();
    _lastPhotoPath = filePath;
    setState(() {});
    if (_previewAnimationController!.status == AnimationStatus.completed) {
      _previewAnimationController!.reset();
    }
    _previewAnimationController!.forward();
    print("----------------------------------");
    print("TAKE PHOTO CALLED");
    final file = File(filePath);
    print("==> hastakePhoto : ${file.exists()} | path : $filePath");
    ImageProcess.Image? img = ImageProcess.decodeImage(file.readAsBytesSync());
    ImageProcess.Image resizedImage = ImageProcess.copyResize(img!, width: 32, height: 32);
    print("==> img.width : ${resizedImage!.width} | img.height : ${resizedImage.height}");
    // Convert to base64 and store the result in the Camera provider.
    //String base64Image = base64Encode(ImageProcess.encodePng(img));
    //Provider.of<CameraProvider>(context, listen: false).imageBase64 = base64Image;
    //ApplicationService.file = file;
    file.writeAsBytesSync(ImageProcess.encodeJpg(resizedImage));
    ApplicationService.file = file;
    print("----------------------------------");
    player.play(alarmAudioPath);
    // Surface preview screen.
  }

  _recordVideo() async {
    // lets just make our phone vibrate
    HapticFeedback.mediumImpact();

    if (_isRecordingVideo) {
      await _videoController.stopRecordingVideo();

      _isRecordingVideo = false;
      setState(() {});

      final file = File(_lastVideoPath!);
      print("----------------------------------");
      print("VIDEO RECORDED");
      print("==> has been recorded : ${file.exists()} | path : $_lastVideoPath");
      print("----------------------------------");

      await Future.delayed(const Duration(milliseconds: 300));
      await Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => CameraPreview(
            videoPath: _lastVideoPath!,
          ),
        ),
      );
    } else {
      final Directory extDir = await getTemporaryDirectory();
      final testDir = await Directory('${extDir.path}/test').create(recursive: true);
      final String filePath = widget.randomPhotoName ? '${testDir.path}/${DateTime.now().millisecondsSinceEpoch}.mp4' : '${testDir.path}/video_test.mp4';
      await _videoController.recordVideo(filePath);
      _isRecordingVideo = true;
      _lastVideoPath = filePath;
      setState(() {});
    }
  }

  _buildChangeResolutionDialog() {
    showModalBottomSheet(
      context: context,
      builder: (context) => ListView.separated(
        itemBuilder: (context, index) => ListTile(
          key: ValueKey("resOption"),
          onTap: () {
            this._photoSize.value = _availableSizes![index];
            setState(() {});
            Navigator.of(context).pop();
          },
          leading: Icon(Icons.aspect_ratio),
          title: Text("${_availableSizes![index].width}/${_availableSizes![index].height}"),
        ),
        separatorBuilder: (context, index) => Divider(),
        itemCount: _availableSizes!.length,
      ),
    );
  }

  void _onOrientationChange(CameraOrientations? newOrientation) {
    _orientation.value = newOrientation!;
    if (_previewDismissTimer != null) {
      _previewDismissTimer!.cancel();
    }
  }

  void _onPermissionsResult(bool? granted) {
    if (!granted!) {
      AlertDialog alert = AlertDialog(
        title: Text('Error'),
        content: Text('It seems that all required permissions have not been authorized. Please check on your settings and try again.'),
        actions: [
          TextButton(
            child: Text('OK'),
            onPressed: () => Navigator.of(context).pop(),
          ),
        ],
      );

      // show the dialog
      showDialog(
        context: context,
        builder: (BuildContext context) {
          return alert;
        },
      );
    } else {
      setState(() {});
      print("granted");
    }
  }

  Widget buildFullscreenCamera() {
    return Positioned(
      top: 0,
      left: 0,
      bottom: 0,
      right: 0,
      child: Center(
        child: CameraAwesome(
          onPermissionsResult: _onPermissionsResult,
          selectDefaultSize: (availableSizes) {
            this._availableSizes = availableSizes;
            return availableSizes[5];
          },
          captureMode: _captureMode,
          photoSize: _photoSize,
          sensor: _sensor,
          enableAudio: _enableAudio,
          switchFlashMode: _switchFlash,
          zoom: _zoomNotifier,
          onOrientationChanged: _onOrientationChange,
          //orientation: DeviceOrientation.portraitUp,
          // imagesStreamBuilder: (imageStream) {
          //   /// listen for images preview stream
          //   /// you can use it to process AI recognition or anything else...
          //   print("-- init CamerAwesome images stream");
          //   setState(() {
          //     previewStream = imageStream;
          //   });

          //   imageStream.listen((Uint8List imageData) {
          //     print(
          //         "...${DateTime.now()} new image received... ${imageData.lengthInBytes} bytes");
          //   });
          // },
          onCameraStarted: () {
            // camera started here -- do your after start stuff
          },
        ),
      ),
    );
  }

  Widget buildSizedScreenCamera() {
    return Positioned(
      top: 0,
      left: 0,
      bottom: 0,
      right: 0,
      child: Container(
        color: Colors.black,
        child: Center(
          child: Container(
            height: 300,
            width: MediaQuery.of(context).size.width,
            child: CameraAwesome(
              onPermissionsResult: _onPermissionsResult,
              selectDefaultSize: (availableSizes) {
                this._availableSizes = availableSizes;
                return availableSizes[0];
              },
              captureMode: _captureMode,
              photoSize: _photoSize,
              sensor: _sensor,
              fitted: true,
              switchFlashMode: _switchFlash,
              zoom: _zoomNotifier,
              onOrientationChanged: _onOrientationChange,
            ),
          ),
        ),
      ),
    );
  }
}

class PreviewCardWidget extends StatelessWidget {
  final String? lastPhotoPath;
  final Animation<Offset> previewAnimation;
  final ValueNotifier<CameraOrientations> orientation;

  const PreviewCardWidget({
    Key? key,
    required this.lastPhotoPath,
    required this.previewAnimation,
    required this.orientation,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    Alignment alignment;
    bool mirror;
    switch (orientation.value) {
      case CameraOrientations.PORTRAIT_UP:
      case CameraOrientations.PORTRAIT_DOWN:
        alignment = orientation.value == CameraOrientations.PORTRAIT_UP ? Alignment.bottomLeft : Alignment.topLeft;
        mirror = orientation.value == CameraOrientations.PORTRAIT_DOWN;
        break;
      case CameraOrientations.LANDSCAPE_LEFT:
      case CameraOrientations.LANDSCAPE_RIGHT:
        alignment = Alignment.topLeft;
        mirror = orientation.value == CameraOrientations.LANDSCAPE_LEFT;
        break;
    }

    return Align(
      alignment: alignment,
      child: Padding(
        padding: CameraOrientationUtils.isOnPortraitMode(orientation.value)
            ? EdgeInsets.symmetric(horizontal: 35.0, vertical: 140)
            : EdgeInsets.symmetric(vertical: 65.0),
        child: Transform.rotate(
          angle: CameraOrientationUtils.convertOrientationToRadian(
            orientation.value,
          ),
          child: Transform(
            alignment: Alignment.center,
            transform: Matrix4.rotationY(mirror ? pi : 0.0),
            child: Dismissible(
              onDismissed: (direction) {},
              key: UniqueKey(),
              child: SlideTransition(
                position: previewAnimation,
                child: _buildPreviewPicture(reverseImage: mirror),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildPreviewPicture({bool reverseImage = false}) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.all(
          Radius.circular(15),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black45,
            offset: Offset(2, 2),
            blurRadius: 25,
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(3.0),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(13.0),
          child: lastPhotoPath != null
              ? Transform(
                  alignment: Alignment.center,
                  transform: Matrix4.rotationY(reverseImage ? pi : 0.0),
                  child: Image.file(
                    File(lastPhotoPath!),
                    width: CameraOrientationUtils.isOnPortraitMode(orientation.value) ? 128 : 256,
                  ),
                )
              : Container(
                  width: CameraOrientationUtils.isOnPortraitMode(orientation.value) ? 128 : 256,
                  height: 228,
                  decoration: const BoxDecoration(
                    color: Colors.black38,
                  ),
                  child: const Center(
                    child: Icon(
                      Icons.photo,
                      color: Colors.white,
                    ),
                  ),
                ),
        ),
      ),
    );
  }
}

class TopBarWidget extends StatelessWidget {
  final bool isFullscreen;
  final bool isRecording;
  final ValueNotifier<Size> photoSize;
  final AnimationController rotationController;
  final ValueNotifier<CameraOrientations> orientation;
  final ValueNotifier<CaptureModes> captureMode;
  final ValueNotifier<bool> enableAudio;
  final ValueNotifier<CameraFlashes> switchFlash;
  final Function onFullscreenTap;
  final Function onResolutionTap;
  final Function onChangeSensorTap;
  final Function onFlashTap;
  final Function onAudioChange;

  const TopBarWidget({
    Key? key,
    required this.isFullscreen,
    required this.isRecording,
    required this.captureMode,
    required this.enableAudio,
    required this.photoSize,
    required this.orientation,
    required this.rotationController,
    required this.switchFlash,
    required this.onFullscreenTap,
    required this.onAudioChange,
    required this.onFlashTap,
    required this.onChangeSensorTap,
    required this.onResolutionTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 16),
      child: Column(
        children: <Widget>[
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: <Widget>[
              Padding(
                padding: const EdgeInsets.only(right: 24.0),
                child: Opacity(
                  opacity: isRecording ? 0.3 : 1.0,
                  child: IconButton(
                    icon: Icon(
                      isFullscreen ? Icons.fullscreen_exit : Icons.fullscreen,
                      color: Colors.white,
                    ),
                    onPressed: isRecording ? null : () => onFullscreenTap?.call(),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.only(right: 24),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: <Widget>[
                    IgnorePointer(
                      ignoring: isRecording,
                      child: Opacity(
                        opacity: isRecording ? 0.3 : 1.0,
                        child: ValueListenableBuilder(
                          valueListenable: photoSize,
                          builder: (context, value, child) => TextButton(
                            key: ValueKey("resolutionButton"),
                            onPressed: () {
                              HapticFeedback.selectionClick();

                              onResolutionTap?.call();
                            },
                            child: Text(
                              '${value?.width?.toInt()} / ${value?.height?.toInt()}',
                              key: ValueKey("resolutionTxt"),
                              style: TextStyle(color: Colors.white),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              OptionButton(
                icon: Icons.switch_camera,
                rotationController: rotationController,
                orientation: orientation,
                onTapCallback: () => onChangeSensorTap?.call(),
              ),
              SizedBox(width: 20.0),
              OptionButton(
                rotationController: rotationController,
                icon: _getFlashIcon(),
                orientation: orientation,
                onTapCallback: () => onFlashTap?.call(),
              ),
            ],
          ),
          SizedBox(height: 20.0),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              captureMode.value == CaptureModes.VIDEO
                  ? OptionButton(
                      icon: enableAudio.value ? Icons.mic : Icons.mic_off,
                      rotationController: rotationController,
                      orientation: orientation,
                      isEnabled: !isRecording,
                      onTapCallback: () => onAudioChange?.call(),
                    )
                  : Container(),
            ],
          ),
        ],
      ),
    );
  }

  IconData _getFlashIcon() {
    switch (switchFlash.value) {
      case CameraFlashes.NONE:
        return Icons.flash_off;
      case CameraFlashes.ON:
        return Icons.flash_on;
      case CameraFlashes.AUTO:
        return Icons.flash_auto;
      case CameraFlashes.ALWAYS:
        return Icons.highlight;
      default:
        return Icons.flash_off;
    }
  }
}

class BottomBarWidget extends StatelessWidget {
  final AnimationController rotationController;
  final ValueNotifier<CameraOrientations> orientation;
  final ValueNotifier<CaptureModes> captureMode;
  final bool isRecording;
  final Function onZoomInTap;
  final Function onZoomOutTap;
  final Function onCaptureTap;
  final Function onCaptureModeSwitchChange;

  const BottomBarWidget({
    Key? key,
    required this.rotationController,
    required this.orientation,
    required this.isRecording,
    required this.captureMode,
    required this.onZoomOutTap,
    required this.onZoomInTap,
    required this.onCaptureTap,
    required this.onCaptureModeSwitchChange,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Positioned(
      bottom: 0,
      left: 0,
      right: 0,
      child: SizedBox(
        height: 200,
        child: Stack(
          children: [
            // Footer's controls panel
            Container(
              color: Colors.black12,
            ),
            Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: <Widget>[
                    OptionButton(
                      icon: Icons.zoom_out,
                      rotationController: rotationController,
                      orientation: orientation,
                      onTapCallback: () => onZoomOutTap?.call(),
                    ),
                    CameraButton(
                      key: const ValueKey('cameraButton'),
                      captureMode: captureMode.value,
                      isRecording: isRecording,
                      onTap: () => onCaptureTap?.call(),
                    ),
                    OptionButton(
                      icon: Icons.zoom_in,
                      rotationController: rotationController,
                      orientation: orientation,
                      onTapCallback: () => onZoomInTap?.call(),
                    ),
                  ],
                ),
                const SizedBox(height: 10.0),
                Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                  OptionButton(
                    icon: Icons.woman,
                    rotationController: rotationController,
                    orientation: orientation,
                    onTapCallback: () {
                      //HttpService.proofOfLife();
                      final progress = ProgressHUD.of(context);
                      progress?.showWithText('Loading...');
                      Future classifier = HttpService.classifyWoman();
                      classifier.then((response) {
                        print(response.statusCode);
                        response.stream.transform(utf8.decoder).listen((value) {
                          print(value);
                          Map<String, dynamic> genderJson = json.decode(value);
                          progress?.dismiss();
                          // Navigate to screen, which will display the classification result.
                          Navigator.push(
                            context,
                            MaterialPageRoute(builder: (context) => ResultScreen(gender: genderJson['gender'])),
                          );
                        });
                      });
                    },
                  ),
                  SizedBox(width: 20,),
                  OptionButton(
                    icon: Icons.account_circle_outlined,
                    rotationController: rotationController,
                    orientation: orientation,
                    onTapCallback: () {
                      if (ApplicationService.file != null) {
                        //HttpService.proofOfLife();
                        final progress = ProgressHUD.of(context);
                        progress?.showWithText('Loading...');
                        Future classifier = HttpService.classify(ApplicationService.file!);
                        classifier.then((response) {
                          print(response.statusCode);
                          response.stream.transform(utf8.decoder).listen((value) {
                            print(value);
                            Map<String, dynamic> genderJson = json.decode(value);
                            progress?.dismiss();
                            // Navigate to screen, which will display the classification result.
                            Navigator.push(
                              context,
                              MaterialPageRoute(builder: (context) => ResultScreen(gender: genderJson['gender'])),
                            );
                          });
                        });
                      } else {
                        final snackBar = SnackBar(
                          content: const Text('Did you take a photograph?'),
                          backgroundColor: (Colors.black12),
                          action: SnackBarAction(
                            label: 'dismiss',
                            onPressed: () {},
                          ),
                        );
                        ScaffoldMessenger.of(context).showSnackBar(snackBar);
                      }
                    },
                  ),
                  SizedBox(width: 20,),
                  OptionButton(
                    icon: Icons.man,
                    rotationController: rotationController,
                    orientation: orientation,
                    onTapCallback: () {
                      //HttpService.proofOfLife();
                      final progress = ProgressHUD.of(context);
                      progress?.showWithText('Loading...');
                      Future classifier = HttpService.classifyMan();
                      classifier.then((response) {
                        print(response.statusCode);
                        response.stream.transform(utf8.decoder).listen((value) {
                          print(value);
                          Map<String, dynamic> genderJson = json.decode(value);
                          progress?.dismiss();
                          // Navigate to screen, which will display the classification result.
                          Navigator.push(
                            context,
                            MaterialPageRoute(builder: (context) => ResultScreen(gender: genderJson['gender'])),
                          );
                        });
                      });
                    },
                  ),
                ]),
                // Row(
                //   mainAxisAlignment: MainAxisAlignment.center,
                //   children: [
                //     Icon(
                //       Icons.photo_camera,
                //       color: Colors.white,
                //     ),
                //     Switch(
                //       key: ValueKey('captureModeSwitch'),
                //       value: (captureMode.value == CaptureModes.VIDEO),
                //       activeColor: Color(0xFF4F6AFF),
                //       onChanged: !isRecording
                //           ? (value) {
                //         HapticFeedback.heavyImpact();
                //         onCaptureModeSwitchChange?.call();
                //       }
                //           : null,
                //     ),
                //     Icon(
                //       Icons.videocam,
                //       color: Colors.white,
                //     ),
                //   ],
                // ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class CameraPreview extends StatefulWidget {
  final String videoPath;

  CameraPreview({
    Key? key,
    required this.videoPath,
  }) : super(key: key);

  @override
  _CameraPreviewState createState() => _CameraPreviewState();
}

class _CameraPreviewState extends State<CameraPreview> {
  VideoPlayerController? _videoPlayerController;

  @override
  void initState() {
    super.initState();
    _videoPlayerController = VideoPlayerController.file(File(widget.videoPath))
      ..initialize().then((_) {
        setState(() {});
        _videoPlayerController!.play();
      });
  }

  @override
  void dispose() {
    _videoPlayerController!.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Video preview'),
      ),
      body: Center(
        child: _videoPlayerController!.value.isInitialized
            ? AspectRatio(
                aspectRatio: _videoPlayerController!.value.aspectRatio,
                child: VideoPlayer(_videoPlayerController!),
              )
            : Container(),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          setState(() {
            _videoPlayerController!.value.isPlaying ? _videoPlayerController!.pause() : _videoPlayerController!.play();
          });
        },
        child: Icon(
          _videoPlayerController!.value.isPlaying ? Icons.pause : Icons.play_arrow,
        ),
      ),
    );
  }
}

class OptionButton extends StatefulWidget {
  final IconData? icon;
  final Function? onTapCallback;
  final AnimationController? rotationController;
  final ValueNotifier<CameraOrientations>? orientation;
  final bool isEnabled;
  const OptionButton({
    Key? key,
    this.icon,
    this.onTapCallback,
    this.rotationController,
    this.orientation,
    this.isEnabled = true,
  }) : super(key: key);

  @override
  _OptionButtonState createState() => _OptionButtonState();
}

class _OptionButtonState extends State<OptionButton> with SingleTickerProviderStateMixin {
  double _angle = 0.0;
  CameraOrientations _oldOrientation = CameraOrientations.PORTRAIT_UP;

  @override
  void initState() {
    super.initState();

    Tween(begin: 0.0, end: 1.0).chain(CurveTween(curve: Curves.ease)).animate(widget.rotationController!).addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        _oldOrientation = CameraOrientationUtils.convertRadianToOrientation(_angle);
      }
    });

    widget.orientation!.addListener(() {
      _angle = CameraOrientationUtils.convertOrientationToRadian(widget.orientation!.value);

      if (widget.orientation!.value == CameraOrientations.PORTRAIT_UP) {
        widget.rotationController!.reverse();
      } else if (_oldOrientation == CameraOrientations.LANDSCAPE_LEFT || _oldOrientation == CameraOrientations.LANDSCAPE_RIGHT) {
        widget.rotationController!.reset();

        if ((widget.orientation!.value == CameraOrientations.LANDSCAPE_LEFT || widget.orientation!.value == CameraOrientations.LANDSCAPE_RIGHT)) {
          widget.rotationController!.forward();
        } else if ((widget.orientation!.value == CameraOrientations.PORTRAIT_DOWN)) {
          if (_oldOrientation == CameraOrientations.LANDSCAPE_RIGHT) {
            widget.rotationController!.forward(from: 0.5);
          } else {
            widget.rotationController!.reverse(from: 0.5);
          }
        }
      } else if (widget.orientation!.value == CameraOrientations.PORTRAIT_DOWN) {
        widget.rotationController!.reverse(from: 0.5);
      } else {
        widget.rotationController!.forward();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: widget.rotationController!,
      builder: (context, child) {
        double? newAngle;

        if (_oldOrientation == CameraOrientations.LANDSCAPE_LEFT) {
          if (widget.orientation!.value == CameraOrientations.PORTRAIT_UP) {
            newAngle = -widget.rotationController!.value;
          }
        }

        if (_oldOrientation == CameraOrientations.LANDSCAPE_RIGHT) {
          if (widget.orientation!.value == CameraOrientations.PORTRAIT_UP) {
            newAngle = widget.rotationController!.value;
          }
        }

        if (_oldOrientation == CameraOrientations.PORTRAIT_DOWN) {
          if (widget.orientation!.value == CameraOrientations.PORTRAIT_UP) {
            newAngle = widget.rotationController!.value * -pi;
          }
        }

        return IgnorePointer(
          ignoring: !widget.isEnabled,
          child: Opacity(
            opacity: widget.isEnabled ? 1.0 : 0.3,
            child: Transform.rotate(
              angle: newAngle ?? widget.rotationController!.value * _angle,
              child: ClipOval(
                child: Material(
                  color: Theme.of(context).primaryColor,
                  child: InkWell(
                    child: SizedBox(
                      width: 48,
                      height: 48,
                      child: Icon(
                        widget.icon,
                        color: Colors.white,
                        size: 24.0,
                      ),
                    ),
                    onTap: () {
                      if (widget.onTapCallback != null) {
                        // Trigger short vibration
                        HapticFeedback.selectionClick();
                        widget.onTapCallback!();
                      }
                    },
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

class CameraButton extends StatefulWidget {
  final CaptureModes? captureMode;
  final bool? isRecording;
  final Function? onTap;

  CameraButton({
    Key? key,
    this.captureMode,
    this.isRecording,
    this.onTap,
  }) : super(key: key);

  @override
  _CameraButtonState createState() => _CameraButtonState();
}

class _CameraButtonState extends State<CameraButton> with SingleTickerProviderStateMixin {
  AnimationController? _animationController;
  double? _scale;
  Duration _duration = Duration(milliseconds: 100);

  @override
  void initState() {
    super.initState();

    _animationController = AnimationController(
      vsync: this,
      duration: _duration,
      lowerBound: 0.0,
      upperBound: 0.1,
    )..addListener(() {
        setState(() {});
      });
  }

  @override
  void dispose() {
    _animationController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    _scale = 1 - _animationController!.value;

    return GestureDetector(
      onTapDown: _onTapDown,
      onTapUp: _onTapUp,
      onTapCancel: _onTapCancel,
      child: Container(
        key: ValueKey('cameraButton' + (widget.captureMode == CaptureModes.PHOTO ? 'Photo' : 'Video')),
        height: 80,
        width: 80,
        child: Transform.scale(
          scale: _scale,
          child: CustomPaint(
            painter: CameraButtonPainter(
              widget.captureMode ?? CaptureModes.PHOTO,
              isRecording: widget.isRecording!,
            ),
          ),
        ),
      ),
    );
  }

  _onTapDown(TapDownDetails details) {
    _animationController!.forward();
  }

  _onTapUp(TapUpDetails details) {
    Future.delayed(_duration, () {
      _animationController!.reverse();
    });

    this.widget.onTap?.call();
  }

  _onTapCancel() {
    _animationController!.reverse();
  }
}

class CameraButtonPainter extends CustomPainter {
  final CaptureModes captureMode;
  final bool isRecording;

  CameraButtonPainter(
    this.captureMode, {
    this.isRecording = false,
  });

  @override
  void paint(Canvas canvas, Size size) {
    var bgPainter = Paint()
      ..style = PaintingStyle.fill
      ..isAntiAlias = true;
    var radius = size.width / 2;
    var center = Offset(size.width / 2, size.height / 2);
    bgPainter.color = Colors.white.withOpacity(.5);
    canvas.drawCircle(center, radius, bgPainter);

    if (this.captureMode == CaptureModes.VIDEO && this.isRecording) {
      bgPainter.color = Colors.red;
      canvas.drawRRect(
          RRect.fromRectAndRadius(
              Rect.fromLTWH(
                17,
                17,
                size.width - (17 * 2),
                size.height - (17 * 2),
              ),
              Radius.circular(12.0)),
          bgPainter);
    } else {
      bgPainter.color = captureMode == CaptureModes.PHOTO ? Colors.white : Colors.red;
      canvas.drawCircle(center, radius - 8, bgPainter);
    }
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) => false;
}
