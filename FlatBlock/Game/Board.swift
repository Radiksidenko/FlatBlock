//
//  Board.swift
//  FlatCube
//
//  Created by Radomyr Sidenko on 14.05.2026.
//

import Foundation

struct Board: Equatable {
    static let size = 9
    private(set) var tiles: [Tile]
    let solvedTiles: [Tile]

    init() {
        let solved = Board.makeSolvedTiles()
        self.tiles = solved
        self.solvedTiles = solved
    }

    func tileAt(row: Int, col: Int) -> Tile {
        tiles[index(row: row, col: col)]
    }

    func isSolved() -> Bool {
        tiles.map(\.color) == solvedTiles.map(\.color)
    }

    mutating func reset() {
        tiles = solvedTiles
    }

    mutating func shuffle(moveCount: Int = 200) {
        reset()
        for _ in 0..<moveCount {
            let isRow = Bool.random()
            let idx = Int.random(in: 0..<Board.size)
            let forward = Bool.random()
            if isRow {
                shiftRow(idx, by: forward ? 1 : -1)
            } else {
                shiftColumn(idx, by: forward ? 1 : -1)
            }
        }
    }

    mutating func shiftRow(_ row: Int, by amount: Int) {
        guard row >= 0 && row < Board.size else { return }
        let normalized = ((amount % Board.size) + Board.size) % Board.size
        guard normalized != 0 else { return }

        let start = row * Board.size
        let rowTiles = Array(tiles[start..<(start + Board.size)])
        let shifted = Array(rowTiles.suffix(normalized)) + Array(rowTiles.dropLast(normalized))
        tiles.replaceSubrange(start..<(start + Board.size), with: shifted)
    }

    mutating func shiftColumn(_ col: Int, by amount: Int) {
        guard col >= 0 && col < Board.size else { return }
        let normalized = ((amount % Board.size) + Board.size) % Board.size
        guard normalized != 0 else { return }

        var column = (0..<Board.size).map { tiles[index(row: $0, col: col)] }
        column = Array(column.suffix(normalized)) + Array(column.dropLast(normalized))

        for row in 0..<Board.size {
            tiles[index(row: row, col: col)] = column[row]
        }
    }

    private func index(row: Int, col: Int) -> Int {
        row * Board.size + col
    }

    private static func makeSolvedTiles() -> [Tile] {
        var result: [Tile] = []

        for blockRow in 0..<3 {
            for _ in 0..<3 {
                for blockCol in 0..<3 {
                    let colorIndex = blockRow * 3 + blockCol
                    let color = TileColor.allCases[colorIndex]
                    for _ in 0..<3 {
                        result.append(Tile(color: color))
                    }
                }
            }
        }

        return result
    }
}
