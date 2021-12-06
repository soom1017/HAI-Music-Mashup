import 'dart:async';

import 'package:audioplayers/audioplayers.dart';
import 'package:mashuptemp/screens/components/processpage.dart';
import 'package:mashuptemp/models/audio.dart';

class AudioStream {
  late String s3Url;

  String audio1 = "";
  String audio2 = "";

  int num_stem1 = 0;
  int num_stem2 = 0;
  int num_beat1 = 0;
  int num_beat2 = 0;

  double first_beat1 = 0;
  double first_beat2 = 0;

  List<AudioPlayer> beatPlayers = []; /* for playing certain beat */
  late int cur_beat;
  late Measure cur_msr;

  late List<Measure> cur_msrs;

  late Duration duration1;
  late Duration duration2;

  List<Duration> positions = [];

  late StreamSubscription<Duration> _listener1;
  late StreamSubscription<Duration> _listener2;

  bool paused = false;

  void setPlayer(List<Audio> audios, String s3Url) async {
    num_stem1 = audios[0].num_stem;
    num_stem2 = audios[1].num_stem;
    num_beat1 = audios[0].num_beat;
    num_beat2 = audios[1].num_beat;
    first_beat1 = audios[0].first_beat;
    first_beat2 = audios[1].first_beat;

    this.s3Url = s3Url;

    for (int i = 0; i < num_stem1 + num_stem2; i++) {
      beatPlayers.add(AudioPlayer());
      beatPlayers[i].setReleaseMode(ReleaseMode.STOP);

      positions.add(Duration());
    }

    List<String> temp1 = audios[0].name.split('.');
    audio1 = temp1[0];

    List<String> temp2 = audios[1].name.split('.');
    audio2 = temp2[0];

    for (int i = 0; i < num_stem1; i++) {
      beatPlayers[i].setUrl(s3Url + audio1 + i.toString() + ".wav");
    }

    for (int i = 0; i < num_stem2; i++) {
      beatPlayers[num_stem1 + i].setUrl(s3Url + audio2 + i.toString() + ".wav");
    }
  }

  initAudio() {
    beatPlayers[0].onDurationChanged.listen((Duration d) {
      duration1 = d;
    });
    beatPlayers[num_stem1].onDurationChanged.listen((Duration d) {
      duration2 = d;
    });

    for (int i = 0; i < beatPlayers.length; i++) {
      beatPlayers[i].onAudioPositionChanged.listen((Duration p) {
        positions[i] = p;
      });
    }
  }

  play(int beat_no, List<Measure> msrs) {
    int dur1 = duration1.inMilliseconds;
    int dur2 = duration2.inMilliseconds;

    // cur_msrs = [];
    // for (int i = 0; i < msrs.length; i++) {
    //   cur_msrs.add(Measure.clone(msrs[i]));
    // }
    cur_msrs = msrs;
    Measure msr = cur_msrs[beat_no];

    // beatPlayers[stem1]: seek to beat_no
    if (msr.stem1 != -1) {
      beatPlayers[msr.stem1].seek(Duration(
          milliseconds: (dur1 / num_beat1).toInt() * beat_no +
              (first_beat1 * 1000).toInt()));
      beatPlayers[msr.stem1].resume();
    }

    // beatPlayers[num_stem1 + stem2]: seek to beat_no
    if (msr.stem2 != -1) {
      beatPlayers[num_stem1 + msr.stem2].seek(Duration(
          milliseconds: (dur2 / num_beat2).toInt() * beat_no +
              (first_beat2 * 1000).toInt()));
      beatPlayers[num_stem1 + msr.stem2].resume();
    }

    // for pause btn
    cur_beat = beat_no;
    cur_msr = Measure.clone(msr);

    // play just one beat, and pause
    switch (msr.status) {
      case 1:
        _listener1 =
            beatPlayers[msr.stem1].onAudioPositionChanged.listen((Duration p) {
          if (p.inMilliseconds ==
              (dur1 / num_beat1).toInt() * (beat_no + 1) +
                  (first_beat1 * 1000).toInt()) {
            paused = true;
            pause();
          }
        });
        break;

      case 2:
        _listener2 = beatPlayers[num_stem1 + msr.stem2]
            .onAudioPositionChanged
            .listen((Duration p) {
          if (p.inMilliseconds ==
              (dur2 / num_beat2).toInt() * (beat_no + 1) +
                  (first_beat2 * 1000).toInt()) {
            paused = true;
            pause();
          }
        });
        break;

      case 3:
        _listener1 =
            beatPlayers[msr.stem1].onAudioPositionChanged.listen((Duration p) {
          if (p.inMilliseconds ==
              (dur1 / num_beat1).toInt() * (beat_no + 1) +
                  (first_beat1 * 1000).toInt()) {
            paused = true;
            pause();
          }
        });
        _listener2 = beatPlayers[num_stem1 + msr.stem2]
            .onAudioPositionChanged
            .listen((Duration p) {
          if (p.inMilliseconds ==
              (dur2 / num_beat2).toInt() * (beat_no + 1) +
                  (first_beat2 * 1000).toInt()) {
            paused = true;
            pause();
          }
        });
        break;
      default:
        break;
    }
  }

  pause() {
    if (cur_msr.status != 0) {
      if (cur_msr.stem1 != -1) {
        beatPlayers[cur_msr.stem1].pause();
        _listener1.cancel();
      }
      if (cur_msr.stem2 != -1) {
        beatPlayers[num_stem1 + cur_msr.stem2].pause();
        _listener2.cancel();
      }

      if (paused == true) {
        paused = false;
        if (cur_beat < (cur_msrs.length - 1) &&
            cur_msrs[cur_beat + 1].status != 0) {
          play(cur_beat + 1, cur_msrs);
        }
      }
    }
  }

  exitStream() {
    for (int i = 0; i < num_stem1 + num_stem2; i++) {
      beatPlayers[i].release();
    }
  }
}
