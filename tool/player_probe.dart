// Prints YouTube's raw playability status for a few InnerTube clients.
import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;

Future<void> main(List<String> args) async {
  final id = args.isEmpty ? 'Rgrt_8mXrK8' : args.first;
  final clients = {
    'IOS': {'clientName': 'IOS', 'clientVersion': '20.10.4', 'deviceModel': 'iPhone16,2', 'osName': 'iPhone', 'osVersion': '18.3.2.22D82'},
    'ANDROID_VR': {'clientName': 'ANDROID_VR', 'clientVersion': '1.62.27', 'androidSdkVersion': 32},
    'WEB_REMIX': {'clientName': 'WEB_REMIX', 'clientVersion': '1.20241106.01.00'},
    'TVHTML5': {'clientName': 'TVHTML5', 'clientVersion': '7.20250120.19.00'},
  };
  for (final e in clients.entries) {
    final res = await http.post(
      Uri.parse('https://www.youtube.com/youtubei/v1/player?prettyPrint=false'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'context': {'client': {...e.value, 'hl': 'en', 'gl': 'US'}}, 'videoId': id}),
    );
    try {
      final j = jsonDecode(res.body) as Map;
      final ps = j['playabilityStatus'] as Map?;
      final fmts = ((j['streamingData'] as Map?)?['adaptiveFormats'] as List?)?.length;
      stdout.writeln('${e.key}: http=${res.statusCode} status=${ps?['status']} reason=${ps?['reason']} formats=$fmts');
    } catch (err) {
      stdout.writeln('${e.key}: http=${res.statusCode} parse error');
    }
  }
}
