import 'dart:io';

class Audio {
  late String name;

  late double first_beat;
  late int num_beat;

  int num_stem = 3;
  List<String> stems = ['vocal', 'drum', 'etc'];

  Audio(String name, double first_beat, int num_beat) {
    this.name = name;
    this.first_beat = first_beat;
    this.num_beat = num_beat;
  }
}
