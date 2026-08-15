# SwiftLog接続部品とOSLog連携範囲

## 背景

導入アプリがSwiftLogや`os.Logger`をすでに使用している場合、すべての呼び出しを
LogViewer固有の`Logger`へ書き換えるのは導入コストが高い。一方、中核機能が特定の
ログ基盤へ依存すると、使用しないアプリにも依存関係と互換性管理を強制する。

## 決定

SwiftLog向けの`LogViewerLogHandler`を、別製品・別ターゲット
`LogViewerSwiftLog`として提供する。接続ターゲットだけが公式`swift-log`の
`Logging`製品へ依存し、`LogViewerCore`、`LogViewerUI`、互換入口`LogViewer`は
依存しない。

HandlerはSwiftLogの水準を同名の`LogLevel`へ写し、message、file、function、lineを
対応する`LogEntry`の項目へ渡す。labelはcategory、sourceは予約付加情報
`swift-log.source`とする。metadataはHandler、MetadataProvider、呼び出し時の順で
後の値を優先し、error情報と実際のsourceは接続部品の予約値として最後に設定する。
配列と辞書はキー順が安定した文字列へ変換する。

接続部品は受け取った出来事を`LogStore.add`へ1回だけ渡し、SwiftLogへ再送しない。
別Backendと併用する場合は、アプリがSwiftLogの最初のbootstrapで
`MultiplexLogHandler`を構成する。`LoggingSystem.bootstrap`を接続部品が自動実行する
APIは提供しない。

Appleの統合ログは`OSLogStore`で履歴を取得できるが、既存の`os.Logger`呼び出しへ
Backendを差し込む仕組みではない。履歴のポーリングはリアルタイム配送を保証せず、
位置管理によって重複や取りこぼしが生じ得る。プライバシー設定で伏せられた値や、
LogEntryが必要とするすべての型・発生元情報も復元できない。そのため、バージョン1
ではOSLog履歴の自動取り込みを提供しない。

## 採用理由

- Core/UIターゲットはSwiftLogをimport・linkせず、接続製品だけがビルド依存する
- SwiftPMのパッケージ解決では、接続製品を選ばない場合もswift-logが解決対象になる
- 既存のSwiftLog呼び出しを変更せずLogViewerへ配送できる
- Handlerの値セマンティクスとSwiftLogの水準判定を維持できる
- 自動bootstrapと再送を避け、無限再送と意図しない二重記録を防げる
- OSLog履歴取得をリアルタイムBackendと誤認させない

## 採用しなかった方式

- `LogViewerCore`からSwiftLogへ直接依存する方式:
  接続を使わないアプリにも依存が追加される。
- 接続部品が`LoggingSystem.bootstrap`を自動実行する方式:
  SwiftLogのプロセス内1回という設定契約と既存Backendに競合する。
- SwiftLogへ再送するラッパー方式:
  Multiplex構成によって循環と二重記録を起こし得る。
- `OSLogStore`を常時ポーリングする方式:
  欠落なし、重複なし、即時反映を保証できず、秘密値と発生元も復元できない。

## 影響

- SwiftLog利用側は`LogViewerSwiftLog`製品を明示的に追加する
- metadata属性と元の型は文字列化で失われる
- SwiftLogの出来事に発生日時がないため、Handler受信時刻を使用する
- `os.Logger`だけを使用する既存コードは自動ではLogViewerへ表示されない
- OSLogと併用する場合は共通窓口またはSwiftLog Multiplexをアプリ側で構成する

## 関連情報

- [SwiftLog](https://github.com/apple/swift-log)
- [Apple Logging](https://developer.apple.com/documentation/os/logging)
- [OSLogStore](https://developer.apple.com/documentation/oslog/oslogstore)
- [GitHub課題第14号](https://github.com/terry-private/LogViewer/issues/14)
