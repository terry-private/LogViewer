# ``LogViewerSwiftLog``

既存のSwiftLog呼び出しをLogViewerの保存機能へ接続する。

## Overview

SwiftLogの最初のbootstrapで``LogViewerLogHandler``を設定し、ログ画面と同じ
`LogStore`へ渡す。既存Backendと併用する場合は`MultiplexLogHandler`を使う。
Handlerは受け取った出来事を1回だけ保存し、SwiftLogへ再送しない。

## Topics

### 接続

- ``LogViewerLogHandler``
