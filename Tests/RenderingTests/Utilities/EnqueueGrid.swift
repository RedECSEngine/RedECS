//
//  EnqueueGrid.swift
//  
//
//  Created by K N on 2022-08-19.
//

import Geometry
import RedECS
import RedECSAppleSupport

func enqueueGrid(into renderer: MetalRenderer) {
    let increments = 48
    let stepBy = 20
    let majorIncrements = 6
    for i in 0..<increments {
        var thickness: Double = (i % majorIncrements == 0) ? 3 : 2
        if i == 0 {
            thickness = 10
        }
        let rectCol = Rect(
            origin: .init(x: Double(i * stepBy) - thickness/2, y: 0),
            size: .init(width: thickness, height: Double(increments * stepBy))
        )
        let rectRow = Rect(
            origin: .init(x: 0, y: Double(i * stepBy) - thickness/2),
            size: .init(width: Double(increments * stepBy), height: thickness)
        )
        renderer.enqueue([
            RenderGroup(
                triangles: try! rectCol.triangulate().map { RenderTriangle(triangle: $0) },
                transformMatrix: .identity,
                fragmentType: .color(i == 0 ? .pink : .green),
                zIndex: 0
            ),
            RenderGroup(
                triangles: try! rectRow.triangulate().map { RenderTriangle(triangle: $0) },
                transformMatrix: .identity,
                fragmentType: .color(i == 0 ? .pink : .green),
                zIndex: 0
            )
        ])
    }
}

func enqueuePoint(_ point: Point, into renderer: MetalRenderer) {
    let circle = Circle(center: point, radius: 6)
    renderer.enqueue([
        RenderGroup(
            triangles: try! circle.triangulate().map { RenderTriangle(triangle: $0) },
            transformMatrix: .identity, fragmentType: .color(.orange),
            zIndex: 100
        )
    ])
}
