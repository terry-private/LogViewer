# ADR 0012: 最低対応Xcodeを26.2とする

## 背景

Xcode 26.0.1とSwift 6.2.0で`LogViewerUI`をReleaseビルドすると、Swift
コンパイラが`PerformanceSILLinker`の`isConcrete` assertionで停止した。
Debugビルドや中核製品だけの成功では、利用アプリのArchiveと配布可能性を
保証できない。

同じ`isConcrete` assertionと`PerformanceSILLinker`を扱う
[Swiftの不具合報告](https://github.com/swiftlang/swift/issues/83788)がある。
本パッケージでは、Xcode 26.2で全公開製品のDebug／Releaseビルドに成功した。

## 決定

- 最低対応Xcodeを26.2とする
- iOS／iPadOS 18.0とSwift tools 6.2の下限は変更しない
- Xcode 26.2で全公開製品のDebug／Release、全テスト、DocC、サンプルE2Eを検証する
- Xcodeのminor下限は`Package.swift`で表現できないため、`SUPPORT.md`で宣言し、
  CIで継続的に検証する

## 採用理由

- Release最適化を含む、利用者と同じビルド条件を保証できる
- コンパイラ修正版を下限にすることで、パッケージへ一時的な回避策を持ち込まない
- 公開前に下限を確定するため、1.x利用者への破壊的変更にならない

## 採用しなかった方式

- Releaseだけ最適化を無効にする方式:
  配布時と異なる条件になり、性能とコード生成の検証を弱める。
- `@_optimize(none)`や内部LLVMフラグを追加する方式:
  underscored APIや特定コンパイラ実装へ依存し、恒久的な保守負担になる。
- Xcode 26.0.1でDebugビルドだけを継続する方式:
  Archiveできない環境を対応対象と誤認させる。

## 互換性と保守への影響

Xcode 26.0および26.0.1は対応対象外となる。公開Swift API、JSON v1、最低OS、
Swift tools versionには変更がない。将来Xcode下限を変更するときも、全公開製品の
Releaseビルドを含む実測結果を根拠にする。

## 関連

- [GitHub課題第15号](https://github.com/terry-private/LogViewer/issues/15)
- [GitHubプルリクエスト第27号](https://github.com/terry-private/LogViewer/pull/27)
- [対応方針](../SUPPORT.md)
