import Foundation

enum SampleText {
    static var isJapanese: Bool {
        Locale.preferredLanguages.first?.hasPrefix("ja") == true
    }

    static func localized(_ japanese: String, _ english: String) -> String {
        isJapanese ? japanese : english
    }

    static var title: String { localized("動作確認サンプル", "Verification Sample") }
    static var scene: String { localized("場面", "Scene") }
    static var sceneShakeCount: String { localized("シェイク受信回数", "Scene shake count") }
    static var hostInput: String { localized("元画面の入力欄", "Host input") }
    static var showLogs: String { localized("ログを表示", "Show logs") }
    static var showSheet: String { localized("シートを表示", "Show sheet") }
    static var showFullScreen: String { localized("全画面を表示", "Show full screen") }
    static var showAlert: String { localized("警告上でログを表示", "Show logs over alert") }
    static var openSecondScene: String { localized("別の場面を開く", "Open another scene") }
    static var inspectClipboard: String { localized("コピー内容を確認", "Inspect copied text") }
    static var sheetTitle: String { localized("シート", "Sheet") }
    static var fullScreenTitle: String { localized("全画面", "Full screen") }
    static var alertTitle: String { localized("警告を表示中", "Alert is presented") }
    static var close: String { localized("閉じる", "Close") }
    static var secondaryWindow: String { localized("別の場面", "Secondary Scene") }
}
