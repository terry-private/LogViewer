---
id: LV-007
github_issue: 8
title: "Add retention policy and improve rendering/search performance"
status: blocked
labels: [performance, enhancement]
depends_on: [LV-006]
---

## Goal

長時間起動や大量ログでもメモリ使用量とUI応答性を安定させる。

## Scope

- 最大ログ件数と保持ポリシー
- 古いログ削除時のタグ・グループ整合性
- ログの三重保持の見直し
- DateFormatterの行単位生成廃止
- 検索・絞り込みの不要な再計算削減

## Acceptance criteria

- [ ] 最大件数を設定できる
- [ ] 上限超過時に古いログが決定的に削除される
- [ ] 削除後もタグ・ファイル・関数グループが正しい
- [ ] 1万件規模の基準テストがある
- [ ] UI描画中に行ごとのDateFormatter生成がない
