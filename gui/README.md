# OthelloAI GUI

オセロAI開発用のデスクトップGUIアプリです。Flutter製で Windows / Mac に対応しています。

## 機能

- **人間 vs 人間 / 人間 vs AI / AI vs AI** の対局
- **エンジンの選択**（exeファイルをファイルダイアログで指定）
- **盤面表示**（合法手ヒント付き）
- **スコア表示**（黒・白の石数、現在の手番をハイライト）
- **パス処理**（合法手がない場合は自動でパス）
- **勝敗判定**（ゲーム終了時に結果を表示）
- **時間設定**（1手の持ち時間・1手ごとの加算をms単位で指定）

## 画面構成

```
SettingsScreen（対局設定画面）
    ↓ 対局開始ボタン
GameScreen（対局画面）
    ↓ 設定画面に戻るボタン
SettingsScreen
```

## ファイル構成

```
lib/
├── main.dart                      # アプリ起点
├── models/
│   ├── board.dart                 # オセロのゲームロジック
│   └── game_config.dart           # 対局設定データ
├── engine/
│   └── engine_process.dart        # C++エンジンとのプロセス通信
├── screens/
│   ├── settings_screen.dart       # 対局設定画面
│   └── game_screen.dart           # 対局画面
└── widgets/
    └── board_painter.dart         # 盤面のCustomPainter描画
```

## エンジンとの通信

`engine_process.dart` がエンジンのexeをサブプロセスとして起動し、stdin/stdout でプロトコル通信を行います。プロトコルの仕様はリポジトリルートの README を参照してください。

## ビルド方法

```bash
# Windowsアプリとしてビルド
flutter build windows

# Macアプリとしてビルド
flutter build macos
```

## 開発用の起動

```bash
flutter run -d windows
flutter run -d macos
```
