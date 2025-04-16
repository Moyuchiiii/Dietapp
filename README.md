# Dietapp

Dietappは、日々の体重・体脂肪率・メモ・スタンプを記録し、カレンダーやグラフで可視化できるFlutter製ダイエット管理アプリです。

## 主な機能

- 体重・体脂肪率・メモ・スタンプの記録・編集
- カレンダーで日々の記録・スタンプを一覧表示
- 折れ線グラフで体重・体脂肪率の推移を可視化
- 記録の変更履歴（ログ）閲覧・削除
- ユーザー情報（名前・身長・目標体重）の設定・変更
- 全データ削除機能

## セットアップ方法

1. Flutter環境を用意してください。
2. 必要なパッケージをインストールします。

   ```
   flutter pub get
   ```

3. エミュレータまたは実機でアプリを起動します。

   ```
   flutter run
   ```

## 依存パッケージ

- [sqflite](https://pub.dev/packages/sqflite)（ローカルDB）
- [path](https://pub.dev/packages/path)
- [intl](https://pub.dev/packages/intl)
- [table_calendar](https://pub.dev/packages/table_calendar)
- [fl_chart](https://pub.dev/packages/fl_chart)

## ディレクトリ構成

- `lib/main.dart` ... アプリのエントリーポイント
- `lib/home.dart` ... タブ切り替えのホーム画面
- `lib/input_screen.dart` ... 日々の記録入力画面
- `lib/calendar_screen.dart` ... カレンダー表示画面
- `lib/graph_screen.dart` ... グラフ表示画面
- `lib/options_screen.dart` ... オプション画面
- `lib/data_list_screen.dart` ... ログ一覧画面
- `lib/firt.dart` ... 初期設定・ユーザー情報画面
- `lib/database_helper.dart` ... SQLiteデータベース操作

## 注意事項

- 本アプリは個人利用を想定しています。
- データは端末ローカルに保存されます。アンインストール時は全データが消去されます。

---
