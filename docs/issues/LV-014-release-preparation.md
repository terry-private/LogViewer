---
id: LV-014
github_issue: 15
title: "Add a sample app, DocC, changelog, and prepare v1.0 release"
status: blocked
labels: [documentation, release]
depends_on: [LV-003, LV-004, LV-005, LV-006, LV-007, LV-008, LV-009, LV-010, LV-011, LV-012, LV-013]
---

## Goal

新規アプリが迷わず導入・検証でき、Semantic Versioningに沿ってv1.0を公開できる状態にする。

## Scope

- Sample App
- README Quick Start
- DocC APIドキュメント
- Migration Guide
- CHANGELOG
- Contribution Guide
- stable版Xcodeでの最終検証
- Gitタグとリリースノートの準備

## Acceptance criteria

- [ ] Sample AppでWindow表示、Shake、検索、共有を確認できる
- [ ] READMEだけで基本導入できる
- [ ] 旧APIからの移行手順がある
- [ ] 対応環境のビルド・テストがすべて成功する
- [ ] `1.0.0`タグ作成前のチェックリストが完了している
- [ ] リリース後の互換性方針が明記されている
