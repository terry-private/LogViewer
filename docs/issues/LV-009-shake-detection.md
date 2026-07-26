---
id: LV-009
github_issue: 11
title: "Replace the global UIWindow motion override with scene-local shake detection"
status: blocked
labels: [bug, architecture, ui]
depends_on: [LV-008]
---

## Goal

導入アプリの`UIWindow`実装と競合せず、揺らしたSceneだけでViewerを開く。

## Scope

- `UIWindow.motionEnded`のグローバルoverride廃止
- Scene/Viewに紐づくResponderによるShake検知
- `.custom`トリガーとの共通Presenter利用
- SimulatorやShake非対応環境の代替導線

## Acceptance criteria

- [ ] UIKit型へグローバルoverrideを追加していない
- [ ] ShakeしたSceneだけでViewerが開く
- [ ] 導入アプリ独自のmotion処理を妨げない
- [ ] `.custom`表示が引き続き利用できる
- [ ] 重複イベントで表示状態が反転しない
