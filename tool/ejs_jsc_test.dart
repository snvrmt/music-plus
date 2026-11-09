// Checks that YouTube's puzzle solver (EJS) runs in Apple's JavaScriptCore,
// the engine the iPhone app uses. Run on a macOS runner.
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:youtube_explode_dart/js_challenge.dart';

Future<void> main() async {
  final modules = await EJSBuilder.getJSModules();
  stdout.writeln('modules: ${modules.length} chars');
  final iframe = await http.get(Uri.parse('https://www.youtube.com/iframe_api'));
  final m = RegExp(r'player\\?/([0-9a-zA-Z_-]+)\\?/').firstMatch(iframe.body);
  if (m == null) {
    stdout.writeln('could not find player id');
    exit(1);
  }
  final playerUrl = 'https://www.youtube.com/s/player/${m.group(1)}/player_ias.vflset/en_US/base.js';
  final player = (await http.get(Uri.parse(playerUrl))).body;
  stdout.writeln('player $playerUrl: ${player.length} chars');
  final call = EJSBuilder.buildJSCall(player, {
    JSChallengeType.n: ['ZdZIqFPQK-Ty8wId', 'aHBfXtKrDpVhNqQ0'],
  });
  File('ejs_test.js').writeAsStringSync('$modules\nprint($call);\n');
  File('ejs_test_node.js').writeAsStringSync('globalThis.print = console.log;\n$modules\nprint($call);\n');
}
