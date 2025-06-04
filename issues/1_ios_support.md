# iOSサポートの追加

## 背景
現在の `lut_transformer` は Android のみを対象とした実装になっています。より多くのユーザーに利用してもらうため、iOS を始めとした他プラットフォームへの対応が必要です。

## やること
- `platform_interface` を作成し、共通 API を定義する
- iOS 向けのプラグイン実装を追加する
- Dart 側でプラットフォームごとの実装を選択できるようにする
- iOS での動作を確認するためのテストを追加する
- README などドキュメントを更新し、iOS でのセットアップ手順を追記する

## 参考
- [Flutter プラグイン開発ガイド](https://docs.flutter.dev/development/packages-and-plugins/plugin-development)
