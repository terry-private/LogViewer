---
id: LV-006
github_issue: 7
title: "Implement a thread-safe LogStore with dependency injection"
status: blocked
labels: [architecture, concurrency]
depends_on: [LV-005]
---

## Goal

ネットワーク処理やTaskなど、任意の実行コンテキストから安全にログを記録できるようにする。

## Scope

- `LogStoreProtocol`または同等の抽象
- スレッドセーフなStore実装
- UIへ変更を通知する仕組み
- `shared`の便利APIを残しつつ、Store注入へ対応
- 一時停止と削除の並行実行仕様

## Acceptance criteria

- [ ] 呼び出し元をMainActorへ強制しない
- [ ] 複数Taskから同時追加しても欠落・破損しない
- [ ] ViewerごとにStoreを差し替えられる
- [ ] `shared`利用とDI利用の両方にサンプルテストがある
- [ ] Swift 6のConcurrency警告がない
