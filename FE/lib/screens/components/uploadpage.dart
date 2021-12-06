import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:mashuptemp/models/audio.dart';
import 'processpage.dart';

class UploadPage extends StatefulWidget {
  @override
  State<UploadPage> createState() => _UploadPageState();
}

class _UploadPageState extends State<UploadPage> {
  String uploadUrl = "http://52.78.193.78:5000/uploadFile";
  String inferenceUrl = "http://52.78.193.78:5000/inference";
  int card_count = 0;
  List<Widget> _cardList = [];

  late String audio1, audio2;
  List<Audio> audios = [];

  late String s3Url;

  bool isLoading = false;

  Future<String> uploadFile(filename, url) async {
    var request = http.MultipartRequest("POST", Uri.parse(url));
    request.files.add(await http.MultipartFile.fromPath('file', filename));

    var response = await request.send();
    return response.statusCode.toString();
  }

  void _addCardWidget(String audio) {
    setState(() {
      _cardList.add(_card(audio));
      card_count++;
    });
  }

  Widget _card(String audioname) {
    return Container(
      margin: EdgeInsets.only(top: 5),
      padding: EdgeInsets.only(top: 15),
      decoration: new BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        color: Colors.blueGrey[50],
      ),
      height: 50,
      width: double.infinity,
      child: Text(
        audioname,
        textAlign: TextAlign.center,
      ),
    );
  }

  Widget _empty_card() {
    return Container(
      margin: EdgeInsets.only(top: 5),
      padding: EdgeInsets.only(top: 15),
      decoration: new BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.black, style: BorderStyle.solid),
      ),
      height: 50,
      width: double.infinity,
      child: Text(
        'Please Upload Your Audio File (.wav)',
        textAlign: TextAlign.center,
      ),
    );
  }

  Widget _audio_text(int index) {
    return Container(
      height: 30,
      width: double.infinity,
      padding: EdgeInsets.only(top: 10, left: 5),
      child: Text('Audio ' + index.toString()),
    );
  }

  Widget _upload_btn() {
    return Container(
        margin: EdgeInsets.only(top: 20),
        alignment: Alignment.topRight,
        child: OutlinedButton(
          onPressed: () async {
            FilePickerResult? result = await FilePicker.platform.pickFiles(
              type: FileType.custom,
              allowedExtensions: ['wav'],
            );

            String res = '';
            if (result != null) {
              File file = File(result.files.first.path!);
              res = await uploadFile(file.path, uploadUrl);
              if (res == '200') {
                if (card_count == 0) {
                  audio1 = file.path.split('/').last;
                } else {
                  audio2 = file.path.split('/').last;
                }
                _addCardWidget(file.path.split('/').last);
              }
            } else {
              print(res); /* if there's bug, fix it before production level */
            }
          },
          child: const Text('Upload'),
        ));
  }

  _inference() async {
    int status = 0;
    var response;

    isLoading = true;
    while (status != 200) {
      response = await http.get(Uri.parse(inferenceUrl));
      status = response.statusCode;
    }
    Map<String, dynamic> audioInfo = jsonDecode(response.body);
    isLoading = false;

    audios.add(
        new Audio(audio1, audioInfo['first_beat1'], audioInfo['num_beat']));
    audios.add(
        new Audio(audio2, audioInfo['first_beat2'], audioInfo['num_beat']));
    s3Url = audioInfo['s3_url'].toString();

    Navigator.push(
        context,
        MaterialPageRoute(
            builder: (context) => ProcessPage(
                  audios: audios,
                  s3Url: s3Url,
                )));
  }

  Widget _start_btn() {
    return Container(
        margin: EdgeInsets.only(top: 20),
        alignment: Alignment.topRight,
        child: OutlinedButton(
          onPressed: () {
            _inference();
          },
          child: const Text('Start Processing'),
        ));
  }

  /* For testing: Send request -> Get json -> Decode json */
  Widget _test_btn() {
    return TextButton(
      onPressed: () {
        _testFunc();
      },
      child: Text('test'),
    );
  }

  _testFunc() async {
    var response = await http.get(Uri.parse(inferenceUrl));
    print(response.body);
    Map<String, dynamic> res = jsonDecode(response.body);
    print("id = " + res['id'].toString());
  }
  /* Test ends */

  Widget _progressIndicator() {
    if (isLoading == true) {
      return CircularProgressIndicator(
        semanticsLabel: "Processing beat, key",
      );
    }
    return Text('');
  }

  Widget build(BuildContext context) {
    SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
    if (card_count >= 2) {
      return Scaffold(
        body: SingleChildScrollView(
          child: Column(
            children: [
              _audio_text(1),
              _cardList[0],
              _audio_text(2),
              _cardList[1],
              _start_btn(),
              _progressIndicator(),
            ],
          ),
        ),
      );
    } else if (card_count == 1) {
      return Scaffold(
        body: SingleChildScrollView(
          child: Column(
            children: [
              _audio_text(1),
              _cardList[0],
              _audio_text(2),
              _empty_card(),
              _upload_btn(),
            ],
          ),
        ),
      );
    }
    return Scaffold(
      body: SingleChildScrollView(
        child: Column(
          children: [
            _audio_text(1),
            _empty_card(),
            _audio_text(2),
            _empty_card(),
            _upload_btn(),
          ],
        ),
      ),
    );
  }
}
