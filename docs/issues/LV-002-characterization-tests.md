---
id: LV-002
github_issue: 3
title: "Add characterization tests and CI-ready verification commands"
status: in-progress
labels: [testing, maintenance]
depends_on: [LV-001]
---

## Goal

既存挙動をテストで固定し、以後のリファクタリングで意図しない変更を検出する。

## Scope

- ログ追加、一時停止、全削除
- タグ収集とファイル・関数別グループ
- 現在の検索・タグフィルター仕様
- iOS Simulatorで再現可能なテストコマンド
- GitHub Actionsへ移植可能なローカル検証スクリプト

## Acceptance criteria

- [x] 空のサンプルテストが実テストへ置き換わっている
- [x] 主要な現行仕様にテストがある
- [x] 失敗時に原因が分かるテスト名になっている
- [x] ビルドとテストを1つの文書化された手順で実行できる
- [ ] 最低対応stable版Xcodeで検証している

## Verification

- 対象Simulatorで全テストが成功する
- 意図的に実装を壊すと対応テストが失敗する

## Verification result

- `./Scripts/verify.sh`: 成功
- Manifest解析: 成功
- iOS 18.0 Deployment Target build: 成功
- iPhone 16 / iOS 18.0 Simulator tests: 成功

Xcode 26 stableでの検証は未完了。Hosted CI workflowは将来追加し、
ローカル検証と同じコマンドを利用する。
