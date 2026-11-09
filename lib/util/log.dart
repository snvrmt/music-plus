import 'package:flutter/foundation.dart';

/// In-app diagnostics log (Home > account menu > Diagnostics).
class Log {
  static final ValueNotifier<List<String>> lines = ValueNotifier(const []);
  static final _start = DateTime.now();

  static void add(String msg) {
    final t = DateTime.now().difference(_start);
    final stamp = '${t.inMinutes}:${(t.inSeconds % 60).toString().padLeft(2, '0')}'
        '.${(t.inMilliseconds % 1000).toString().padLeft(3, '0')}';
    final line = '$stamp  $msg';
    debugPrint(line);
    final next = [...lines.value, line];
    lines.value = next.length > 400 ? next.sublist(next.length - 400) : next;
  }
}
