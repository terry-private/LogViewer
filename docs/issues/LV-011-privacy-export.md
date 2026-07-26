---
id: LV-011
github_issue: 13
title: "Add privacy controls, redaction, and log export"
status: blocked
labels: [security, enhancement]
depends_on: [LV-005, LV-006]
---

## Goal

ログに含まれる秘密情報を保護しつつ、調査に必要な範囲を安全に共有できるようにする。

## Scope

- RedactionルールとカスタムMask
- 本番ビルドでの有効化方針
- コピー、テキスト、JSONエクスポート
- エクスポート対象へ現在のフィルターを適用
- Token、メール、任意metadataの公開レベル

## Acceptance criteria

- [ ] 表示とエクスポートの両方にRedactionが適用される
- [ ] 秘密値を保持しない設定が可能である
- [ ] JSON出力仕様がテストされている
- [ ] 本番利用時の注意事項が文書化されている
- [ ] 共有操作はユーザーの明示操作でのみ開始される
