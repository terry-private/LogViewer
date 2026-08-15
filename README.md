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
- 🌐 日本語・英語 — アプリの言語設定に合わせて表示
- ♿️ アクセシビリティ — VoiceOverとDynamic Typeに対応
- 🔌 SwiftLog接続 — 既存の`swift-log`呼び出しをそのまま表示

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

パッケージ内部は次の4ターゲットに分かれている。

- `LogViewerCore` — ログ型、保存、絞り込み
- `LogViewerUI` — SwiftUI／UIKitによる表示。`LogViewerCore`だけに依存
- `LogViewer` — 既存の`import LogViewer`を維持する互換入口
- `LogViewerSwiftLog` — SwiftLog向け接続部品。`LogViewerCore`と`Logging`に依存

通常の利用側はこれまでどおり`LogViewer`製品を追加し、`import LogViewer`を
使用する。画面を必要としないiOS／iPadOS向けの処理では、
`LogViewerCore`製品だけを選択できる。
既存の`swift-log`呼び出しを接続する場合だけ、追加で`LogViewerSwiftLog`製品を
選択する。

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

### シートより前面への表示

標準の`.overlay`は、修飾したViewの階層内へログ画面を表示する。
シートや全画面表示より前面へ出す必要がある場合は、`.window`を指定する。

```swift
ContentView()
    .logViewer(
        on: .custom($showLogs),
        presentation: .window
    )
```

`.window`は修飾したViewが属する`UIWindowScene`へ専用ウインドウを1つだけ作る。
`.custom`では複数ウインドウ対応アプリでも、操作元とは別の場面へ表示しない。
ログ画面を閉じると、表示前にキーだったウインドウへキー状態を戻す。

`.shake`は修飾したViewが属する場面内のResponderで検知するため、別の場面の
LogViewerを開かない。`UIWindow`型全体の動作は変更しない。

シミュレーター、シェイクを利用できない環境、アプリ独自の表示操作を使う場合は、
`.custom`へBindingを渡して表示する。

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
func fetchUser(id: String) {
    Logger.shared.add(
        "ユーザーを取得します: \(id)",
        tags: "api", "user"
    )
}
```

`Logger`と標準の`InMemoryLogStore`は`Sendable`であり、
`MainActor`へ切り替えずに任意のタスクから記録できる。

```swift
Task.detached {
    Logger.shared.add("バックグラウンド処理を開始しました")
}
```

### 保存機能の差し替え

アプリや画面ごとにログを分離する場合は、同じ`LogStore`を`Logger`と
ログ画面へ渡す。

```swift
let store = InMemoryLogStore()
let logger = Logger(store: store)

logger.add("この画面専用のログ")

ContentView()
    .logViewer(
        on: .shake,
        store: store
    )
```

引数を省略したログ画面は`Logger.shared.store`を使用する。

### SwiftLogとの接続

導入アプリが[SwiftLog](https://github.com/apple/swift-log)を使用している場合は、
`LogViewerSwiftLog`製品を追加して`LogViewerLogHandler`を設定する。`LogViewerCore`と
`LogViewer`のターゲット自体はSwiftLogをimport・linkしない。なおSwiftPMでは任意製品を
選んだ場合も、パッケージ宣言に含まれるswift-logが依存解決の対象になる。

```swift
import Logging
import LogViewer
import LogViewerSwiftLog

let store = InMemoryLogStore(privacyPolicy: .standard)

LoggingSystem.bootstrap { label in
    LogViewerLogHandler(label: label, store: store)
}

let logger = Logging.Logger(label: "com.example.network")
logger.info("通信を開始しました", metadata: ["request-id": "42"])

ContentView()
    .logViewer(on: .shake, store: store)
