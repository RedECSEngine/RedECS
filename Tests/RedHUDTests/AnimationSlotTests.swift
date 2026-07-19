import XCTest
import Geometry
import RedECS
@testable import RedHUD

final class AnimationSlotTests: XCTestCase {
    private var cache: HUDCache!
    private let key = AnimationKey(path: [.index(0)], kind: "scale")

    override func setUp() {
        cache = HUDCache()
        cache.beginAnimationFrame()
    }

    private func step(
        target: Double? = nil,
        range: (from: Double, to: Double)? = nil,
        duration: Double = 1,
        timing: TimingFunction = .linear,
        repeats: Repetition = .once,
        trigger: AnimationTrigger = .targetChange,
        delta: Double
    ) -> Double {
        cache.stepAnimation(
            key: key,
            singleTarget: target,
            range: range,
            animation: HUDAnimation(duration: duration, timing: timing, repeats: repeats, trigger: trigger),
            delta: delta
        )
    }

    func testTargetChangeInstallsSettledWithoutAnimating() {
        XCTAssertEqual(step(target: 1.0, delta: 1), 1.0)
        XCTAssertEqual(step(target: 1.0, delta: 1), 1.0)
    }

    func testTargetChangeTransitionsAndSettles() {
        _ = step(target: 1.0, delta: 1)                       // install
        XCTAssertEqual(step(target: 2.0, delta: 1), 1.0)      // transition begins at start
        XCTAssertEqual(step(target: 2.0, delta: 0.25), 1.25)
        XCTAssertEqual(step(target: 2.0, delta: 0.25), 1.5)
        XCTAssertEqual(step(target: 2.0, delta: 0.5), 2.0)    // completes, settles
        XCTAssertEqual(step(target: 2.0, delta: 5), 2.0)      // stays settled
    }

    func testRetargetMidFlightResumesFromDisplayedValue() {
        _ = step(target: 0.0, delta: 1)
        _ = step(target: 1.0, delta: 1)          // begin 0 → 1
        _ = step(target: 1.0, delta: 0.5)        // displayed 0.5
        XCTAssertEqual(step(target: 0.0, delta: 1), 0.5)   // retarget: starts at 0.5
        XCTAssertEqual(step(target: 0.0, delta: 0.5), 0.25, accuracy: 1e-9)
    }

    func testEasingAppliesPerLeg() {
        _ = step(target: 0.0, timing: .easeIn, delta: 1)
        _ = step(target: 1.0, timing: .easeIn, delta: 1)
        // easeIn(0.5) = 0.25
        XCTAssertEqual(step(target: 1.0, timing: .easeIn, delta: 0.5), 0.25)
    }

    func testAppearPlaysFromBirthAndPingPongsForever() {
        let range = (from: 1.0, to: 2.0)
        let repeats = Repetition.forever(strategy: .pingPong)
        XCTAssertEqual(step(range: range, repeats: repeats, trigger: .appear, delta: 1), 1.0)   // install at from
        XCTAssertEqual(step(range: range, repeats: repeats, trigger: .appear, delta: 0.5), 1.5)
        XCTAssertEqual(step(range: range, repeats: repeats, trigger: .appear, delta: 1.0), 1.5) // 1.5 legs in → coming back
        XCTAssertEqual(step(range: range, repeats: repeats, trigger: .appear, delta: 0.5), 1.0) // full cycle
        XCTAssertEqual(step(range: range, repeats: repeats, trigger: .appear, delta: 0.25), 1.25) // still going
    }

    func testRestartLoopJumpsBack() {
        let range = (from: 0.0, to: 1.0)
        let repeats = Repetition.forever(strategy: .restart)
        _ = step(range: range, repeats: repeats, trigger: .appear, delta: 1)
        XCTAssertEqual(step(range: range, repeats: repeats, trigger: .appear, delta: 0.75), 0.75)
        XCTAssertEqual(step(range: range, repeats: repeats, trigger: .appear, delta: 0.5), 0.25)  // wrapped
    }

    func testCountedPingPongEndStates() {
        let range = (from: 1.0, to: 2.0)
        // even count ends at start
        var repeats = Repetition.count(2, strategy: .pingPong)
        _ = step(range: range, repeats: repeats, trigger: .appear, delta: 1)
        XCTAssertEqual(step(range: range, repeats: repeats, trigger: .appear, delta: 2.5), 1.0)
        XCTAssertEqual(step(range: range, repeats: repeats, trigger: .appear, delta: 1), 1.0)

        // odd count ends at target (fresh key)
        cache = HUDCache()
        cache.beginAnimationFrame()
        repeats = .count(3, strategy: .pingPong)
        _ = step(range: range, repeats: repeats, trigger: .appear, delta: 1)
        XCTAssertEqual(step(range: range, repeats: repeats, trigger: .appear, delta: 3.5), 2.0)
    }

    func testChangeTriggerIsSilentAtBirthAndReplaysOnChange() {
        let range = (from: 1.0, to: 1.5)
        // silent install at rest
        XCTAssertEqual(step(range: range, trigger: .change(of: 5), delta: 1), 1.0)
        XCTAssertEqual(step(range: range, trigger: .change(of: 5), delta: 5), 1.0)
        // trigger changes → plays
        XCTAssertEqual(step(range: range, trigger: .change(of: 6), delta: 1), 1.0)
        XCTAssertEqual(step(range: range, trigger: .change(of: 6), delta: 0.5), 1.25)
        XCTAssertEqual(step(range: range, trigger: .change(of: 6), delta: 0.5), 1.5)
        // same trigger stays settled
        XCTAssertEqual(step(range: range, trigger: .change(of: 6), delta: 1), 1.5)
    }

    func testZeroDurationAppliesInstantly() {
        XCTAssertEqual(step(target: 3.0, duration: 0, delta: 1), 3.0)
    }

    func testOpacityFactorRoutesPerFragmentType() {
        // The renderers only read RenderGroup.opacity for texture groups;
        // color groups blend with their fill color's alpha.
        let view = Rectangle()
            .frame(width: 10, height: 10)
            .foregroundColor(.green)
            .opacity(0.5)
        let groups = view.render(context: HUDRenderContext(), size: Size(width: 10, height: 10))
        XCTAssertEqual(groups.first?.color, Color.green.withAlpha(0.5))
        XCTAssertEqual(groups.first?.opacity, 0.5)
    }

    func testUntouchedSlotsArePrunedEachFrame() {
        _ = step(target: 1.0, delta: 1)
        cache.endAnimationFrame()
        XCTAssertEqual(cache.animationSlots.count, 1)

        cache.beginAnimationFrame()   // nothing steps this frame
        cache.endAnimationFrame()
        XCTAssertTrue(cache.animationSlots.isEmpty)
    }
}
