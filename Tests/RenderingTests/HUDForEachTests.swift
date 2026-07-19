import XCTest
import RedECS
import RedHUD
import Geometry

@MainActor
class HUDForEachTests: HUDSnapshotTestCase {
    /// One coloured bar per element; the enclosing VStack lays the ForEach
    /// output out vertically, proving ForEach is transparent to layout.
    func testForEachInVStack() throws {
        let bars: [(id: Int, width: Double, color: Color)] = [
            (0, 60, .red),
            (1, 100, .green),
            (2, 140, .blue),
            (3, 80, .yellow),
        ]
        setHUD {
            VStack(alignment: .leading, spacing: 8) {
                ForEach(bars, id: \.id) { bar in
                    Rectangle().frame(width: bar.width, height: 24).foregroundColor(bar.color)
                }
            }
        }
        snapshotFrame()
    }

    /// The same expansion laid out horizontally by an HStack — ForEach owns
    /// no axis, so the parent alone decides the direction.
    func testForEachInHStack() throws {
        let bars: [(id: Int, height: Double, color: Color)] = [
            (0, 60, .red),
            (1, 100, .green),
            (2, 140, .blue),
            (3, 80, .yellow),
        ]
        setHUD {
            HStack(alignment: .bottom, spacing: 8) {
                ForEach(bars, id: \.id) { bar in
                    Rectangle().frame(width: 24, height: bar.height).foregroundColor(bar.color)
                }
            }
        }
        snapshotFrame()
    }

    /// Only the middle element carries a scale animation. Its slot is keyed
    /// by that element's ForEach `.id`, so the transaction lands on the green
    /// bar alone — it grows about its center (render-only, so layout of the
    /// red and blue neighbours is unchanged) across the three frames.
    func testForEachMiddleElementScaleTimeline() throws {
        let bars: [(id: Int, color: Color)] = [(0, .red), (1, .green), (2, .blue)]
        setHUD {
            VStack(spacing: 8) {
                ForEach(bars, id: \.id) { bar in
                    if bar.id == 1 {
                        Rectangle()
                            .frame(width: 120, height: 40)
                            .foregroundColor(bar.color)
                            .scaleEffect(from: 1.0, to: 2.0)
                            .animated(duration: 1, timing: .linear, on: .appear)
                    } else {
                        Rectangle()
                            .frame(width: 120, height: 40)
                            .foregroundColor(bar.color)
                    }
                }
            }
        }
        snapshotFrame(named: "start")               // install → 1.0x (40 tall)
        snapshotFrame(named: "middle", delta: 0.5)  // t=0.5 → 1.5x (60 tall)
        snapshotFrame(named: "end", delta: 0.5)     // t=1.0 → settled 2.0x (80 tall)
    }

    /// ForEach interleaves with statically-placed siblings in the same stack.
    func testForEachComposesWithStaticSiblings() throws {
        let rows: [(id: Int, color: Color)] = [(0, .red), (1, .green), (2, .blue)]
        setHUD {
            VStack(alignment: .leading, spacing: 8) {
                Rectangle().frame(width: 160, height: 16).foregroundColor(.white)
                ForEach(rows, id: \.id) { row in
                    Rectangle().frame(width: 100, height: 24).foregroundColor(row.color)
                }
                Rectangle().frame(width: 160, height: 16).foregroundColor(.white)
            }
        }
        snapshotFrame()
    }
}
