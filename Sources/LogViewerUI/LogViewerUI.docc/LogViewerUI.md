# ``LogViewerUI``

SwiftUIアプリの現在の場面へ、検索・絞り込み・共有機能を備えたログ画面を表示する。

## Overview

Viewへ``SwiftUICore/View/logViewer(on:presentation:store:privacyPolicy:isTransparent:)``を
適用する。シートや全画面表示より前面へ出す場合は
``LogViewerPresentationStyle/window``を選ぶ。シェイクを使えない環境では
``ShowTrigger/custom(_:)``を使って明示操作を提供する。

## Topics

### 表示

- ``ShowTrigger``
- ``LogViewerPresentationStyle``
- ``SwiftUICore/View/logViewer(on:presentation:store:privacyPolicy:isTransparent:)``

### シェイク通知

- ``LogViewerShakeNotification``
- ``Foundation/NSNotification/Name/deviceDidShakeNotification``
