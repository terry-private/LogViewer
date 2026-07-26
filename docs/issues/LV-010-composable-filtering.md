---
id: LV-010
github_issue: 9
title: "Implement composable level, tag, text, and period filters"
status: blocked
labels: [enhancement, ui]
depends_on: [LV-005, LV-007]
---

## Goal

検索と各種条件を同時に利用でき、大量ログから目的の情報へ素早く到達できるようにする。

## Scope

- テキスト、レベル、タグ、期間の複合条件
- タグのAND/OR仕様
- 大文字小文字とLocaleを考慮した検索
- フィルター状態の明示とリセット
- 必要に応じた検索debounce

## Acceptance criteria

- [ ] 検索とタグを同時に指定できる
- [ ] 複数条件の評価順とAND/OR仕様がテストされている
- [ ] 空の条件が予期せず「タグなしのみ」にならない
- [ ] フィルター中であることと結果件数が分かる
- [ ] 1万件の検索でUI操作を著しくブロックしない
