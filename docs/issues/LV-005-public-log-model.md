---
id: LV-005
github_issue: 6
title: "Design public LogEntry, LogLevel, metadata, and source models"
status: blocked
labels: [architecture, enhancement]
depends_on: [LV-004]
---

## Goal

アプリやログAdapterから共通利用できる、拡張可能な公開ログモデルを定義する。

## Scope

- `LogEntry`
- `LogLevel`
- `SourceLocation`
- category、tags、metadata、timestamp
- UUIDなど安定したID型
- 既存`Logger.shared.add`からの互換経路

## Acceptance criteria

- [ ] 公開モデルが`Sendable`である
- [ ] レベル、メッセージ、発生元、任意メタデータを表現できる
- [ ] UI固有型へ依存していない
- [ ] API移行方法とdeprecated方針が文書化されている
- [ ] 等価性、ソート、変換のテストがある
