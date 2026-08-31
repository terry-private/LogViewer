# JSON書き出し形式

バージョン1の``LogExportFormat/json``は、`LogEntry`のJSON配列をUTF-8で出力する。

各要素の形式は次のとおり。`category`が`nil`の場合はキー自体を省略し、
それ以外のフィールドは必須である。

| フィールド | JSON型と意味 |
| --- | --- |
| `id` | UUID文字列 |
| `level` | `trace`から`critical`に対応する整数`0...6` |
| `message` | 文字列 |
| `source` | `fileID`と`function`の文字列、`line`の非負整数を持つobject |
| `category` | 任意の文字列。値がない場合はキーを省略 |
| `tags` | 文字列の配列 |
| `metadata` | 文字列をキーと値に持つobject |
| `timestamp` | ミリ秒を含むISO 8601文字列 |

```json
[
  {
    "category": "network",
    "id": "00000000-0000-0000-0000-000000000014",
    "level": 5,
    "message": "Request failed",
    "metadata": { "request-id": "42" },
    "source": {
      "fileID": "API.swift",
      "function": "send()",
      "line": 42
    },
    "tags": ["api", "error"],
    "timestamp": "1970-01-01T00:16:40.125Z"
  }
]
```

1.xでは既存フィールドの意味と型を維持する。読み取り側は将来追加される未知の
フィールドを無視すること。必須フィールドの削除、型変更、配列以外への最上位形式の
変更は次のメジャーバージョンでのみ行う。共有前には``LogPrivacyPolicy``を適用し、
秘密値を含む未保護のJSONを外部へ渡さないこと。
