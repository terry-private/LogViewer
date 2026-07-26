# 対応方針

## 対応環境

| 項目 | 最低バージョン | 備考 |
| --- | --- | --- |
| iOS／iPadOS | 18.0 | 画面機能でiOS 18以降のSwiftUI APIを使用する |
| Xcode | 26.0 | 安定版を互換性検証の基準とする |
| Swift tools | 6.2 | `Package.swift`で宣言する |
| Swift言語モード | 6 | パッケージの各ターゲットをSwift 6モードでコンパイルする |

最低バージョンは互換性の下限であり、最新OSだけを対応対象とする意味ではない。
このパッケージはiOS 18から、対応するXcodeに同梱されたSDKのバージョンまで、
継続してビルド・実行できる状態を目指す。

## 対応プラットフォーム

`LogViewerCore`はログ型、保存、絞り込みを持ち、SwiftUI／UIKitを取り込まない。
`LogViewerUI`は表示機能を持ち、`LogViewerCore`だけに依存する。
既存の`LogViewer`製品は両ターゲットを再公開し、従来の導入方法を維持する。

正式な対応対象は次のとおり。

- iOS
- iPadOS

次のプラットフォームは現在の検証対象に含めない。

- macOS
- Mac Catalyst
- tvOS
- watchOS
- visionOS

`LogViewerCore`製品は、正式対応中のiOS／iPadOSで画面機能を必要としない
利用向けに提供する。他プラットフォームへの対応は、その環境でのビルドと
テストを整備してから判断する。ターゲット分割だけを、未検証プラットフォームの
正式対応とは扱わない。

## Xcodeの対応方針

- 安定版Xcodeを互換性の基準とする。
- ベータ版Xcodeは早期検証に使用できるが、ベータ版での成功を
  最低対応の安定版Xcodeによる検証の代わりにはしない。
- 最低バージョンを意図的に引き上げるプルリクエストでは、
  `Package.swift`、`README.md`、この文書、検証手順を同時に更新する。

## 想定用途と本番ビルド

LogViewerは、主にデバッグ、開発、TestFlight、そのほかの内部向けビルドで
使用する開発支援ツールである。

現在のパッケージは、リリースビルドから自身を自動的に除外しない。
本番アプリへ組み込む場合は、利用側が表示機能へのアクセスを制御し、
秘密情報や個人情報を記録しないようにする必要がある。
秘匿化と本番環境でのアクセス制御は
[GitHub課題第13号](https://github.com/terry-private/LogViewer/issues/13)で管理する。

## ローカル検証

すべてのローカル検証を実行する。

```bash
./Scripts/verify.sh
```

既定では、LogViewerスキームが報告する互換性のあるiOSシミュレーターを
1台選択する。特定の実行環境が必要な場合は次のように上書きする。

```bash
LOGVIEWER_TEST_DESTINATION='platform=iOS Simulator,name=<名前>,OS=<バージョン>' \
  ./Scripts/verify.sh
```

スクリプトは、次の検証を個別に実行する。

パッケージ定義を解析する。

```bash
swift package dump-package
```

最低対応のiOSバージョンを対象にパッケージをビルドする。

```bash
xcodebuild \
  -scheme LogViewer \
  -destination 'generic/platform=iOS Simulator' \
  IPHONEOS_DEPLOYMENT_TARGET=18.0 \
  build
```

インストール済みのiOS 18以降のシミュレーターでテストを実行する。

```bash
xcodebuild \
  -scheme LogViewer \
  -destination 'platform=iOS Simulator,name=<シミュレーター名>' \
  test
```

最低iOSバージョンは汎用ビルドで検証する。最低バージョンのiOS実行環境で
テストするには、その実行環境をインストールし、
`LOGVIEWER_TEST_DESTINATION`を明示する必要がある。

対応環境を変更または公開するときは、最低対応の安定版Xcodeで
この検証を実行する。ベータ版ツールチェーンでの成功は早期の確認には役立つが、
最低対応の安定版ツールチェーンで成功した証明にはならない。
