//
//  Point+Normalize.swift
//  
//
//  Created by K N on 2022-01-21.
//

import Foundation
import Geometry

public extension Point {
    func normalized(to maxValue: Double) -> Point {
        var new = self
        new.normalize(to: maxValue)
        return new
    }
    
    mutating func normalize(to maxValue: Double) {
        let distance = distanceFrom(.zero)
        guard distance > 0 else { return }
        self = (self / distance) * maxValue
    }
}
