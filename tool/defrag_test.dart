import 'dart:io';
import 'package:music_player/source/mp4_defrag.dart';

void main(List<String> args) {
  final input = File(args[0]).readAsBytesSync();
  final out = defragmentMp4(input);
  if (out == null) {
    stderr.writeln('Not fragmented');
    exit(2);
  }
  File(args[1]).writeAsBytesSync(out);
  stdout.writeln('in ${input.length} bytes -> out ${out.length} bytes');
}
