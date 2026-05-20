//
//  Piece.swift
//  FlatBlock
//
//  Created by Radomyr Sidenko on 20.05.2026.
//

import Foundation

struct PieceCell: Identifiable, Hashable, Codable {
    let id: UUID
    let row: Int
    let col: Int

    init(id: UUID = UUID(), row: Int, col: Int) {
        self.id = id
        self.row = row
        self.col = col
    }
}

struct Piece: Identifiable, Equatable, Codable {
    let id: UUID
    let color: TileColor
    let cells: [PieceCell]

    init(id: UUID = UUID(), color: TileColor, cells: [PieceCell]) {
        self.id = id
        self.color = color
        self.cells = cells
    }

    var width: Int {
        (cells.map(\.col).max() ?? 0) + 1
    }

    var height: Int {
        (cells.map(\.row).max() ?? 0) + 1
    }

    var tileCount: Int {
        cells.count
    }
}

enum PieceLibrary {
    static func randomPieces(count: Int) -> [Piece] {
        (0..<count).map { _ in randomPiece() }
    }

    static func randomPiece() -> Piece {
        let shape = shapes.randomElement() ?? [(0, 0)]
        let color = TileColor.allCases.randomElement() ?? .blue
        let cells = shape.map { PieceCell(row: $0.0, col: $0.1) }
        return Piece(color: color, cells: cells)
    }

    private static let shapes: [[(Int, Int)]] = [
        [(0, 0)],
        [(0, 0), (0, 1)],
        [(0, 0), (1, 0)],
        [(0, 0), (0, 1), (0, 2)],
        [(0, 0), (1, 0), (2, 0)],
        [(0, 0), (0, 1), (1, 0), (1, 1)],
        [(0, 0), (0, 1), (0, 2), (1, 1)],
        [(0, 1), (1, 0), (1, 1), (1, 2)],
        [(0, 0), (1, 0), (2, 0), (1, 1)],
        [(0, 1), (1, 1), (2, 1), (1, 0)],
        [(0, 0), (0, 1), (0, 2), (1, 0)],
        [(0, 0), (0, 1), (0, 2), (1, 2)],
        [(0, 0), (1, 0), (2, 0), (2, 1)],
        [(0, 1), (1, 1), (2, 1), (2, 0)],
        [(0, 0), (0, 1), (1, 1), (1, 2)],
        [(0, 1), (0, 2), (1, 0), (1, 1)],
        [(0, 0), (1, 0), (1, 1), (2, 1)],
        [(0, 1), (1, 1), (1, 0), (2, 0)],
        [(0, 0), (0, 1), (0, 2), (0, 3)],
        [(0, 0), (1, 0), (2, 0), (3, 0)],
        [(0, 0), (0, 1), (0, 2), (1, 0), (1, 1), (1, 2)],
        [(0, 0), (1, 0), (2, 0), (0, 1), (1, 1), (2, 1)],
        [(0, 0), (0, 1), (1, 0), (1, 1), (2, 0), (2, 1)],
        [(0, 0), (0, 1), (0, 2), (1, 0), (1, 1), (1, 2), (2, 0), (2, 1), (2, 2)]
    ]
}
