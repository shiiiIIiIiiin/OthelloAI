enum PlayerType { human, engine }

class GameConfig {
  final PlayerType blackPlayer;
  final PlayerType whitePlayer;
  final String blackName;
  final String whiteName;
  final String blackEnginePath;
  final String whiteEnginePath;
  final int timePerMove; // ms
  final int increment;   // ms

  const GameConfig({
    required this.blackPlayer,
    required this.whitePlayer,
    this.blackName = '黒',
    this.whiteName = '白',
    this.blackEnginePath = '',
    this.whiteEnginePath = '',
    this.timePerMove = 5000,
    this.increment = 1000,
  });
}
