---
id: LV-008
github_issue: 10
title: "Present LogViewer in a scene-aware dedicated UIWindow"
status: blocked
labels: [enhancement, architecture, ui]
depends_on: [LV-004, LV-006]
---

## Goal

SheetやFullScreenCoverと競合せず、現在のSceneの最前面へLogViewerを表示する。

## Scope

- `LogViewerWindowPresenter`
- `UIHostingController`によるSwiftUI表示
- 呼び出し元Viewに属する`UIWindowScene`の取得
- SceneごとのWindow管理
- Key Windowの保存と復元
- `.overlay`と`.window`のPresentation設定

## Acceptance criteria

- [ ] Sheet表示中でもViewerがその上へ表示される
- [ ] 複数Sceneで呼び出し元のSceneだけに表示される
- [ ] 連続表示でWindowが重複しない
- [ ] 検索欄でキーボード入力できる
- [ ] 閉じた後に元のKey Windowと入力状態が適切に復元される
- [ ] Window解放後に保持サイクルがない

## Verification

- 通常画面、Sheet、FullScreenCover、Alert表示中のケースを確認する
- 2つのSceneを開いて独立動作を確認する
