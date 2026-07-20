import XCTest
import RedECS
import RedHUD
import Geometry

@MainActor
class HUDScrollTests: HUDSnapshotTestCase {
    private let colors: [Color] = [.red, .green, .blue, .yellow]

    /// Proof the composed API works today: a ScrollView over ASSORTED, mixed
    /// HUDViews (text, buttons, differently-sized shapes, a ForEach) — full
    /// HUDView support, auto-wrapped in a VStack, scrolled and clipped. This is
    /// `ScrollView { …assorted… }`; a future eager→windowed `LazyVStack` would
    /// be a drop-in child with no API change.
    func testScrollViewOfAssortedContent() throws {
        setHUD {
            ScrollView(.vertical) {
                Text("Header")
                Rectangle().frame(width: 160, height: 30).foregroundColor(.red)
                Button(up: "x") { Rectangle().frame(width: 120, height: 50).foregroundColor(.blue) }
                Text("Middle")
                Rectangle().frame(width: 180, height: 70).foregroundColor(.green)
                ForEach(0..<5, id: \.self) { i in
                    Rectangle().frame(width: 140, height: 28).foregroundColor(colors[i % colors.count])
                        .overlay { Text("\(i)") }
                }
                Text("Footer")
            }
            .frame(width: 200, height: 260)
        }
        snapshotFrame(named: "top")

        // Drag it to prove the mixed content scrolls as one.
        store.sendAction(.hud(.pointerDown(Point(x: 240, y: 300))))
        store.sendAction(.hud(.pointerMove(Point(x: 240, y: 160))))   // up 140
        snapshotFrame(named: "scrolled")
        store.sendAction(.hud(.pointerUp(Point(x: 240, y: 160))))
    }

    /// A genuinely lazy 1000-row list: only the ~6 rows in the window are ever
    /// built, yet the scroll range spans all 1000 (44000pt). Dragging shows a
    /// different window of rows — all still clipped, none off-screen realized.
    func testLazyVStackInScrollView() throws {
        let palette = colors
        setHUD {
            ScrollView(.vertical) {
                LazyVStack(0..<1000, id: \.self) { i in
                    Rectangle().frame(width: 180, height: 44).foregroundColor(palette[i % palette.count])
                        .overlay { Text("\(i)") }
                }
            }
            .frame(width: 200, height: 260)
        }
        snapshotFrame(named: "top")

        store.sendAction(.hud(.pointerDown(Point(x: 240, y: 300))))
        store.sendAction(.hud(.pointerMove(Point(x: 240, y: 100))))   // up 200
        snapshotFrame(named: "scrolled")
        store.sendAction(.hud(.pointerUp(Point(x: 240, y: 100))))
    }


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
