# LogViewer local issue backlog

GitHubへ接続できない期間も作業を進められるように、Issueを1件1ファイルで管理する。
各ファイルは、そのままGitHub Issueの本文へ移せる粒度にする。

## Status

- `ready`: 着手可能
- `blocked`: 依存Issueの完了待ち
- `in-progress`: 作業中
- `done`: ローカルで受け入れ条件を満たした
- `published`: GitHub Issueへ移行済み

## Recommended order

| ID | GitHub | Title | Depends on | Status |
| --- | --- | --- | --- | --- |
| LV-000 | [#1](https://github.com/terry-private/LogViewer/issues/1) | v1.0 reusable foundation | - | ready |
| LV-001 | [#2](https://github.com/terry-private/LogViewer/issues/2) | supported environments and build matrix | - | done |
| LV-002 | [#3](https://github.com/terry-private/LogViewer/issues/3) | characterization tests and CI-ready commands | LV-001 | done |
| LV-003 | [#4](https://github.com/terry-private/LogViewer/issues/4) | public API and documentation correctness | LV-002 | in-progress |
| LV-004 | [#5](https://github.com/terry-private/LogViewer/issues/5) | split Core and UI targets | LV-002 | blocked |
| LV-005 | [#6](https://github.com/terry-private/LogViewer/issues/6) | public log model and compatibility API | LV-004 | blocked |
| LV-006 | [#7](https://github.com/terry-private/LogViewer/issues/7) | thread-safe store and dependency injection | LV-005 | blocked |
| LV-007 | [#8](https://github.com/terry-private/LogViewer/issues/8) | retention policy and performance | LV-006 | blocked |
| LV-008 | [#10](https://github.com/terry-private/LogViewer/issues/10) | scene-aware UIWindow presentation | LV-004, LV-006 | blocked |
| LV-009 | [#11](https://github.com/terry-private/LogViewer/issues/11) | scene-local shake detection | LV-008 | blocked |
| LV-010 | [#9](https://github.com/terry-private/LogViewer/issues/9) | composable filtering and search | LV-005, LV-007 | blocked |
| LV-011 | [#13](https://github.com/terry-private/LogViewer/issues/13) | privacy, redaction, and export | LV-005, LV-006 | blocked |
| LV-012 | [#12](https://github.com/terry-private/LogViewer/issues/12) | localization and accessibility | LV-008, LV-010 | blocked |
| LV-013 | [#14](https://github.com/terry-private/LogViewer/issues/14) | logging adapters | LV-005, LV-006 | blocked |
| LV-014 | [#15](https://github.com/terry-private/LogViewer/issues/15) | sample, DocC, and v1.0 release preparation | LV-003...LV-013 | blocked |

`LV-008`の専用Window対応は、Sheetとの競合を避けるための正式な表示方式として扱う。
ただし再設計の手戻りを避けるため、Core/UI分割とStore注入の後に実装する。

## Working locally

1. 着手するIssueのFront Matterを`in-progress`へ変更する。
2. Issueに記載された範囲だけを実装する。
3. Verificationを実行する。
4. Acceptance criteriaを満たしたら`done`へ変更する。
5. 次のIssueの依存条件が解消されたら`ready`へ変更する。

## Publishing later

GitHub CLIの認証復旧後、各ファイルを次の形で移行できる。

```bash
gh issue create \
  -R terry-private/LogViewer \
  --title "<front matterのtitle>" \
  --body-file docs/issues/LV-001-supported-environments.md
```

公開前に既存Issueとの重複を確認し、GitHub上のIssue番号をこのREADMEへ追記する。
