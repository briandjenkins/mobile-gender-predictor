import 'dart:convert';
import 'dart:io' as io;
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'package:http/http.dart';
import 'package:http_parser/http_parser.dart';


class HttpService {
  static String remoteUrl = 'https://gender-classifier-rest-service.herokuapp.com';
  static String localUrl = 'http://localhost:8080';
  static String emulatorUrl = 'http://10.0.2.2:8080';
  static String activeUrl = remoteUrl;

  static void classifyTest() {
    print('blah blah');
  }

  static Future<String> proofOfLife() async {
    String url = '$activeUrl/';
    Map<String, String> headers = {"Content-type": "application/json"};
    final response = await http.get(Uri.parse(url), headers: headers);
    if (response.statusCode == 200) {
      // If the server did return a 200 OK response,
      // then parse the JSON.
      return response.body;
    } else {
      // If the server did not return a 200 OK response,
      // then throw an exception.
      throw Exception('Failed to load album');
    }
  }

  static Future classifyWoman() async {
    String url = '$activeUrl/upload/image';
    var uri = Uri.parse(url);
    var request = http.MultipartRequest("POST", uri);
    // Tests to determine if the image in the resource directory will be correctly classified.
    var picture = http.MultipartFile.fromBytes('image', (await rootBundle.load('assets/images/131422.jpg')).buffer.asUint8List(), filename: 'testimage.png');
    request.files.add(picture);
    var response = await request.send();
    return response;
  }

  static Future classifyMan() async {
    String url = '$activeUrl/upload/image';
    var uri = Uri.parse(url);
    var request = http.MultipartRequest("POST", uri);
    // Tests to determine if the image in the resource directory will be correctly classified.
    var picture = http.MultipartFile.fromBytes('image', (await rootBundle.load('assets/images/bdj.jpg')).buffer.asUint8List(), filename: 'testimage.png');
    request.files.add(picture);
    var response = await request.send();
    return response;
  }

  static Future classify(io.File image) async {
    String url = '$activeUrl/upload/image';
    var uri = Uri.parse(url);
    var request = http.MultipartRequest("POST", uri);
    // Tests to determine if the image in the resource directory will be correctly classified.
    //MultipartFile picture = http.MultipartFile.fromBytes('image', (await rootBundle.load('assets/images/131422.jpg')).buffer.asUint8List(), filename: 'testimage.png');
    //request.files.add(picture);
    request.files.add(http.MultipartFile.fromBytes('image', image.readAsBytesSync(), contentType: MediaType.parse('multipart/form-data'),  filename: "Photo.jpg"));
    //
    var response = await request.send();
    return response;
  }
}
