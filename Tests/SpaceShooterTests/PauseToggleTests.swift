import XCTest
@testable import SpaceShooter

final class PauseToggleTests: XCTestCase {
    func testDistinctPressesTogglePause() {
        var pause = PauseToggle()
        let input = [true, true, false, true, true, false]
        let expectedPaused = [true, true, true, false, false, false]
        let expectedChanged = [true, false, false, true, false, false]

        for frame in input.indices {
            let changed = pause.update(isKeyDown: input[frame])
            XCTAssertEqual(pause.isPaused, expectedPaused[frame], "paused at frame \(frame)")
            XCTAssertEqual(changed, expectedChanged[frame], "transition at frame \(frame)")
        }
    }

    func testNoPressLeavesGameRunning() {
        var pause = PauseToggle()

        for _ in 0..<3 {
            XCTAssertFalse(pause.update(isKeyDown: false))
            XCTAssertFalse(pause.isPaused)
        }
    }
}
