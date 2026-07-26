# 中核機能と画面機能のターゲット分割

## 背景

ログ型、保存、絞り込みと、SwiftUI／UIKitによる表示が同じターゲットにあり、
中核機能だけをビルド・テスト・再利用できなかった。一方、既存の利用側は
`LogViewer`製品と`import LogViewer`に依存している。

## 決定

パッケージ内部を次の一方向依存に分割する。

```text
LogViewer → LogViewerUI → LogViewerCore
          ↘ LogViewerCore
```

- `LogViewerCore`: ログ型、保存、絞り込み
- `LogViewerUI`: SwiftUI／UIKit表示
- `LogViewer`: 中核と画面を再公開する互換入口

プレビュー専用データは`LogViewerUI/Preview`へ置き、公開用の中核コードへ
含めない。ターゲット間だけで必要な型と処理には`package`可視性を使い、
新しい公開APIにはしない。

## 採用理由

- 中核ターゲットからSwiftUI／UIKit依存を除ける
- 中核テストと画面テストの責務が明確になる
- 既存の`import LogViewer`を変更せずに移行できる
- 公開ログモデルの再設計を後続課題へ分離できる

## 採用しなかった方式

- 既存の`LogViewer`ターゲットをそのまま画面ターゲットにする方式:
  `LogViewerUI`という責務が明確にならず、中核と画面の個別利用を表現しにくい。
- 画面ターゲットを単独製品としてすぐに公開する方式:
  通常利用は互換入口で足り、公開製品を増やす利点がまだないため見送る。
- 大規模な層構造や依存性注入を同時に導入する方式:
  公開モデルと保存機能の再設計は後続課題の範囲であり、今回の分割には不要。

## 影響

- 新しい内部ターゲット名とテストターゲット名が追加される
- `LogViewerCore`はiOS／iPadOS向けの単独製品として利用できる
- `LogViewerUI`から`LogViewerCore`への一方向依存になる
- 既存の`LogViewer`製品と公開APIの利用方法は維持される
- 他プラットフォーム対応を宣言するには、別途ビルドとテストが必要になる

## 関連情報

- [GitHub課題第5号](https://github.com/terry-private/LogViewer/issues/5)
