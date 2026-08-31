# LogViewerSample

リポジトリ直下のローカルSwift Packageを参照するiOS／iPadOSサンプルアプリ。

## 起動

1. `LogViewerSample.xcodeproj`をXcodeで開く
2. `LogViewerSample`スキームを選ぶ
3. iOS 18以降のiPhoneまたはiPad、実端末で実行する

サンプルには次の導線がある。

- 任意ボタンと物理シェイクによる専用ウインドウ表示
- シート、全画面、警告より前面での表示
- 元画面とLogViewerの検索欄への実キーボード入力
- 場面ごとに異なるStoreと識別ログを持つ別ウインドウ
- 保存前秘匿化済みログの絞り込みとコピー内容確認
- 場面単位で受信したシェイク通知のカウンタ

## 自動E2E

```bash
./Scripts/verify-sample.sh
```

特定のiPad Simulatorを使う場合は次のように指定する。

```bash
LOGVIEWER_SAMPLE_DESTINATION='platform=iOS Simulator,name=iPad (10th generation),OS=18.0' \
  ./Scripts/verify-sample.sh
```

自動テストはwindow前面、検索入力、元入力欄の復帰、日英最大文字、停止・再開、
削除確認、保護済みの絞り込み結果コピー、別場面の作成を確認する。

物理シェイク、実VoiceOver、外部アプリへのテキスト／JSON共有はOSと実端末の
操作が必要なため、[公開手順の実端末手動チェック](../../docs/RELEASING.md#実端末手動チェック)
に従う。

`project.yml`を変更した場合はXcodeGenでプロジェクトを再生成し、生成された
`.xcodeproj`も同じ変更へ含める。

```bash
xcodegen generate --spec Examples/LogViewerSample/project.yml
```
