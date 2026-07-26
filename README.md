# LogViewer

SwiftUIアプリ向けの、見やすく直感的なデバッグログ表示ツール。

[![Swift](https://img.shields.io/badge/Swift-6.2-orange.svg)](https://swift.org)
[![プラットフォーム](https://img.shields.io/badge/platform-iOS%2018%2B-blue.svg)](https://developer.apple.com/ios/)
[![ライセンス](https://img.shields.io/badge/license-MIT-green.svg)](https://github.com/terry-private/LogViewer/blob/main/LICENSE)

## 主な機能

- 🔍 リアルタイム表示 — 生成されたログをすぐに確認
- 🏷️ タグ絞り込み — 使用中のタグを自動収集して選択
- 📂 グループ表示 — ファイルまたは関数ごとに整理
- 📱 シェイク表示 — 端末を振ってログ画面を表示
- ⏸️ 一時停止と再開 — ログ収集を画面上で制御
- 🎨 SwiftUIによる画面 — 滑らかな操作と見やすい表示
- 🔄 自動スクロール — 新しいログへ自動で追従
- 🔎 検索 — メッセージ、ファイル、関数を全文検索

## 必要環境

- iOS 18.0以降
- Xcode 26.0以降
- Swift 6.2以降

現在は、iOSおよびiPadOS上で動作するSwiftUIアプリに対応する。
macOS、Mac Catalyst、tvOS、watchOS、visionOSは、まだ正式な検証対象に
含まれていない。

LogViewerは、主にデバッグおよび内部向けビルドでの使用を想定している。
本番ビルドへ含める場合は、ログ表示を有効にする前に、認証情報、個人情報、
そのほかの秘密情報が記録されていないことを確認すること。

互換性とローカル検証の詳細は
[対応方針](docs/SUPPORT.md)を参照。
課題、進捗、優先順位は
[GitHub課題](https://github.com/terry-private/LogViewer/issues)で管理する。
文書の管理場所と更新規則は
[ドキュメント方針](docs/README.md)を参照。

## モジュール構成

パッケージ内部は次の3ターゲットに分かれている。

- `LogViewerCore` — ログ型、保存、絞り込み
- `LogViewerUI` — SwiftUI／UIKitによる表示。`LogViewerCore`だけに依存
- `LogViewer` — 既存の`import LogViewer`を維持する互換入口

通常の利用側はこれまでどおり`LogViewer`製品を追加し、`import LogViewer`を
使用する。画面を必要としないiOS／iPadOS向けの処理では、
`LogViewerCore`製品だけを選択できる。

中核ターゲットにはSwiftUI／UIKitを含めず、画面機能から中核機能への
一方向依存を維持する。

## 導入方法

### Swift Package Manager

XcodeからLogViewerを追加する。

1. 「ファイル」→「パッケージの依存関係を追加」を選択
2. `https://github.com/terry-private/LogViewer.git`を入力
3. 最初の安定版が公開されるまでは`main`ブランチを選択
4. 「パッケージを追加」を実行

`Package.swift`へ直接追加する場合は次のように記述する。

```swift
dependencies: [
    .package(
        url: "https://github.com/terry-private/LogViewer.git",
        branch: "main"
    )
]
```

## 基本的な使い方

### 1. 読み込みと設定

```swift
import LogViewer
import SwiftUI

@main
struct MyApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView()
                .logViewer(on: .shake) // 端末を振って表示
        }
    }
}
```

### 2. ログの追加

```swift
import LogViewer

// 単純なログ
Logger.shared.add("ユーザーがログインしました")

// タグ付きログ
Logger.shared.add("API応答を受信しました", tags: "api", "network")

// エラーの記録
@MainActor
func report(_ error: any Error) {
    Logger.shared.add("処理に失敗しました: \(error)", tags: "error")
}

// 複数タグ
Logger.shared.add(
    "ユーザー情報を更新しました",
    tags: "user", "api", "success"
)
```

### 3. 任意の操作による表示

```swift
struct ContentView: View {
    @State private var showLogs = false

    var body: some View {
        VStack {
            Button("ログを表示") {
                showLogs = true
            }
        }
        .logViewer(on: .custom($showLogs))
    }
}
```

## 詳しい使い方

### タグによる絞り込み

ログに使われているタグは自動的に収集され、ログ画面から選択できる。

```swift
Logger.shared.add("通信を開始しました", tags: "network")
Logger.shared.add("認証に成功しました", tags: "auth", "success")
Logger.shared.add("キャッシュがありません", tags: "cache", "warning")

ContentView()
    .logViewer(on: .shake)
```

### 発生元情報

ログにはファイルと関数の情報が自動的に記録される。

```swift
// UserService.swift内
@MainActor
func fetchUser(id: String) {
    Logger.shared.add(
        "ユーザーを取得します: \(id)",
        tags: "api", "user"
    )
}
```

現在の`Logger` APIは`MainActor`へ分離されている。`@MainActor`の実行環境から
呼び出すか、明示的にメインアクターへ切り替えること。
任意のタスクから直接記録する対応は
[GitHub課題第7号](https://github.com/terry-private/LogViewer/issues/7)で管理する。

### ログの整理

ログ画面には3つの表示方法がある。

- すべて — 時系列ですべてのログを表示
- ファイル — 発生元ファイルごとに表示
- 関数 — 発生元関数ごとに表示

### 絞り込み方法

ログ画面では次の絞り込みを使用できる。

- タグ — 自動収集されたタグから選択
- 検索 — 指定した文字列を含むログを検索

現在、検索とタグ絞り込みは別の表示方法として動作する。
複数条件を組み合わせる絞り込みは
[GitHub課題第9号](https://github.com/terry-private/LogViewer/issues/9)で管理する。

## API概要

### Logger

```swift
// 共有インスタンス
Logger.shared

// 任意のタグを付けてログを追加
func add(
    _ message: String,
    tags: Tag...,
    fileID: String = #fileID,
    function: String = #function
)
```

### View拡張

```swift
// ログ画面を有効化
func logViewer(
    on trigger: ShowTrigger,
    isTransparent: Bool = false
) -> some View
```

`isTransparent`は、ログ画面を開いたときの背景表示を指定する。
表示中は画面内のメニューから変更できる。

利用側でも`os.Logger`を使う場合は、このパッケージの現在のロガーを
`LogViewer.Logger`と明示する。名前が衝突しにくいログAPIへの変更は、
バージョン1の公開モデル設計で対応する。

### ShowTrigger

```swift
enum ShowTrigger {
    case shake                  // 端末を振って表示
    case custom(Binding<Bool>) // 任意のBindingで表示を切り替え
}
```

## 貢献

不具合や改善案は
[GitHub課題](https://github.com/terry-private/LogViewer/issues)へ登録する。
変更を提案する場合はプルリクエストを作成する。

## ライセンス

LogViewerはMITライセンスで公開されている。詳細は
[LICENSE](LICENSE)を参照。

## 作者

[terry-private](https://github.com/terry-private)
