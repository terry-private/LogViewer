# ADR 0011: バージョン1の配布と互換性基準

## 背景

バージョン1を公開すると、公開API、JSON書き出し形式、導入方法を1.xの間に
安定して維持する必要がある。互換入口は従来の`import LogViewer`を守るため、
中核機能と画面機能を再公開している。

## 決定

- `LogViewer`製品は`@_exported import`による互換入口を1.xで維持する
- 詳細APIはソース文書コメントと各ターゲットのDocCを正本にする
- `CHANGELOG.md`を版ごとの変更の正本とし、GitHub Releaseは要約とリンクを持つ
- JSON v1は`LogEntry`配列と8つの既存フィールドの意味・型を1.xで維持する
- 1.0.0をAPI互換性診断の基準タグとし、以後は直前の安定版タグとの差分を確認する
- タグ前に最低対応Xcode 26.2のCI、サンプルE2E、実端末手動チェックを完了する

## 採用理由

- 既存の`import LogViewer`利用側を移行なしで維持できる
- README、DocC、変更履歴、Releaseの役割が重複しない
- 自動検証できる境界と、物理端末・VoiceOver・共有先でのみ確認できる境界を分けられる

## 採用しなかった方式

- GitHub Releaseだけを変更履歴の正本にする方式:
  ソースと同じ版管理でレビューできず、公開前の内容も参照しにくい。
- OSLog履歴やサンプル用hookで物理シェイクE2Eを代用する方式:
  実際のResponder、場面、端末イベントを検証できない。
- 1.xのminor更新でJSONの必須フィールドを変更する方式:
  保存済み調査データと外部利用側を壊す。

## 互換性と保守への影響

underscoredな`@_exported import`はXcode 26.2と継続CIで利用側コンパイルを固定する。
将来この方式を置き換える場合は、MIGRATIONへ代替importと移行期間を記載する。
JSONへフィールドを追加する場合は任意項目とし、旧読み取り側が未知項目を無視できる
ことを確認する。

## 関連

- [GitHub課題第15号](https://github.com/terry-private/LogViewer/issues/15)
- [公開手順](../RELEASING.md)
- [変更履歴](../../CHANGELOG.md)
