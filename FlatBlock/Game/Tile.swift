//
//  Tile.swift
//  FlatCube
//
//  Created by Radomyr Sidenko on 14.05.2026.
//

import SwiftUI

enum TileColor: Int, CaseIterable, Codable {
    case red, blue, green, yellow, purple, orange, cyan, pink, darkGray

    var color: Color {
        switch self {
        case .red: Color(#colorLiteral(red: 0.855, green: 0.114, blue: 0.114, alpha: 1)) // #da1d1d
        case .blue: Color(#colorLiteral(red: 0.118, green: 0.298, blue: 0.855, alpha: 1)) // #1e4cda
        case .green: Color(#colorLiteral(red: 0.184, green: 0.655, blue: 0.208, alpha: 1)) // #2fa735
        case .yellow: Color(#colorLiteral(red: 0.988, green: 0.827, blue: 0.0, alpha: 1)) // #fcd300
        case .purple: Color(#colorLiteral(red: 0.553, green: 0.114, blue: 0.855, alpha: 1)) // #8d1dda
        case .orange: Color(#colorLiteral(red: 0.957, green: 0.502, blue: 0.059, alpha: 1)) // #f4800f
        case .cyan: Color(#colorLiteral(red: 0.0, green: 0.784, blue: 0.855, alpha: 1)) // #00c8da
        case .pink: Color(#colorLiteral(red: 0.925, green: 0.251, blue: 0.588, alpha: 1)) // #ec4096
        case .darkGray: Color(#colorLiteral(red: 0.251, green: 0.271, blue: 0.314, alpha: 1)) // #404550
        }
    }

    var accessibilityName: String {
        switch self {
        case .red: return "tangerine"
        case .blue: return "orange"
        case .green: return "yellow"
        case .yellow: return "lime"
        case .purple: return "green"
        case .orange: return "cyan"
        case .cyan: return "twilight"
        case .pink: return "purple"
        case .darkGray: return "peach"
        }
    }
}

struct Tile: Identifiable, Equatable, Codable {
    let id: UUID
    let color: TileColor

    init(id: UUID = UUID(), color: TileColor) {
        self.id = id
        self.color = color
    }
}
