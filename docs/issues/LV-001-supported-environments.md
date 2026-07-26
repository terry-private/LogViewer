---
id: LV-001
github_issue: 2
title: "Define supported iOS, Swift, and Xcode versions"
status: in-progress
labels: [maintenance, documentation]
depends_on: []
---

## Goal

利用側が必要な環境を正しく判断でき、同じ条件で継続検証できるようにする。

## Scope

- 最低iOSバージョンを決定する
- Swift tools versionとXcode要件を整合させる
- iOS専用か、CoreのみmacOS対応するかを決定する
- Debug用ライブラリとしての対応方針を明記する

## Acceptance criteria

- [x] `Package.swift`とREADMEの要件が一致している
- [ ] 最低対応stable版Xcodeで実際に検証している
- [x] 対応外プラットフォームの扱いが明記されている
- [x] ローカル検証用のビルドコマンドが記録されている

## Verification

- `xcodebuild`で最低Deployment Target向けにビルドする
- `swift package dump-package`が成功する

## Decision

- iOS / iPadOS 18.0以上
- Xcode 26.0以上のstable版
- Swift tools 6.2、Swift 6 language mode
- 現在の正式対応はiOS / iPadOSのみ
- Debug、開発、TestFlightなどの内部利用を主用途とする

Core分割後に、より古いiOSや他プラットフォームへ対応範囲を広げるか再評価する。

## Verification result

- `swift package dump-package`: 成功
- iOS Simulator、Deployment Target 18.0のbuild: 成功
- 実行環境: Xcode 27.0 beta / Swift 6.4

最低対応stable版であるXcode 26での実検証は未完了。Issue #3とPR #16で
追跡し、mainへのマージ前に結果を記録する。
