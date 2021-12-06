import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:r_dotted_line_border/r_dotted_line_border.dart';
import 'package:percent_indicator/percent_indicator.dart';

import 'package:mashuptemp/models/audio.dart';
import 'package:mashuptemp/main.dart';
import 'package:mashuptemp/utils/audio_stream.dart';

class ProcessPage extends StatefulWidget {
  const ProcessPage({Key? key, required this.audios, required this.s3Url})
      : super(key: key);
  final List<Audio> audios;
  final String s3Url;

  @override
  State<ProcessPage> createState() => _ProcessPageState(audios, s3Url);
}

class _ProcessPageState extends State<ProcessPage> {
  String s3Url = "";

  List<Audio> audios = [];
  AudioStream audioStream = AudioStream();

  int cur_act = -1;
  List<Measure> msrs = [];

  bool complete = false;

  _ProcessPageState(List<Audio> audios, String s3Url) {
    this.audios = audios;
    for (int i = 0; i < audios.first.num_beat; i++) {
      msrs.add(Measure());
    }
    this.s3Url = s3Url;

    audioStream.setPlayer(audios, s3Url);
  }

  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    audioStream.initAudio();
  }

  void setStem(int audio_idx, int stem_idx) {
    setState(() {
      if (audio_idx == 0) {
        msrs[cur_act].stem1 = stem_idx;
        if (msrs[cur_act].stem2 == -1) {
          msrs[cur_act].status = 1;
        } else {
          msrs[cur_act].status = 3;
          activateMsr(cur_act + 1);
        }
      } else {
        msrs[cur_act].stem2 = stem_idx;
        if (msrs[cur_act].stem1 == -1) {
          msrs[cur_act].status = 2;
        } else {
          msrs[cur_act].status = 3;
          activateMsr(cur_act + 1);
        }
      }
    });
  }

  Widget _stem_btns(int audio_idx) {
    return Container(
      width: 400,
      height: 30,
      child: ListView.builder(
          scrollDirection: Axis.horizontal,
          itemCount: audios[audio_idx].num_stem,
          itemBuilder: (BuildContext context, int index) {
            return Container(
              margin: EdgeInsets.only(right: 5),
              child: OutlinedButton(
                  onPressed: () {
                    if (cur_act != -1) setStem(audio_idx, index);
                  },
                  child: Text(
                    audios[audio_idx].stems[index],
                    style: TextStyle(
                        color: Colors.black, fontWeight: FontWeight.bold),
                  )),
            );
          }),
    );
  }

  String _truncatedName(int idx) {
    String result = audios[idx].name;
    if (audios[idx].name.length > 14) {
      List<String> strs = result.split('.');
      strs[0] = strs[0].substring(0, 8) + "... ";

      result = strs[0] + '.' + strs[1];
    }
    return result;
  }

  Widget _audio_header(int idx) {
    return Container(
      width: 540,
      height: 30,
      child: Row(
        children: [
          Spacer(),
          Text(
            _truncatedName(idx),
            textAlign: TextAlign.left,
          ),
          Container(width: 0.5),
          _stem_btns(idx),
        ],
      ),
    );
  }

  void activateMsr(int index) {
    setState(() {
      for (int i = 0; i < msrs.length; i++) {
        msrs[i].activated = false;
      }
      msrs[index].activated = true;
      cur_act = index;
    });
  }

  Widget _measure(int index, int status) {
    return Container(
      width: 150,
      height: 150,
      decoration: BoxDecoration(
          border: RDottedLineBorder(
              right: BorderSide(
        width: 2,
        color: Colors.white,
      ))),
      child: GestureDetector(
        child: Image.asset(
          'assets/images/IMG_' + status.toString() + '.PNG',
          fit: BoxFit.cover,
        ),
        onTap: () => activateMsr(index),
      ),
    );
  }

  Widget _track() {
    return Container(
        height: 200,
        width: 800,
        alignment: Alignment.centerLeft,
        child: ListView.builder(
            padding: EdgeInsets.only(left: 2),
            scrollDirection: Axis.horizontal,
            itemCount: audios.first.num_beat,
            itemBuilder: (BuildContext context, int index) {
              return _measure(index, msrs[index].getStatus());
            }));
  }

  double _progress() {
    double result = 0;

    int completed_msr = 0;
    for (Measure msr in msrs) {
      if (msr.status != 0) {
        completed_msr++;
      }
    }
    if (completed_msr != 0) {
      result = completed_msr / msrs.length;
    }

    if (result == 1) {
      setState(() {
        complete = true;
      });
    }
    return result;
  }

  void _FlutterDialog() {
    showDialog(
        context: context,
        barrierDismissible: true,
        builder: (BuildContext context) {
          return AlertDialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
            title: Text("Exit?"),
            content: Text("완성하지 않은 채로 나가면, 지금까지의 작업이 사라집니다."),
            actions: [
              TextButton(
                  onPressed: () => Navigator.pop(context), child: Text("No")),
              TextButton(
                  onPressed: () {
                    audioStream.exitStream();
                    Navigator.push(context,
                        MaterialPageRoute(builder: (context) => MyHomePage()));
                  },
                  child: Text("Yes")),
            ],
          );
        });
  }

  @override
  Widget build(BuildContext context) {
    SystemChrome.setPreferredOrientations([DeviceOrientation.landscapeLeft]);
    return Scaffold(
      backgroundColor: Colors.grey[200],
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Column(
                children: [
                  Container(height: 10),
                  _audio_header(0),
                  Container(height: 10),
                  _audio_header(1),
                ],
              ),
              Container(child: Text('전체 매시업 듣기')),
              IconButton(
                onPressed: () {
                  if (cur_act != -1 && msrs[cur_act].status != 0) {
                    audioStream.play(cur_act, msrs);
                  }
                },
                icon: Icon(
                  Icons.play_arrow,
                  size: 50,
                ),
                color: Colors.blue,
              ),
              IconButton(
                onPressed: () {
                  audioStream.pause();
                },
                icon: Icon(
                  Icons.pause,
                  size: 50,
                ),
                color: Colors.grey,
              ),
              IconButton(
                onPressed: () {},
                icon: Icon(
                  Icons.stop,
                  size: 50,
                ),
                color: Colors.red,
              ),
              Spacer()
            ],
          ),
          Container(height: 25),
          _track(),
          Container(height: 25),
          Center(
              child: LinearPercentIndicator(
            width: 800,
            lineHeight: 10,
            percent: _progress(),
            progressColor: Colors.blue,
          )),
          Container(
              margin: EdgeInsets.only(right: 5),
              alignment: Alignment.bottomRight,
              child: TextButton(
                onPressed: () {
                  if (complete == true) {
                    audioStream.exitStream();
                    Navigator.push(context,
                        MaterialPageRoute(builder: (context) => MyHomePage()));
                  } else {
                    _FlutterDialog();
                  }
                },
                child: const Text('exit'),
              )),
        ],
      ),
    );
  }
}

class Measure {
  bool activated = false;
  int status = 0;
  int stem1 = -1;
  int stem2 = -1;

  Measure() {}
  Measure.clone(Measure anotherMeasure) {
    this.activated = anotherMeasure.activated;
    this.status = anotherMeasure.status;
    this.stem1 = anotherMeasure.stem1;
    this.stem2 = anotherMeasure.stem2;
  }

  int getStatus() {
    if (this.activated == false) return status;
    return (4 + status);
  }
}
