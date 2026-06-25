//
//  VisionMode.swift
//  IrisLens
//
//  Created by Antonio Bonetti on 10/03/26.
//

import SwiftUI

/// Defines the various vision modes supported by the application.
/// Each mode corresponds to a specific type of color vision deficiency (CVD)
/// and determines which color ranges should be isolated and highlighted.
enum VisionMode: String, CaseIterable, Identifiable {
    case deuteranomaly
    case protanomaly
    case tritanomaly
    case normal
    
    var id: String { rawValue }
    
    /// A short symbol used in UI components (e.g., segmented controls).
    var symbol: String {
        switch self {
        case .deuteranomaly: return "D"
        case .protanomaly:  return "P"
        case .tritanomaly:  return "T"
        case .normal:       return "NV"
        }
    }
    
    /// The full, human-readable title of the vision mode.
    var title: String {
        switch self {
        case .deuteranomaly: return "Deuteranomaly (D)"
        case .protanomaly:  return "Protanomaly (P)"
        case .tritanomaly:  return "Tritanomaly (T)"
        case .normal:       return "Normal vision (NV)"
        }
    }
    
    /// A brief description of the deficiency, used in informational UI sheets.
    var description: String {
        switch self {
        case .deuteranomaly:
            return "Reduced sensitivity to green light. Red/green confusion is common."
        case .protanomaly:
            return "Reduced sensitivity to red light. Reds can look darker and less distinct."
        case .tritanomaly:
            return "Reduced sensitivity to blue light. Blue/yellow confusion can happen."
        case .normal:
            return "No color vision deficiency simulation/highlighting."
        }
    }
}
