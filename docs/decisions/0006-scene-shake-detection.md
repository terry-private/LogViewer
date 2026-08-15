# 場面単位のシェイク検知

## 背景

`UIWindow.motionEnded`をextensionで上書きすると、LogViewerを導入しただけで
アプリ内のすべての`UIWindow`の動作が変わる。複数の`UIWindowScene`がある場合、
アプリ全体への通知を各場面が受け取り、振っていない場面まで表示される可能性もある。
通知のたびに表示状態を反転すると、重複イベントがログ画面を閉じる問題もある。

## 決定

`.logViewer(on: .shake)`を設定したSwiftUI Viewの背面へ、操作を遮らない小さな
`UIViewRepresentable`を配置する。そのViewだけがFirst Responderとして
`motionEnded`を受け取り、所属する`UIWindowScene`のLogViewerを表示する。

検知Viewは`super.motionEnded`を必ず呼び、アプリ側のResponder chainを止めない。
ウインドウがキーになった時とキーボードが閉じた時に、必要ならResponderへ戻る。
シェイク時の状態遷移は反転ではなく常に表示へ収束させ、重複イベントで閉じない。

既存の`deviceDidShakeNotification`は互換性のため維持し、通知の`object`も
従来どおり`UIEvent?`とする。シェイクを受け取った`UIWindowScene`は
`LogViewerShakeNotification.windowSceneUserInfoKey`を使って`userInfo`から
取得できる。ただし発火範囲はアプリ全体の`UIWindow`から、`.shake`を設定した
Viewの所属場面へ狭まる。LogViewer自身は場面に結び付いた直接のコールバックで
表示する。

## 採用理由

- UIKitの型全体へ動作を追加せず、修飾したViewの範囲へ限定できる
- 検知Viewが属するウインドウから表示対象の場面が決定する
- `super`を通すため、導入アプリ独自のResponder処理を妨げない
- 同じイベントが重なっても表示状態を閉じる方向へ変えない

## 採用しなかった方式

- `UIWindow.motionEnded`をextensionで上書きする方式:
  導入アプリのすべてのウインドウへ影響するため採用しない。
- アプリ全体の通知だけで表示先を決める方式:
  複数場面で呼び出し元を一意に決められないため採用しない。
- シェイクのたびに表示状態を反転する方式:
  重複イベントで開いた直後に閉じる可能性があるため採用しない。

## 影響

- 既存の`.logViewer(on: .shake)`の呼び出し方は変わらない
- シミュレーターやシェイク非対応環境では`.custom`を代替導線として使う
- テキスト入力終了後は検知ViewがFirst Responderへ戻る

## 関連情報

- [GitHub課題第11号](https://github.com/terry-private/LogViewer/issues/11)
- 実端末のシェイク、複数Scene、導入アプリ独自の動作検知との共存は
  [GitHub課題第15号](https://github.com/terry-private/LogViewer/issues/15)の
  アプリホストE2Eで検証する
