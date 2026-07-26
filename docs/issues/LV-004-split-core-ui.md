---
id: LV-004
github_issue: 5
title: "Split LogViewerCore and LogViewerUI targets"
status: blocked
labels: [architecture, maintenance]
depends_on: [LV-002]
---

## Goal

ログ保存・検索ロジックをSwiftUI/UIKitから分離し、単体テストと将来の他プラットフォーム対応を容易にする。

## Scope

- `LogViewerCore`ターゲットの追加
- Entity、Store、FilterロジックのCore移動
- `LogViewerUI`のCore依存
- 既存`LogViewer` productの互換性維持方針
- Preview用ダミーデータの本番コードからの分離

## Out of scope

- ログモデルの大幅なAPI変更
- 専用Window表示

## Acceptance criteria

- [ ] CoreがSwiftUI/UIKitをimportしていない
- [ ] CoreのテストをUIなしで実行できる
- [ ] 既存の基本的な導入コードが引き続きビルドできる
- [ ] 依存方向がUIからCoreへの一方向になっている
