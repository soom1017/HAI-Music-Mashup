import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:mashuptemp/screens/components/uploadpage.dart';
import 'package:mashuptemp/screens/components/mypage.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return const MaterialApp(title: 'Flutter Demo', home: MyHomePage());
  }
}

class MyHomePage extends StatelessWidget {
  const MyHomePage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('mashup temp'),
          bottom: const TabBar(
            tabs: <Widget>[
              Tab(icon: Icon(Icons.add_outlined)),
              Tab(icon: Icon(Icons.my_library_music_outlined)),
            ],
          ),
        ),
        body: TabBarView(
          children: <Widget>[
            UploadPage(),
            MyPage(),
          ],
        ),
      ),
    );
  }
}
