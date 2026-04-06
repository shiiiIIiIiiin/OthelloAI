import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import '../models/game_config.dart';
import 'game_screen.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  PlayerType _blackType = PlayerType.human;
  PlayerType _whiteType = PlayerType.engine;
  final _blackNameController = TextEditingController(text: '黒');
  final _whiteNameController = TextEditingController(text: '白');
  String _blackPath = '';
  String _whitePath = '';
  int _timePerMove = 5000;
  int _increment = 5000;

  @override
  void dispose() {
    _blackNameController.dispose();
    _whiteNameController.dispose();
    super.dispose();
  }

  Future<void> _pickEngine(bool isBlack) async {
    final result = await FilePicker.platform.pickFiles();
    if (result != null) {
      setState(() {
        if (isBlack) {
          _blackPath = result.files.single.path ?? '';
        } else {
          _whitePath = result.files.single.path ?? '';
        }
      });
    }
  }

  void _startGame() {
    if (_blackType == PlayerType.engine && _blackPath.isEmpty) return;
    if (_whiteType == PlayerType.engine && _whitePath.isEmpty) return;

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => GameScreen(
          config: GameConfig(
            blackPlayer: _blackType,
            whitePlayer: _whiteType,
            blackName: _blackNameController.text.isEmpty ? '黒' : _blackNameController.text,
            whiteName: _whiteNameController.text.isEmpty ? '白' : _whiteNameController.text,
            blackEnginePath: _blackPath,
            whiteEnginePath: _whitePath,
            timePerMove: _timePerMove,
            increment: _increment,
          ),
        ),
      ),
    );
  }

  Widget _playerSection(String label, bool isBlack) {
    final type = isBlack ? _blackType : _whiteType;
    final path = isBlack ? _blackPath : _whitePath;
    final nameController = isBlack ? _blackNameController : _whiteNameController;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label,
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Row(
              children: [
                Radio<PlayerType>(
                  value: PlayerType.human,
                  groupValue: type,
                  onChanged: (v) => setState(
                      () => isBlack ? _blackType = v! : _whiteType = v!),
                ),
                const Text('人間'),
                const SizedBox(width: 24),
                Radio<PlayerType>(
                  value: PlayerType.engine,
                  groupValue: type,
                  onChanged: (v) => setState(
                      () => isBlack ? _blackType = v! : _whiteType = v!),
                ),
                const Text('エンジン'),
              ],
            ),
            Row(
              children: [
                const SizedBox(width: 4),
                const Text('名前'),
                const SizedBox(width: 16),
                SizedBox(
                  width: 200,
                  child: TextField(
                    controller: nameController,
                    decoration: const InputDecoration(
                      isDense: true,
                      border: OutlineInputBorder(),
                    ),
                  ),
                ),
              ],
            ),
            if (type == PlayerType.engine) ...[
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: Text(
                      path.isEmpty ? '（未選択）' : path,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                          color: path.isEmpty ? Colors.red : Colors.black87),
                    ),
                  ),
                  TextButton(
                    onPressed: () => _pickEngine(isBlack),
                    child: const Text('選択'),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('OthelloAI - 対局設定'),
        backgroundColor: Colors.green.shade700,
        foregroundColor: Colors.white,
      ),
      body: Center(
        child: SizedBox(
          width: 500,
          child: ListView(
            padding: const EdgeInsets.all(24),
            children: [
              _playerSection('黒', true),
              const SizedBox(height: 12),
              _playerSection('白', false),
              const SizedBox(height: 12),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('時間設定',
                          style: TextStyle(
                              fontSize: 16, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 12),
                      _timeSetting('1手の持ち時間', _timePerMove,
                          (v) => _timePerMove = v),
                      const SizedBox(height: 8),
                      _timeSetting(
                          '1手ごとの加算', _increment, (v) => _increment = v),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: _startGame,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green.shade700,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
                child: const Text('対局開始', style: TextStyle(fontSize: 18)),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _timeSetting(String label, int value, void Function(int) onChanged) {
    return Row(
      children: [
        SizedBox(width: 160, child: Text(label)),
        SizedBox(
          width: 90,
          child: TextFormField(
            initialValue: value.toString(),
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(
              isDense: true,
              border: OutlineInputBorder(),
            ),
            onChanged: (v) {
              final parsed = int.tryParse(v);
              if (parsed != null) onChanged(parsed);
            },
          ),
        ),
        const SizedBox(width: 8),
        const Text('ms'),
      ],
    );
  }
}
