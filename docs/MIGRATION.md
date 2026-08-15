# 公開APIの移行ガイド

## 公開ログモデル

新しいログ連携処理では、`LogViewerCore`の`LogEntry`を使用する。
`LogEntry`はログ水準、本文、発生元、分類、タグ、付加情報、記録日時を
画面機能に依存しない値として保持する。

```swift
import LogViewerCore

func recordSlowResponse() {
    let entry = LogEntry(
        level: .warning,
        message: "応答に時間がかかっています",
        source: SourceLocation(
            fileID: #fileID,
            function: #function,
            line: #line
        ),
        category: "network",
        tags: ["performance"],
        metadata: ["duration": "2.4"]
    )

    Logger.shared.add(entry)
}
```

`LogEntry`は`Sendable`なので任意の実行環境で作成できる。
`Logger`と標準の`InMemoryLogStore`も`Sendable`であり、
`Logger.shared.add`は`MainActor`へ切り替えずに呼び出せる。

保存先を共有状態から分離する場合は、保存機能を明示的に注入する。

```swift
import LogViewer

let store = InMemoryLogStore()
let logger = Logger(store: store)

logger.add("独立した保存先へ記録します")

ContentView()
    .logViewer(on: .shake, store: store)
```

## 保存件数の上限

`InMemoryLogStore`と`Logger.shared.store`は、標準で最新1万件を保持する。
上限を超えると、記録日時ではなく保存機能へ追加された順序に基づき、
先に追加されたログから削除する。

以前と同じく実行中の全ログを保持する必要がある場合も、無制限にはせず、
アプリの想定量に合わせて明示的な上限を指定する。

```swift
let store = InMemoryLogStore(maximumEntryCount: 50_000)
let logger = Logger(store: store)
```

`maximumEntryCount`は0以上を指定する。`0`の場合はログを保持しない。

## 専用ウインドウ表示

既存の`.logViewer(on:)`は引き続き`.overlay`で表示するため、動作は変わらない。
シート、全画面表示、警告表示より前面へログ画面を表示する場合は、
`presentation: .window`を明示する。

```swift
ContentView()
    .logViewer(
        on: .custom($showLogs),
        presentation: .window
    )
```

専用ウインドウは呼び出し元Viewが属する`UIWindowScene`ごとに管理される。
閉じると表示前のキーウインドウへ戻る。

## シェイク検知

シェイク検知は`UIWindow.motionEnded`の全体的な上書きから、
`.logViewer(on: .shake)`を設定したViewの場面内Responderへ移行した。
利用側の`UIWindow`実装や別の場面の表示状態を変更しない。

`deviceDidShakeNotification`を直接購読している場合、`object`は従来どおり
`UIEvent?`として利用できる。検知した場面は
`LogViewerShakeNotification.windowSceneUserInfoKey`を使って`userInfo`から
取得できる。通知の発火範囲はすべての`UIWindow`から、
`.logViewer(on: .shake)`を設定したViewの所属場面へ狭まる。通知だけを購読して
いた利用側も、検知する場面のViewへ`.logViewer(on: .shake)`を設定する必要がある。

シミュレーターやシェイク非対応環境では、引き続き`.custom`へBindingを渡して
ボタン、メニュー、デバッグ操作などから表示できる。

## 絞り込み

検索、ログ水準、タグ、期間は排他的な表示方法ではなくなり、同時に指定できる。
条件同士はAND、複数タグは画面でORまたはANDを選択して評価する。

従来はタグ絞り込みを選び、タグを1つも選択していない場合に「タグなし」のログ
だけを表示していた。現在は空のタグ選択を「タグ条件なし」として扱い、すべての
タグ有無を表示する。「タグなし」だけを対象にする専用条件は提供しない。

## 既存APIとの互換性

秘匿化を指定しない既存の`InMemoryLogStore`と`.logViewer`は、引き続き
`LogPrivacyPolicy.none`として動作する。保存済みの値を後から復元不能な形で
秘匿化したい場合は、Store作成時に方針を明示する。

```swift
let policy = LogPrivacyPolicy.standard
let store = InMemoryLogStore(privacyPolicy: policy)
let logger = Logger(store: store)
```

任意の`LogStore`に未加工のログを保持したまま表示・共有だけを秘匿化する場合は、
`.logViewer(privacyPolicy:)`へ方針を渡す。秘密値を保持しない要件がある場合は、
表示時ではなく保存前の秘匿化を使用する。同じ方針をStore、Viewer、Exporterへ
重ねて指定せず、未加工値が入る最初の必要な境界で適用する。

次の既存コードは引き続き利用できる。

```swift
Logger.shared.add("処理を開始しました", tags: "debug")
```

文字列を受け取る`Logger.add`は、ログ水準`.info`、空の分類・付加情報を持つ
`LogEntry`へ変換する。ファイル、関数、行番号は呼び出し元から取得する。

## 非推奨化の方針

この変更では、既存の`Logger.shared.add`を非推奨にしない。
既存コードを変更せずに新しいスレッド安全な保存機能へ移行できるよう、
共有APIを互換窓口として維持するためである。

将来、共有APIを置き換える必要が生じた場合は、次の順序で移行する。

1. 新しい保存APIと移行例を公開する
2. 既存APIから新しい保存APIへの互換変換を維持する
3. 少なくとも1回の移行期間を設ける
4. 非推奨属性、代替API、削除予定版を同時に案内する

関連する作業状態と完了条件は
[GitHub課題第7号](https://github.com/terry-private/LogViewer/issues/7)で管理する。
