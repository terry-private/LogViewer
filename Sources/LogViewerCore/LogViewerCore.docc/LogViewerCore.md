# ``LogViewerCore``

アプリの任意の実行環境からログを安全に記録し、保持、秘匿化、書き出しを行う。

## Overview

``Logger``へ追加した``LogEntry``は``LogStore``へ保存される。標準の
``InMemoryLogStore``はスレッド安全で、保持上限と保存前の``LogPrivacyPolicy``を
設定できる。画面を使わない処理は`LogViewerCore`製品だけを導入できる。

## Topics

### ログモデル

- ``LogEntry``
- ``LogLevel``
- ``SourceLocation``
- ``Tag``

### 記録と保存

- ``Logger``
- ``LogStore``
- ``InMemoryLogStore``
- ``LogStoreSnapshot``

### 秘匿化と書き出し

- ``LogPrivacyPolicy``
- ``LogRedactionRule``
- ``LogExporter``
- ``LogExportFormat``
- <doc:JSON-Format-v1>
