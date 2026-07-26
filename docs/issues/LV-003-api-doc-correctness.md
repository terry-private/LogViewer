---
id: LV-003
github_issue: 4
title: "Fix public API behavior and README inconsistencies"
status: in-progress
labels: [bug, documentation]
depends_on: [LV-002]
---

## Goal

公開APIの実際の挙動とドキュメントを一致させる。

## Scope

- `isTransparent`が初期表示へ反映されない不具合
- READMEの複合フィルター記述
- `tags`引数のdeprecated表記
- 存在しない`1.0.0`タグを前提にした導入例
- `Logger`と`os.Logger`の名前衝突方針

## Acceptance criteria

- [ ] 全公開引数に効果または明確なdeprecated指定がある
- [ ] READMEのサンプルがコンパイル可能である
- [ ] 未公開バージョンを指定した導入例がない
- [ ] 互換性を壊す変更は後続Issueへ明示的に分離されている

## Verification

- 公開サンプルを小さなConsumer PackageまたはSample Appでビルドする
