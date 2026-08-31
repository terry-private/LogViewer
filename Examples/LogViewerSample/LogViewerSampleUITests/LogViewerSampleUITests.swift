import XCTest

@MainActor
final class LogViewerSampleUITests: XCTestCase {
    private var app: XCUIApplication!

    func testWindowPresentationSearchAndKeyRestorationFromSheet() {
        launch(language: "en")
        defer { app.terminate() }
        app.buttons["sample.show.sheet"].tap()
        let hostInput = app.textFields["sample.scenario.input"]
        XCTAssertTrue(hostInput.waitForExistence(timeout: 5))
        hostInput.tap()
        hostInput.typeText("before")

        app.buttons["sample.scenario.show-logs"].tap()
        let search = app.textFields["logviewer.search"]
        XCTAssertTrue(search.waitForExistence(timeout: 5))
        XCTAssertTrue(app.buttons["logviewer.close"].isHittable)
        search.tap()
        search.typeText("network included")
        waitForResultCount("1 / 2 logs")
        XCTAssertTrue(element(containing: "network included main")
            .waitForExistence(timeout: 5))
        XCTAssertFalse(element(containing: "database excluded main").exists)

        app.buttons["logviewer.close"].tap()
        XCTAssertTrue(hostInput.waitForExistence(timeout: 5))
        hostInput.tap()
        hostInput.typeText("-after")
        XCTAssertEqual(hostInput.value as? String, "before-after")
    }

    func testWindowAppearsOverFullScreenAndAlert() {
        launch(language: "en")
        defer { app.terminate() }
        app.buttons["sample.show.full-screen"].tap()
        XCTAssertTrue(app.buttons["sample.scenario.show-logs"]
            .waitForExistence(timeout: 5))
        app.buttons["sample.scenario.show-logs"].tap()
        XCTAssertTrue(app.buttons["logviewer.close"]
            .waitForExistence(timeout: 5))
        XCTAssertTrue(app.buttons["logviewer.close"].isHittable)
        app.buttons["logviewer.close"].tap()
        app.buttons["sample.scenario.close"].tap()

        app.buttons["sample.show.alert"].tap()
        XCTAssertTrue(app.alerts.firstMatch.waitForExistence(timeout: 5))
        XCTAssertTrue(app.buttons["logviewer.close"]
            .waitForExistence(timeout: 5))
        XCTAssertTrue(app.buttons["logviewer.close"].isHittable)
        app.buttons["logviewer.close"].tap()
        XCTAssertTrue(app.alerts.firstMatch.exists)
    }

    func testFilteredCopyContainsOnlyProtectedResult() {
        launch(language: "en")
        defer { app.terminate() }
        app.buttons["sample.show.logs"].tap()
        let search = app.textFields["logviewer.search"]
        XCTAssertTrue(search.waitForExistence(timeout: 5))
        search.tap()
        search.typeText("network included")
        waitForResultCount("1 / 2 logs")
        XCTAssertTrue(element(containing: "network included main")
            .waitForExistence(timeout: 5))

        actionMenu.tap()
        XCTAssertTrue(app.buttons["logviewer.actions.copy"]
            .waitForExistence(timeout: 5))
        app.buttons["logviewer.actions.copy"].tap()
        app.buttons["logviewer.close"].tap()
        app.buttons["sample.inspect.clipboard"].tap()

        let preview = app.staticTexts["sample.clipboard.preview"]
        XCTAssertTrue(preview.waitForExistence(timeout: 5))
        let value = preview.label
        XCTAssertTrue(value.contains("network included main"))
        XCTAssertFalse(value.contains("database excluded main"))
        XCTAssertFalse(value.contains("owner@example.com"))
        XCTAssertFalse(value.contains("secret-token"))
        XCTAssertTrue(value.contains("<private>"))
    }

    func testTextAndJSONShareOpenOnlyAfterExplicitAction() {
        launch(language: "en")
        defer { app.terminate() }
        app.buttons["sample.show.logs"].tap()
        XCTAssertTrue(actionMenu.waitForExistence(timeout: 5))
        XCTAssertFalse(shareSheet.exists)

        actionMenu.tap()
        app.buttons["logviewer.actions.share-text"].tap()
        XCTAssertTrue(shareSheet.waitForExistence(timeout: 8))
        dismissShareSheet()

        actionMenu.tap()
        app.buttons["logviewer.actions.share-json"].tap()
        XCTAssertTrue(shareSheet.waitForExistence(timeout: 8))
        dismissShareSheet()
        XCTAssertTrue(app.buttons["logviewer.close"].isHittable)
    }

