import Testing
@testable import LogViewerCore

@Suite("スレッド安全なログ保存機能")
struct InMemoryLogStoreTests {
    @Test("標準の最大保持件数は1万件")
    func defaultMaximumEntryCountIsTenThousand() {
        let store = InMemoryLogStore()

        #expect(InMemoryLogStore.defaultMaximumEntryCount == 10_000)
        #expect(store.maximumEntryCount == 10_000)
    }

    @Test("上限を超えると先に追加したログから削除する")
    func retentionRemovesOldestInsertedEntries() {
        let store = InMemoryLogStore(maximumEntryCount: 3)

        for index in 1...5 {
            store.add(makeEntry(message: String(index)))
        }

        #expect(
            store.snapshot().entries.map(\.message) == ["3", "4", "5"]
        )
    }

    @Test("最大保持件数を0にするとログを保持しない")
    func zeroMaximumEntryCountKeepsNoEntries() {
        let store = InMemoryLogStore(maximumEntryCount: 0)

        store.add(makeEntry(message: "ignored"))

        #expect(store.snapshot().entries.isEmpty)
    }

    @Test(
        "2万件追加後に最新1万件を保持する",
        .timeLimit(.minutes(1))
    )
    func twentyThousandEntriesMeetBaseline() {
        let store = InMemoryLogStore(maximumEntryCount: 10_000)

        for index in 0..<20_000 {
            store.add(makeEntry(message: String(index)))
        }

        let entries = store.snapshot().entries
        #expect(
            entries.map(\.message)
                == (10_000..<20_000).map(String.init)
        )
    }

    @Test(
        "変更ストリームがすべての状態変更を複数購読者へ通知する",
        .timeLimit(.minutes(1))
    )
    func updatesYieldEveryChangedSnapshot() async {
        let store = InMemoryLogStore()
        var firstIterator = store.updates().makeAsyncIterator()
        var secondIterator = store.updates().makeAsyncIterator()
        let entry = makeEntry(message: "added")

        let expectedInitial = LogStoreSnapshot(
            entries: [],
            isRecordingEnabled: true
        )
        #expect(await firstIterator.next() == expectedInitial)
        #expect(await secondIterator.next() == expectedInitial)

        store.add(entry)
        let expectedAdded = LogStoreSnapshot(
            entries: [entry],
            isRecordingEnabled: true
        )
        #expect(await firstIterator.next() == expectedAdded)
        #expect(await secondIterator.next() == expectedAdded)

        store.setRecordingEnabled(false)
        let expectedPaused = LogStoreSnapshot(
            entries: [entry],
            isRecordingEnabled: false
        )
        #expect(await firstIterator.next() == expectedPaused)
        #expect(await secondIterator.next() == expectedPaused)

        store.setRecordingEnabled(true)
        let expectedResumed = LogStoreSnapshot(
            entries: [entry],
            isRecordingEnabled: true
        )
        #expect(await firstIterator.next() == expectedResumed)
        #expect(await secondIterator.next() == expectedResumed)

        store.deleteAll()
        let expectedDeleted = LogStoreSnapshot(
            entries: [],
            isRecordingEnabled: true
        )
        #expect(await firstIterator.next() == expectedDeleted)
        #expect(await secondIterator.next() == expectedDeleted)
    }

    @Test("複数タスクからの同時追加をすべて保持する")
    func concurrentAddsKeepEveryEntry() async {
        let store = InMemoryLogStore()
        let count = 500

        await withTaskGroup(of: Void.self) { group in
            for index in 0..<count {
                group.addTask {
                    store.add(
                        self.makeEntry(message: String(index))
                    )
                }
            }
        }

        let snapshot = store.snapshot()
        #expect(snapshot.entries.count == count)
        #expect(
            Set(snapshot.entries.map(\.message))
                == Set((0..<count).map(String.init))
        )
    }

    @Test("一時停止中の追加を破棄し再開後の追加を保持する")
    func pauseAndResumeDefineRecordingBoundary() {
        let store = InMemoryLogStore()

        store.setRecordingEnabled(false)
        store.add(makeEntry(message: "paused"))
        store.setRecordingEnabled(true)
        store.add(makeEntry(message: "resumed"))

        let snapshot = store.snapshot()
        #expect(snapshot.isRecordingEnabled)
        #expect(snapshot.entries.map(\.message) == ["resumed"])
    }

    @Test("削除以前のログを消し削除後のログを保持する")
    func deleteDefinesRemovalBoundary() {
        let store = InMemoryLogStore()
        store.add(makeEntry(message: "before"))

        store.deleteAll()
        store.add(makeEntry(message: "after"))

        #expect(
            store.snapshot().entries.map(\.message) == ["after"]
        )
    }

    @Test("追加と停止の並行実行をどちらかの順序で確定する")
    func concurrentAddAndPauseAreLinearized() async {
        for _ in 0..<100 {
            let store = InMemoryLogStore()

            await withTaskGroup(of: Void.self) { group in
                group.addTask {
                    store.add(self.makeEntry(message: "entry"))
                }
                group.addTask {
                    store.setRecordingEnabled(false)
                }
            }

            let snapshot = store.snapshot()
            #expect(!snapshot.isRecordingEnabled)
            #expect(
                snapshot.entries.isEmpty
                    || snapshot.entries.map(\.message) == ["entry"]
            )
        }
    }

    @Test("追加と削除の並行実行をどちらかの順序で確定する")
    func concurrentAddAndDeleteAreLinearized() async {
        for _ in 0..<100 {
            let store = InMemoryLogStore()
            store.add(makeEntry(message: "before"))

            await withTaskGroup(of: Void.self) { group in
                group.addTask {
                    store.add(self.makeEntry(message: "after"))
                }
                group.addTask {
                    store.deleteAll()
                }
            }

            let messages = store.snapshot().entries.map(\.message)
            #expect(messages.isEmpty || messages == ["after"])
        }
    }

    @Test("停止状態で初期化できる")
    func initializesPaused() {
        let store = InMemoryLogStore(isRecordingEnabled: false)

        store.add(makeEntry(message: "ignored"))

        #expect(
            store.snapshot() == LogStoreSnapshot(
                entries: [],
                isRecordingEnabled: false
            )
        )
    }

    @Test(
        "保存機能の破棄時に変更ストリームを終了する",
        .timeLimit(.minutes(1))
    )
    func deinitFinishesUpdateStream() async {
        var store: InMemoryLogStore? = InMemoryLogStore()
        weak let weakStore = store
        var iterator = store!.updates().makeAsyncIterator()

        #expect(await iterator.next() != nil)
        store = nil

        #expect(weakStore == nil)
        #expect(await iterator.next() == nil)
    }

    @Test(
        "購読Taskのキャンセル時に購読を解除する",
        .timeLimit(.minutes(1))
    )
    func cancellationRemovesUpdateSubscriber() async {
        let store = InMemoryLogStore()
        let task = Task {
            for await _ in store.updates() {}
        }
        await waitUntil {
            store.updateSubscriberCount == 1
        }
        #expect(store.updateSubscriberCount == 1)

        task.cancel()
        await task.value

        #expect(store.updateSubscriberCount == 0)
    }

    private func waitUntil(
        _ condition: () -> Bool
    ) async {
        let clock = ContinuousClock()
        let deadline = clock.now.advanced(by: .seconds(1))
        while !condition(), clock.now < deadline {
            await Task.yield()
        }
    }

    private nonisolated func makeEntry(message: String) -> LogEntry {
        LogEntry(
            message: message,
            source: SourceLocation(
                fileID: "Test.swift",
                function: "run()",
                line: 1
            )
        )
    }
}
