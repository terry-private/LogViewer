# 貢献手引き

## 作業の始め方

1. GitHub Issueで目的、完了条件、依存関係を確認する
2. `main`から作業ブランチを作成する
3. 公開APIの変更は文書コメント、DocC、READMEまたはMIGRATION、テストを同時に更新する
4. 進捗と完了条件はGitHub Issueだけで管理し、`docs/issues`へ複製しない

## ローカル検証

```bash
./Scripts/verify.sh
./Scripts/verify-docs.sh
./Scripts/verify-sample.sh
```

特定のSimulatorを使う場合は`LOGVIEWER_TEST_DESTINATION`と
`LOGVIEWER_SAMPLE_DESTINATION`を指定する。最低対応のXcode 26安定版による検証は
GitHub Actionsでも実行する。

## Pull Request

- タイトルと本文は日本語で、変更理由、利用者への影響、検証結果を書く
- 新しい依存を中核ターゲットへ追加するときは責務分離への影響を書く
- 公開APIを削除・変更するときはセマンティックバージョニング方針と移行手順を書く
- サブエージェントまたは別の確認者による実装・テスト・文書レビューを行う
- CIとレビューが成功するまではDraftとして扱う

## 文書の正本

文書ごとの役割とSSOTは[ドキュメント方針](docs/README.md)に従う。
利用者向けの版ごとの変更は[変更履歴](CHANGELOG.md)へ集約する。
