import Foundation
import Synchronization

/// プロセス内でログを保持する、スレッド安全な保存機能。
public final class InMemoryLogStore: LogStore, Sendable {
    private struct State {
        var entries: [LogEntry] = []
        var isRecordingEnabled: Bool
        var continuations: [
            UUID: AsyncStream<LogStoreSnapshot>.Continuation
        ] = [:]

        var snapshot: LogStoreSnapshot {
            LogStoreSnapshot(
                entries: entries,
                isRecordingEnabled: isRecordingEnabled
            )
        }
    }

    private let state: Mutex<State>

    /// 空の保存機能を作成する。
    public init(isRecordingEnabled: Bool = true) {
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
        mutate { state in
            guard state.isRecordingEnabled else { return false }
            state.entries.append(entry)
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
