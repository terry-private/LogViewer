import Foundation

enum LogViewerStringKey: String, CaseIterable {
    case accessibilityClearSearch = "accessibility.clear_search"
    case accessibilityClose = "accessibility.close"
    case accessibilityCollapsed = "accessibility.collapsed"
    case accessibilityExpanded = "accessibility.expanded"
    case accessibilityMoreActions = "accessibility.more_actions"
    case accessibilityScrollToBottom = "accessibility.scroll_to_bottom"
    case commonCancel = "common.cancel"
    case commonOK = "common.ok"
    case emptyNoLogs = "empty.no_logs"
    case emptyNoMatches = "empty.no_matches"
    case filterClear = "filter.clear"
    case filterMatchAll = "filter.match.all"
    case filterMatchAny = "filter.match.any"
    case filterPeriodAll = "filter.period.all"
    case filterPeriodLast24Hours = "filter.period.last_24_hours"
    case filterPeriodLast5Minutes = "filter.period.last_5_minutes"
    case filterPeriodLastHour = "filter.period.last_hour"
    case filterResultCountOne = "filter.result_count.one"
    case filterResultCountOther = "filter.result_count.other"
    case filterSearchPlaceholder = "filter.search.placeholder"
    case filterTags = "filter.tags"
    case filterTagsAll = "filter.tags.all"
    case filterTagsAny = "filter.tags.any"
    case groupingAll = "grouping.all"
    case groupingFile = "grouping.file"
    case groupingFunction = "grouping.function"
    case groupingLabel = "grouping.label"
    case levelCritical = "level.critical"
    case levelDebug = "level.debug"
    case levelError = "level.error"
    case levelInfo = "level.info"
    case levelNotice = "level.notice"
    case levelTrace = "level.trace"
    case levelWarning = "level.warning"
    case logsDeleteAction = "logs.delete.action"
    case logsDeleteMessage = "logs.delete.message"
    case logsDeleteTitle = "logs.delete.title"
    case logsCopyFiltered = "logs.copy_filtered"
    case logsExportErrorMessage = "logs.export_error.message"
    case logsExportErrorTitle = "logs.export_error.title"
    case logsShareJSON = "logs.share_json"
    case logsShareText = "logs.share_text"
    case recordingPause = "recording.pause"
    case recordingPaused = "recording.paused"
    case recordingResume = "recording.resume"
    case settingsTransparentBackground = "settings.transparent_background"
}

enum LogViewerLocalization {
    static func string(
        _ key: LogViewerStringKey,
        locale: Locale = .current
    ) -> String {
        let languageCode = locale.language.languageCode?.identifier
        let localizationBundle = languageCode.flatMap {
            Bundle.module.path(forResource: $0, ofType: "lproj")
        }.flatMap(Bundle.init(path:)) ?? .module
        return localizationBundle.localizedString(
            forKey: key.rawValue,
            value: nil,
            table: nil
        )
    }

    static func resultCount(
        _ resultCount: Int,
        totalCount: Int,
        locale: Locale = .current
    ) -> String {
        let key: LogViewerStringKey = totalCount == 1
            ? .filterResultCountOne
            : .filterResultCountOther
        return String(
            format: string(key, locale: locale),
            locale: locale,
            Int64(resultCount),
            Int64(totalCount)
        )
    }
}
