import 'dart:io';
import 'dart:async';
import 'dart:convert';

class EngineProcess {
  Process? _process;
  final _responseController = StreamController<String>.broadcast();
  StreamSubscription? _stdoutSub;

  Future<void> start(String path) async {
    _process = await Process.start(path, []);
    _stdoutSub = _process!.stdout
        .transform(utf8.decoder)
        .transform(const LineSplitter())
        .listen((line) {
      if (line.trim().isNotEmpty) {
        _responseController.add(line.trim());
      }
    });
  }

  Future<String?> getName() async {
    _send('name');
    try {
      return await _responseController.stream.first
          .timeout(const Duration(seconds: 2));
    } catch (_) {
      return null;
    }
  }

  void sendRule(String color, int timePerMove, int increment) {
    _send('rule color $color time_per_move $timePerMove increment $increment');
  }

  Future<String> sendPosition(String board, String color, int timeMs) {
    _send('position $board $color $timeMs');
    return _responseController.stream.first
        .timeout(Duration(milliseconds: timeMs + 2000));
  }

  void _send(String command) {
    _process?.stdin.writeln(command);
  }

  Future<void> quit() async {
    _send('quit');
    await _stdoutSub?.cancel();
    await _responseController.close();
    _process?.kill();
  }
}
