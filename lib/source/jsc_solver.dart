import 'package:flutter_js/flutter_js.dart';
import 'package:youtube_explode_dart/js_challenge.dart';

/// Solves YouTube's JavaScript link puzzles with the phone's own
/// JavaScript engine (JavaScriptCore on iPhone). Without this YouTube only
/// serves the first megabyte of a song and then answers 403.
class JscSolver extends BaseEJSSolver {
  JscSolver._(this._rt);
  final JavascriptRuntime _rt;

  static Future<JscSolver> init() async {
    final modules = await EJSBuilder.getJSModules();
    final rt = getJavascriptRuntime();
    final r = rt.evaluate(modules);
    if (r.isError) throw Exception('Puzzle solver failed to load: ${r.stringResult}');
    return JscSolver._(rt);
  }

  @override
  Future<String> executeJavaScript(String jsCode) async {
    final r = _rt.evaluate(jsCode);
    if (r.isError) throw Exception('Puzzle solver error: ${r.stringResult}');
    return r.stringResult;
  }

  @override
  void dispose() => _rt.dispose();
}
