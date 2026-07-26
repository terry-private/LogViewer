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

## 既存APIとの互換性

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
