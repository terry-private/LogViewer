# 変更履歴

このファイルをバージョンごとの利用者向け変更の正本とする。GitHub Releaseは、
対応する見出しの要約とこのファイルへのリンクを掲載する。

形式は[Keep a Changelog](https://keepachangelog.com/ja/1.1.0/)を参考にし、
バージョン番号はセマンティックバージョニングに従う。

## [1.0.0] - 未公開

### 追加

- スレッド安全で保持上限を持つ`LogStore`と依存性注入
- 検索、水準、タグ、相対期間を組み合わせるログ画面
- 現在の`UIWindowScene`に対応した専用ウインドウ表示
- 場面単位のシェイク検知と任意操作による表示
- 日本語・英語、VoiceOver、Dynamic Typeへの対応
- 保存前・表示前・書き出し前の秘匿化
- 絞り込み後ログのコピー、テキスト共有、JSON共有
- 任意導入のSwiftLog接続製品
- サンプルアプリ、DocC、Xcode 26.2安定版CI

### 互換性

- iOS／iPadOS 18.0以降
- Xcode 26.2以降
- Swift tools 6.2、Swift 6言語モード

### 既知の制約

- macOS、Mac Catalyst、tvOS、watchOS、visionOSは正式対応外
- OSLog履歴の自動取り込みは提供しない
- 実端末の物理シェイク、実VoiceOver、外部共有先は公開前の手動確認対象

[1.0.0]: https://github.com/terry-private/LogViewer/releases/tag/1.0.0
