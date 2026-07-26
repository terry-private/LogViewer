---
id: LV-000
github_issue: 1
title: "Tracking: LogViewer v1.0 reusable foundation"
status: ready
labels: [epic, maintenance]
depends_on: []
---

## Goal

LogViewerを複数のSwiftUIアプリへ安全に導入でき、長期保守できるv1.0ライブラリへ整える。

## Scope

- CoreとUIの責務分離
- 任意スレッドからのログ記録
- Scene対応の専用Window表示
- 保持上限、検索、フィルター、プライバシー
- テスト、ドキュメント、配布手順

## Child issues

LV-001からLV-014までを推奨順に進める。

## Acceptance criteria

- [ ] LV-001からLV-014が完了している
- [ ] サポート対象の全環境でビルドとテストが成功する
- [ ] サンプルアプリで導入から表示、検索、共有まで確認できる
- [ ] 公開APIとREADME、DocCの内容が一致している
