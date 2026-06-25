//
//  ColorNamer.swift
//  IrisLens
//
//  Created by Antonio Bonetti on 10/03/26.
//

import SwiftUI

/// A utility struct responsible for matching RGB pixel data to human-readable color names.
struct ColorNamer {
    
    /// Represents a predefined color with its standard RGB values (0-255).
    struct NamedColor {
        let name: String
        let r: Double
        let g: Double
        let b: Double
    }
    
    /// A dictionary of standard colors used as reference points for the nearest-neighbor algorithm.
    static let colors: [NamedColor] = [
        NamedColor(name: "Black", r: 0, g: 0, b: 0),
        NamedColor(name: "White", r: 255, g: 255, b: 255),
        NamedColor(name: "Red", r: 255, g: 0, b: 0),
        NamedColor(name: "Lime", r: 0, g: 255, b: 0),
        NamedColor(name: "Blue", r: 0, g: 0, b: 255),
        NamedColor(name: "Yellow", r: 255, g: 255, b: 0),
        NamedColor(name: "Cyan", r: 0, g: 255, b: 255),
        NamedColor(name: "Magenta", r: 255, g: 0, b: 255),
        NamedColor(name: "Silver", r: 192, g: 192, b: 192),
        NamedColor(name: "Gray", r: 128, g: 128, b: 128),
        NamedColor(name: "Maroon", r: 128, g: 0, b: 0),
        NamedColor(name: "Olive", r: 128, g: 128, b: 0),
        NamedColor(name: "Green", r: 0, g: 128, b: 0),
        NamedColor(name: "Purple", r: 128, g: 0, b: 128),
        NamedColor(name: "Teal", r: 0, g: 128, b: 128),
        NamedColor(name: "Navy", r: 0, g: 0, b: 128),
        NamedColor(name: "Orange", r: 255, g: 165, b: 0),
        NamedColor(name: "Brown", r: 165, g: 42, b: 42),
        NamedColor(name: "Pink", r: 255, g: 192, b: 203),
        NamedColor(name: "Indigo", r: 75, g: 0, b: 130),
        NamedColor(name: "Violet", r: 238, g: 130, b: 238),
        NamedColor(name: "Gold", r: 255, g: 215, b: 0),
        NamedColor(name: "Beige", r: 245, g: 245, b: 220),
        NamedColor(name: "Turquoise", r: 64, g: 224, b: 208),
        NamedColor(name: "Lavender", r: 230, g: 230, b: 250),
        NamedColor(name: "Coral", r: 255, g: 127, b: 80),
        NamedColor(name: "Sky Blue", r: 135, g: 206, b: 235),
        NamedColor(name: "Forest Green", r: 34, g: 139, b: 34),
        NamedColor(name: "Crimson", r: 220, g: 20, b: 60)
    ]
    
    /// Compares an input RGB color against the predefined color palette to find the closest match.
    ///
    /// This function uses a Weighted Euclidean Distance algorithm to approximate human color perception.
    /// The human eye is more sensitive to green and red than it is to blue. Therefore, differences in
    /// the green channel are penalized more heavily than differences in the blue channel.
    ///
    /// - Parameters:
    ///   - r: The normalized red value (0.0 to 1.0).
    ///   - g: The normalized green value (0.0 to 1.0).
    ///   - b: The normalized blue value (0.0 to 1.0).
    /// - Returns: A `String` representing the name of the closest matching color.
    static func name(for r: Double, g: Double, b: Double) -> String {
        var minDistance = Double.infinity
        var closestColor = "Unknown"
        
        // Convert normalized values (0.0-1.0) back to standard 8-bit scale (0-255) for comparison.
        let r1 = r * 255
        let g1 = g * 255
        let b1 = b * 255
        
        for color in colors {
            let dr = color.r - r1
            let dg = color.g - g1
            let db = color.b - b1
            
            // Weighted Euclidean distance: 2*ΔR^2 + 4*ΔG^2 + 3*ΔB^2
            // Green is weighted most (4), followed by Blue (3), then Red (2).
            let distance = 2 * pow(dr, 2) + 4 * pow(dg, 2) + 3 * pow(db, 2)
            
            if distance < minDistance {
                minDistance = distance
                closestColor = color.name
            }
        }
        
        return closestColor
    }
}
