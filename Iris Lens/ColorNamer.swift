//
//  ColorNamer.swift
//  IrisLens
//
//  Created by Antonio Bonetti on 10/03/26.
//

import SwiftUI

struct ColorNamer {
    struct NamedColor {
        let name: String
        let r: Double
        let g: Double
        let b: Double
    }
    
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
    
    static func name(for r: Double, g: Double, b: Double) -> String {
        var minDistance = Double.infinity
        var closestColor = "Unknown"
        
        let r1 = r * 255
        let g1 = g * 255
        let b1 = b * 255
        
        for color in colors {
            let dr = color.r - r1
            let dg = color.g - g1
            let db = color.b - b1
            
            // Weighted Euclidean distance for better human perception approximation
            // Red and Green are weighted more than Blue.
            let distance = 2 * pow(dr, 2) + 4 * pow(dg, 2) + 3 * pow(db, 2)
            
            if distance < minDistance {
                minDistance = distance
                closestColor = color.name
            }
        }
        
        return closestColor
    }
}
