import 'dart:io';
import 'dart:async';
import 'dart:convert';
import 'dart:collection';

class EngineProcess {
  Process? _process;
  StreamSubscription? _stdoutSub;

  // 受信した行をキューに積み、待っているCompleterに順番に渡す
  final Queue<String> _buffer = Queue();
  final Queue<Completer<String>> _waiters = Queue();

  Future<void> start(String path) async {
    _process = await Process.start(path, []);
    _stdoutSub = _process!.stdout
        .transform(utf8.decoder)
        .transform(const LineSplitter())
        .listen((line) {
      final trimmed = line.trim();
      if (trimmed.isEmpty) return;

      if (_waiters.isNotEmpty) {
        _waiters.removeFirst().complete(trimmed);
      } else {
        _buffer.addLast(trimmed);
      }
    });
  }

  // 次の1行を受け取るFutureを返す
  Future<String> _readLine(Duration timeout) {
    if (_buffer.isNotEmpty) {
      return Future.value(_buffer.removeFirst());
    }
    final completer = Completer<String>();
    _waiters.addLast(completer);
    return completer.future.timeout(timeout, onTimeout: () {
      _waiters.remove(completer);
      throw TimeoutException('Engine response timeout');
    });
  }

  Future<String?> getName() async {
    _send('name');
    try {
      return await _readLine(const Duration(seconds: 2));
    } catch (_) {
      return null;
    }
  }

  void sendRule(String color, int timePerMove, int increment) {
    _send('rule color $color time_per_move $timePerMove increment $increment');
  }

  Future<String> sendPosition(String board, String color, int timeMs) {
    _send('position $board $color $timeMs');
    return _readLine(Duration(milliseconds: timeMs + 2000));
  }

  void _send(String command) {
    _process?.stdin.writeln(command);
  }

  Future<void> quit() async {
    _send('quit');
    await _stdoutSub?.cancel();
    _process?.kill();
  }
}
