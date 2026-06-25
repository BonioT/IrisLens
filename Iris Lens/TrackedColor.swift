//
//  TrackedColor.swift
//  IrisLens
//
//  Created by Antonio Bonetti on 10/03/26.
//

import SwiftUI

/// Represents the specific primary colors that the application can track and highlight.
/// Contains the mathematical HSV bounds for each color to generate accurate 3D Color LUTs.
enum TrackedColor: String, CaseIterable, Identifiable {
    case red
    case green
    case blue
    case yellow
    
    var id: String { rawValue }
    
    /// The hue range in degrees (0-360) corresponding to this color in the HSV color space.
    /// Note: Red crosses the 0-degree mark, so its min is higher than its max (330 to 30).
    var hueRangeDegrees: (min: Double, max: Double) {
        switch self {
        case .red:    return (min: 330, max: 30)
        case .yellow: return (min: 40,  max: 80)
        case .green:  return (min: 80,  max: 160)
        case .blue:   return (min: 180, max: 260)
        }
    }
    
    /// The minimum saturation threshold (0.0 - 1.0) required to consider a pixel as matching this color.
    /// This prevents highlighting desaturated/grayish objects like concrete or shadows.
    var minSaturation: Double {
        switch self {
        case .red:    return 0.20
        case .yellow: return 0.20
        case .green:  return 0.18
        case .blue:   return 0.18
        }
    }
    
    /// The minimum brightness/value threshold (0.0 - 1.0) required to consider a pixel as matching this color.
    /// This prevents highlighting extremely dark/black objects.
    var minValue: Double {
        switch self {
        case .red:    return 0.15
        case .yellow: return 0.20
        case .green:  return 0.12
        case .blue:   return 0.08
        }
    }
}
