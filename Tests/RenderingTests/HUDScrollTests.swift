import XCTest
import RedECS
import RedHUD
import Geometry

@MainActor
class HUDScrollTests: HUDSnapshotTestCase {
    private let colors: [Color] = [.red, .green, .blue, .yellow]

    @HUDViewBuilder private func rows() -> [AnyHUDView] {
        VStack(spacing: 0) {
            ForEach(0..<20, id: \.self) { i in
                Rectangle()
                    .frame(width: 200, height: 63)
                    .foregroundColor(colors[i % colors.count])
                    .overlay {
                        Text("\(i)")
                    }
            }
        }
    }

    func testScrollViewWithClippedFrame() throws {
        setHUD {
            ScrollView(.vertical) { rows() }
                .frame(width: 200, height: 300)
        }
        snapshotFrame()
    }

    func testScrollToIdShowsTargetRow() throws {
        setHUD {
            ScrollView(.vertical, scrollTo: 9) { rows() }
                .frame(width: 200)
        }
        snapshotFrame()
    }

    @HUDViewBuilder private func columns() -> [AnyHUDView] {
        HStack(spacing: 0) {
            ForEach(0..<20, id: \.self) { i in
                Rectangle()
                    .frame(width: 63, height: 200)
                    .foregroundColor(colors[i % colors.count])
                    .overlay {
                        Text("\(i)")
                    }
            }
        }
    }

    func testHorizontalScrollViewWithClippedFrame() throws {
        setHUD {
            ScrollView(.horizontal) { columns() }
                .frame(width: 300, height: 200)
        }
        snapshotFrame()
    }

    func testHorizontalScrollToIdShowsTargetColumn() throws {
        setHUD {
            ScrollView(.horizontal, scrollTo: 9) { columns() }
                .frame(height: 200)
        }
        snapshotFrame()
    }

    func testDragScrollTimeline() throws {
        setHUD {
            ScrollView(.vertical) { rows() }
                .frame(width: 200, height: 300)
        }
        snapshotFrame(named: "start")   // offset 0 — rows 0…

        store.sendAction(.hud(.pointerDown(Point(x: 240, y: 300))))
        store.sendAction(.hud(.pointerMove(Point(x: 240, y: 200))))   // drag up 100
        snapshotFrame(named: "middle")  // offset 100

        store.sendAction(.hud(.pointerMove(Point(x: 240, y: 100))))   // drag up another 100
        snapshotFrame(named: "end")     // offset 200

        // Cross-axis: a horizontal drag on a vertical scroll changes nothing.
        store.sendAction(.hud(.pointerMove(Point(x: 340, y: 100))))   // right 100, y fixed
        snapshotFrame(named: "crossAxis")   // still offset 200 — identical to end
        store.sendAction(.hud(.pointerUp(Point(x: 340, y: 100))))
    }

    func testHorizontalDragScrollTimeline() throws {
        setHUD {
            ScrollView(.horizontal) { columns() }
                .frame(width: 300, height: 200)
        }
        snapshotFrame(named: "start")   // offset 0 — columns 0…

        store.sendAction(.hud(.pointerDown(Point(x: 300, y: 240))))
        store.sendAction(.hud(.pointerMove(Point(x: 200, y: 240))))   // drag left 100
        snapshotFrame(named: "middle")  // offset 100

        store.sendAction(.hud(.pointerMove(Point(x: 100, y: 240))))   // drag left another 100
        snapshotFrame(named: "end")     // offset 200

        // Cross-axis: a vertical drag on a horizontal scroll changes nothing.
        store.sendAction(.hud(.pointerMove(Point(x: 100, y: 340))))   // down 100, x fixed
        snapshotFrame(named: "crossAxis")   // still offset 200 — identical to end
        store.sendAction(.hud(.pointerUp(Point(x: 100, y: 340))))
    }
}
