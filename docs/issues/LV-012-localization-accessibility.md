---
id: LV-012
github_issue: 12
title: "Localize the UI and improve accessibility"
status: blocked
labels: [accessibility, ui]
depends_on: [LV-008, LV-010]
---

## Goal

日本語・英語環境、VoiceOver、Dynamic TypeでViewerを実用的に操作できるようにする。

## Scope

- UI文字列のString Catalog化
- 日本語と英語
- アイコンボタンのAccessibility Label
- Dynamic Typeと長文表示
- Viewer表示時のAccessibility focus
- 空状態、停止状態、削除確認

## Acceptance criteria

- [ ] ハードコードされた利用者向け文字列が残っていない
- [ ] 日本語・英語でレイアウトが破綻しない
- [ ] VoiceOverだけで表示、検索、停止、削除、終了ができる
- [ ] 最大Dynamic Typeで重要操作が隠れない
- [ ] 色だけに依存した状態表現がない
