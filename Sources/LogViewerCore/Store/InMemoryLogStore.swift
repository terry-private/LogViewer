import DequeModule
import Foundation
import Synchronization

/// プロセス内でログを保持する、スレッド安全な保存機能。
public final class InMemoryLogStore: LogStore, Sendable {
    private struct State {
        var entries: Deque<LogEntry> = []
        var isRecordingEnabled: Bool
        var continuations: [
            UUID: AsyncStream<LogStoreSnapshot>.Continuation
        ] = [:]

        var snapshot: LogStoreSnapshot {
            LogStoreSnapshot(
                entries: Array(entries),
                isRecordingEnabled: isRecordingEnabled
            )
        }
    }

    /// 標準で保持する最大ログ件数。
    public static let defaultMaximumEntryCount = 10_000

    /// この保存機能が保持する最大ログ件数。
    public let maximumEntryCount: Int
    /// 保存前に適用する秘匿化方針。
    public let privacyPolicy: LogPrivacyPolicy

    private let state: Mutex<State>

    /// 最大件数と初期記録状態を指定して、空の保存機能を作成する。
    public init(
        maximumEntryCount: Int = defaultMaximumEntryCount,
        isRecordingEnabled: Bool = true,
        privacyPolicy: LogPrivacyPolicy = .none
    ) {
        precondition(
            maximumEntryCount >= 0,
            "maximumEntryCount must not be negative"
        )
        self.maximumEntryCount = maximumEntryCount
        self.privacyPolicy = privacyPolicy
        state = Mutex(
            State(isRecordingEnabled: isRecordingEnabled)
        )
    }

    deinit {
        let continuations = state.withLock { state in
            let continuations = Array(state.continuations.values)
            state.continuations.removeAll()
            return continuations
        }
        for continuation in continuations {
            continuation.finish()
        }
    }

    var updateSubscriberCount: Int {
        state.withLock { state in
            state.continuations.count
        }
    }

    public func snapshot() -> LogStoreSnapshot {
        state.withLock { state in
            state.snapshot
        }
    }

    public func updates() -> AsyncStream<LogStoreSnapshot> {
        let id = UUID()
        let (stream, continuation) = AsyncStream.makeStream(
            of: LogStoreSnapshot.self,
            bufferingPolicy: .bufferingNewest(1)
        )
        continuation.onTermination = { [weak self] _ in
            self?.removeContinuation(id: id)
        }
        state.withLock { state in
            state.continuations[id] = continuation
            if case .terminated = continuation.yield(state.snapshot) {
                state.continuations.removeValue(forKey: id)
            }
        }
        return stream
    }

    public func add(_ entry: LogEntry) {
        let acceptsEntry = state.withLock { state in
            state.isRecordingEnabled && maximumEntryCount > 0
        }
        guard acceptsEntry else { return }
        let entry = privacyPolicy.redacting(entry)
        mutate { state in
            guard state.isRecordingEnabled else { return false }
            guard maximumEntryCount > 0 else { return false }
            state.entries.append(entry)
            while state.entries.count > maximumEntryCount {
                state.entries.removeFirst()
            }
            return true
        }
    }

    public func setRecordingEnabled(_ isEnabled: Bool) {
        mutate { state in
            guard state.isRecordingEnabled != isEnabled else {
                return false
            }
            state.isRecordingEnabled = isEnabled
            return true
        }
    }

    public func deleteAll() {
        mutate { state in
            guard !state.entries.isEmpty else { return false }
            state.entries.removeAll()
            return true
        }
    }

    private func mutate(
        _ mutation: (inout State) -> Bool
    ) {
        state.withLock { state in
            guard mutation(&state) else { return }
            guard !state.continuations.isEmpty else { return }
            let snapshot = state.snapshot
            var terminatedIDs: [UUID] = []
            for (id, continuation) in state.continuations {
                if case .terminated = continuation.yield(snapshot) {
                    terminatedIDs.append(id)
                }
            }
            for id in terminatedIDs {
                state.continuations.removeValue(forKey: id)
            }
        }
    }

    private func removeContinuation(id: UUID) {
        _ = state.withLock { state in
            state.continuations.removeValue(forKey: id)
        }
    }
}