```

`LoggingSystem.bootstrap`はプロセス内で1回だけ呼び出せる。すでに別のBackendを
設定している場合は、その最初の設定箇所でSwiftLogの`MultiplexLogHandler`へ
既存Handlerと`LogViewerLogHandler`を一緒に渡す。接続部品自身はSwiftLogへ再送せず、
受け取った出来事を1回だけ`LogStore`へ追加する。

変換規則は次のとおり。

| SwiftLog | LogViewer |
| --- | --- |
| `trace`から`critical`までの水準 | 同名の`LogLevel` |
| `message` | `LogEntry.message` |
| `label` | `LogEntry.category` |
| `file`、`function`、`line` | `SourceLocation` |
| `source` | 予約付加情報`swift-log.source` |
| Logger／Provider／呼び出し時のmetadata | 後の値を優先した文字列metadata |
| `error` | `error.message`と`error.type` |

配列・辞書のmetadataは安定した文字列表現へ変換する。SwiftLogのmetadata属性と
値の型、元の発生日時、LogViewerのタグは`LogEntry`へ引き継げない。記録日時は
Handlerが受け取った時刻になる。秘密値を保存前に除去する場合は、上の例のように
`InMemoryLogStore(privacyPolicy:)`へ方針を指定する。

### OSLogとの接続範囲

既存の`os.Logger`呼び出しをBackendとして横取りする公開APIはない。
`OSLogStore`は統合ログの履歴を取得できるが、LogViewer向けの欠落しないリアルタイム
配送ではなく、ポーリングでは重複・取りこぼしの境界管理が必要になる。また、OSLogの
プライバシー設定で伏せられた値、元のSwift型、すべての発生元情報は復元できない。
このため、バージョン1ではOSLog履歴の自動取り込みを提供しない。

OSLogとLogViewerの両方へ同じ出来事を送りたい場合は、アプリの共通ログ窓口で
明示的に二つへ渡すか、SwiftLogを入口にしてOSLog Backendと
`LogViewerLogHandler`をMultiplexする。OSLog履歴を後から再投入して、すでに直接
保存したログと混在させる運用は二重記録になるため行わない。

### ログの保持件数

標準の`InMemoryLogStore`は、先に追加されたログから削除しながら
最新1万件を保持する。アプリの用途に合わせて初期化時に変更できる。

```swift
let store = InMemoryLogStore(maximumEntryCount: 2_000)
let logger = Logger(store: store)
```

`maximumEntryCount`へ`0`を指定するとログを保持しない。
負の値は設定できない。

### プライバシーと書き出し

標準の秘匿化方針は、メールアドレス、`Bearer`認証値、`token`、`password`、
`authorization`などの付加情報を`<private>`へ置き換える。秘密値をStoreへ
保持し続けない場合は、保存前に方針を適用する`InMemoryLogStore`を使用する。
付加情報は値だけでなくキーも対象になり、伏せ字後に同じキーが複数できた場合は
`#2`以降の連番を付けて項目を保持する。

```swift
let privacyPolicy = LogPrivacyPolicy.standard
let store = InMemoryLogStore(privacyPolicy: privacyPolicy)
let logger = Logger(store: store)

ContentView()
    .logViewer(
        on: .shake,
        store: store
    )
```

独自の秘密文字列は`LogRedactionRule(matching:)`で追加できる。任意の正規表現は
処理時間を予測できないため公開APIでは受け付けない。付加情報キーは、値だけを
伏せ字にするものと、キーごと削除するものを分けて指定できる。既定値の
`.none`は互換性のためログを変更しない。Storeで保存前秘匿化したログへ同じ方針を
重ねて指定せず、未加工値を持つ任意のStoreの表示・共有だけを保護するときに
`.logViewer(privacyPolicy:)`を使う。本番でログを記録する場合は
`privacyPolicy`を明示し、画面自体を本番へ含めるかもビルド設定で判断する。

ログ画面の操作メニューから、現在の絞り込み結果だけをコピー、テキスト共有、
JSON共有できる。共有画面は利用者が操作を選んだときだけ開く。テキストは各値を
引用して制御文字をescapeし、1件を1行で出力する。JSONは`LogEntry`配列で、日時を
ミリ秒付きISO 8601文字列として出力する。コードから変換する場合は
`LogExporter`へ表示・共有と同じ秘匿化方針を渡す。