    func testJapaneseMaximumTextKeepsImportantActionsReachable() {
        launch(language: "ja", maximumContentSize: true)
        defer { app.terminate() }
        app.buttons["sample.show.logs"].tap()
        XCTAssertTrue(app.buttons["logviewer.close"]
            .waitForExistence(timeout: 5))
        XCTAssertTrue(app.buttons["logviewer.close"].isHittable)
        XCTAssertTrue(app.textFields["logviewer.search"].isHittable)

        actionMenu.tap()
        app.buttons["logviewer.actions.pause"].tap()
        XCTAssertTrue(app.staticTexts["logviewer.state.paused"]
            .waitForExistence(timeout: 5))
        actionMenu.tap()
        XCTAssertTrue(app.buttons["logviewer.actions.resume"].isHittable)
        app.buttons["logviewer.actions.resume"].tap()

        actionMenu.tap()
        app.buttons["logviewer.actions.delete"].tap()
        let confirmDelete = app.buttons["logviewer.delete.confirm"]
        XCTAssertTrue(confirmDelete.waitForExistence(timeout: 5))
        let cancelDelete = app.buttons.matching(NSPredicate(
            format: "identifier == %@ OR label == %@ OR label == %@",
            "logviewer.delete.cancel",
            "キャンセル",
            "Cancel"
        )).firstMatch
        if cancelDelete.exists {
            cancelDelete.tap()
        } else {
            // iPadのconfirmationDialogは、キャンセルを外側タップで表す。
            app.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.2))
                .tap()
        }
        XCTAssertTrue(confirmDelete.waitForNonExistence(timeout: 5))
        XCTAssertTrue(app.buttons["logviewer.close"].isHittable)
        XCTAssertTrue(element(containing: "network included main").exists)
    }

    func testEnglishMaximumTextKeepsImportantActionsReachable() {
        launch(language: "en", maximumContentSize: true)
        defer { app.terminate() }
        app.buttons["sample.show.logs"].tap()

        XCTAssertTrue(app.buttons["logviewer.close"]
            .waitForExistence(timeout: 5))
        XCTAssertTrue(app.buttons["logviewer.close"].isHittable)
        XCTAssertTrue(app.textFields["logviewer.search"].isHittable)
        actionMenu.tap()
        XCTAssertTrue(app.buttons["logviewer.actions.pause"]
            .waitForExistence(timeout: 5))
        app.buttons["logviewer.actions.pause"].tap()
        XCTAssertTrue(app.staticTexts["logviewer.state.paused"]
            .waitForExistence(timeout: 5))
    }

    func testSecondarySceneCanBeOpened() throws {
        launch(language: "en")
        defer { app.terminate() }
        app.buttons["sample.open.secondary"].tap()

        let secondary = element(containing: "Scene: secondary")
        XCTAssertTrue(secondary.waitForExistence(timeout: 8))
        XCTAssertGreaterThanOrEqual(app.windows.count, 2)

        guard let secondaryWindow = app.windows.allElementsBoundByIndex
            .first(where: {
                $0.staticTexts["sample.scene.name"].label
                    .contains("secondary")
            }) else {
            XCTFail("secondary scene window was not found")
            return
        }
        let hostInput = secondaryWindow.textFields["sample.host.input"]
        hostInput.tap()
        hostInput.typeText("before")
        secondaryWindow.buttons["sample.show.logs"].tap()

        let search = app.textFields["logviewer.search"]
        XCTAssertTrue(search.waitForExistence(timeout: 5))
        search.tap()
        search.typeText("network included")
        waitForResultCount("1 / 2 logs")
        XCTAssertTrue(element(containing: "network included secondary")
            .waitForExistence(timeout: 5))
        XCTAssertFalse(element(containing: "network included main").exists)

        app.buttons["logviewer.close"].tap()
        XCTAssertTrue(hostInput.waitForExistence(timeout: 5))
        hostInput.tap()
        hostInput.typeText("-after")
        XCTAssertEqual(hostInput.value as? String, "before-after")
    }

    private func launch(
        language: String,
        maximumContentSize: Bool = false
    ) {
        continueAfterFailure = false
        executionTimeAllowance = 90
        app = XCUIApplication()
        app.launchArguments += [
            "-ApplePersistenceIgnoreState", "YES",
            "-AppleLanguages", "(\(language))",
            "-AppleLocale", language == "ja" ? "ja_JP" : "en_US",
        ]
        if maximumContentSize {
            app.launchArguments += [
                "-UIPreferredContentSizeCategoryName",
                "UICTContentSizeCategoryAccessibilityExtraExtraExtraLarge",
            ]
        }
        app.launch()
        XCTAssertTrue(app.buttons["sample.show.logs"]
            .waitForExistence(timeout: 8))
    }

    private func element(containing text: String) -> XCUIElement {
        app.descendants(matching: .any)
            .matching(NSPredicate(format: "label CONTAINS %@", text))
            .firstMatch
    }

    private var shareSheet: XCUIElement {
        app.otherElements["ActivityListView"]
    }

    private var actionMenu: XCUIElement {
        app.descendants(matching: .any)["logviewer.actions"]
    }

    private func dismissShareSheet() {
        app.coordinate(withNormalizedOffset: CGVector(dx: 0.05, dy: 0.05))
            .tap()
        XCTAssertTrue(shareSheet.waitForNonExistence(timeout: 5))
    }

    private func waitForResultCount(_ expected: String) {
        let resultCount = app.staticTexts["logviewer.filter.result-count"]
        XCTAssertTrue(resultCount.waitForExistence(timeout: 5))
        let expectation = XCTNSPredicateExpectation(
            predicate: NSPredicate(format: "label == %@", expected),
            object: resultCount
        )
        XCTAssertEqual(
            XCTWaiter.wait(for: [expectation], timeout: 5),
            .completed
        )
    }
}
