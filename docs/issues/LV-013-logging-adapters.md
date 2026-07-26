---
id: LV-013
github_issue: 14
title: "Provide adapters for existing logging pipelines"
status: blocked
labels: [integration, enhancement]
depends_on: [LV-005, LV-006]
---

## Goal

導入アプリが既存のログ呼び出しを大きく書き換えずにLogViewerへ接続できるようにする。

## Scope

- `swift-log`向け`LogHandler`またはAdapter
- `OSLog`連携で可能な範囲の調査と実装
- Adapterを別target/productへ分離
- レベル、metadata、sourceの変換規則

## Acceptance criteria

- [ ] Coreが特定ログライブラリへ依存しない
- [ ] Adapter依存を導入アプリが選択できる
- [ ] レベルとmetadataの変換がテストされている
- [ ] OSLogから取得できない情報や制約が明記されている
- [ ] Adapter自身が無限再送や二重記録を起こさない
