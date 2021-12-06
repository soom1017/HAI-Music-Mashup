import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class MyPage extends StatefulWidget {
  @override
  State<MyPage> createState() => _MyPageState();
}

class _MyPageState extends State<MyPage> {
  String json = '''{
      "num_file": 3, 
      "urls": [
        "https://test-soomin-bucket.s3.ap-northeast-2.amazonaws.com/audios/mashupComp1.wav", 
        "https://test-soomin-bucket.s3.ap-northeast-2.amazonaws.com/audios/mashupComp2.wav",
        "https://test-soomin-bucket.s3.ap-northeast-2.amazonaws.com/audios/mashupComp3.wav"
      ]
    }''';

  Widget _card(int index, List<String> urls) {
    return Container(
        margin: EdgeInsets.only(top: 5, left: 8, right: 8),
        padding: EdgeInsets.only(top: 15),
        decoration: new BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          color: Colors.blueGrey[50],
        ),
        height: 50,
        child: Row(
          children: [
            Spacer(),
            Text(
              urls[index].split('/').last,
              textAlign: TextAlign.center,
            ),
            Spacer(),
            IconButton(
              icon: Icon(Icons.download),
              onPressed: () {},
            )
          ],
        ));
  }

  Widget build(BuildContext context) {
    SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);

    Map<String, dynamic> info = jsonDecode(json);
    List<String> urls = List.from(info['urls']);

    return Scaffold(
      body: Column(
        children: [
          Container(
            height: 20,
          ),
          Container(
            height: 40,
            width: double.infinity,
            child: Text(
              '   please download completed files',
              textAlign: TextAlign.left,
              style: TextStyle(
                fontSize: 16,
                // fontWeight: FontWeight.bold,
              ),
            ),
          ),
          Container(
            height: 600,
            width: double.infinity,
            child: info['num_file'] > 0
                ? ListView.builder(
                    itemCount: info['num_file'],
                    itemBuilder: (BuildContext context, int index) {
                      return _card(index, urls);
                    })
                : const Center(
                    child: Text('No items'),
                  ),
          )
        ],
      ),
    );
  }
}