### ログの整理

ログ画面には3つの表示方法がある。

- すべて — 時系列ですべてのログを表示
- ファイル — 発生元ファイルごとに表示
- 関数 — 発生元関数ごとに表示

### 絞り込み方法

ログ画面では次の絞り込みを使用できる。

- 検索 — メッセージ、ファイル、関数を大文字小文字を区別せず検索
- ログ水準 — 複数の水準を選択
- タグ — 複数タグをOR（いずれか）またはAND（すべて）で選択
- 期間 — 直近5分、1時間、24時間から選択

すべての条件は同時に指定でき、条件同士はANDで評価される。選択中の条件と
「絞り込み結果件数 / 全件数」は画面下部で確認できる。タグとログ水準を1つも
選択していない場合は、その項目で絞り込まない。

### 言語とアクセシビリティ

ログ画面の固定文字列と日時は、アプリが使用する日本語または英語の地域設定に
合わせて表示される。VoiceOverでは、閉じる、検索、絞り込み、記録の停止・再開、
削除、最新ログへの移動をラベル付きの操作として利用できる。

文字サイズをアクセシビリティサイズまで拡大すると、ヘッダーの表示方法を
自動的に切り替え、検索と主要操作を画面内に維持する。選択中のログ水準とタグは、
色だけでなくチェック印とVoiceOverの選択状態でも示す。ログがない場合、
絞り込み結果がない場合、記録の一時停止中も画面上で状態を確認できる。

## API概要

### LogEntry

新しい連携処理では、公開された値型`LogEntry`を使用する。

```swift
let entry = LogEntry(
    level: .error,
    message: "API要求に失敗しました",
    source: SourceLocation(
        fileID: #fileID,
        function: #function,
        line: #line
    ),
    category: "network",
    tags: ["api", "error"],
    metadata: ["status": "500"]
)

Logger.shared.add(entry)
```

`LogEntry`は`Sendable`かつ`Codable`な値型で、UUIDによる識別子、
`LogLevel`、本文、`SourceLocation`、任意の分類・タグ・付加情報、記録日時を持つ。

### Logger

```swift
// 共有インスタンス
Logger.shared

// 差し替え可能な保存機能
let store = InMemoryLogStore()
let logger = Logger(store: store)

// 保持上限を変更
let smallerStore = InMemoryLogStore(maximumEntryCount: 2_000)

// 任意のタグを付けてログを追加
func add(
    _ message: String,
    tags: Tag...,
    fileID: String = #fileID,
    function: String = #function,
    line: UInt = #line
)
```

既存の文字列追加APIは、受け取った値を`LogEntry`へ変換して保存する。
`Logger`は保存機能を持たない軽量な窓口で、実際の状態は`LogStore`が管理する。
標準の`InMemoryLogStore`は並行する追加、一時停止、削除を同期し、
`AsyncStream<LogStoreSnapshot>`で画面へ変更を通知する。
標準の最大保持件数は1万件で、上限超過時は追加順の古いログから削除する。
移行と非推奨化の方針は[移行ガイド](docs/MIGRATION.md)を参照。

### View拡張

```swift
// ログ画面を有効化
func logViewer(
    on trigger: ShowTrigger,
    presentation: LogViewerPresentationStyle = .overlay,
    store: any LogStore = Logger.shared.store,
    privacyPolicy: LogPrivacyPolicy = .none,
    isTransparent: Bool = false
) -> some View
```

`presentation`は標準の`.overlay`と、シートより前面へ出す`.window`を選べる。
`isTransparent`は、ログ画面を開いたときの背景表示を指定する。
表示中は画面内のメニューから変更できる。

利用側でも`os.Logger`を使う場合は、このパッケージの現在のロガーを
`LogViewer.Logger`と明示する。新しいログ連携処理では`LogEntry`を使用し、
画面単位で分離するときは`LogStore`を注入する。

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
