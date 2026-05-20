//
//  Board.swift
//  FlatCube
//
//  Created by Radomyr Sidenko on 14.05.2026.
//

import Foundation

struct Board: Equatable {
    static let size = 9

    private(set) var tiles: [Tile?]

    init() {
        self.tiles = Array(repeating: nil, count: Board.size * Board.size)
    }

    func tileAt(row: Int, col: Int) -> Tile? {
        guard isValid(row: row, col: col) else { return nil }
        return tiles[index(row: row, col: col)]
    }

    func isCellEmpty(row: Int, col: Int) -> Bool {
        tileAt(row: row, col: col) == nil
    }

    func canPlace(_ piece: Piece, at row: Int, col: Int) -> Bool {
        for cell in piece.cells {
            let targetRow = row + cell.row
            let targetCol = col + cell.col
            guard isValid(row: targetRow, col: targetCol) else { return false }
            guard isCellEmpty(row: targetRow, col: targetCol) else { return false }
        }
        return true
    }

    func allValidPlacements(for piece: Piece) -> [(row: Int, col: Int)] {
        var result: [(row: Int, col: Int)] = []
        for row in 0..<Board.size {
            for col in 0..<Board.size {
                if canPlace(piece, at: row, col: col) {
                    result.append((row, col))
                }
            }
        }
        return result
    }

    func hasAnyValidPlacement(for piece: Piece) -> Bool {
        !allValidPlacements(for: piece).isEmpty
    }

    mutating func clear() {
        tiles = Array(repeating: nil, count: Board.size * Board.size)
    }

    mutating func place(_ piece: Piece, at row: Int, col: Int) -> PlacementResult {
        guard canPlace(piece, at: row, col: col) else {
            return PlacementResult(scoreGained: 0, clearedRows: [], clearedColumns: [], clearedBlocks: [], didPlace: false)
        }

        for cell in piece.cells {
            let targetRow = row + cell.row
            let targetCol = col + cell.col
            tiles[index(row: targetRow, col: targetCol)] = Tile(color: piece.color)
        }

        let clearedRows = completedRows()
        let clearedColumns = completedColumns()
        let clearedBlocks = completedBlocks()

        for targetRow in clearedRows {
            for targetCol in 0..<Board.size {
                tiles[index(row: targetRow, col: targetCol)] = nil
            }
        }

        for targetCol in clearedColumns {
            for targetRow in 0..<Board.size {
                tiles[index(row: targetRow, col: targetCol)] = nil
            }
        }

        for block in clearedBlocks {
            let startRow = block.row * 3
            let startCol = block.col * 3
            for localRow in 0..<3 {
                for localCol in 0..<3 {
                    tiles[index(row: startRow + localRow, col: startCol + localCol)] = nil
                }
            }
        }

        let lineClearCount = clearedRows.count + clearedColumns.count + clearedBlocks.count
        let baseScore = piece.tileCount
        let bonusScore = lineClearCount * 18
        let score = baseScore + bonusScore

        return PlacementResult(
            scoreGained: score,
            clearedRows: clearedRows,
            clearedColumns: clearedColumns,
            clearedBlocks: clearedBlocks,
            didPlace: true
        )
    }

    private func completedRows() -> [Int] {
        (0..<Board.size).filter { row in
            (0..<Board.size).allSatisfy { col in tileAt(row: row, col: col) != nil }
        }
    }

    private func completedColumns() -> [Int] {
        (0..<Board.size).filter { col in
            (0..<Board.size).allSatisfy { row in tileAt(row: row, col: col) != nil }
        }
    }

    private func completedBlocks() -> [BoardBlock] {
        var result: [BoardBlock] = []

        for blockRow in 0..<3 {
            for blockCol in 0..<3 {
                var isComplete = true
                for localRow in 0..<3 {
                    for localCol in 0..<3 {
                        let row = blockRow * 3 + localRow
                        let col = blockCol * 3 + localCol
                        if tileAt(row: row, col: col) == nil {
                            isComplete = false
                        }
                    }
                }
                if isComplete {
                    result.append(BoardBlock(row: blockRow, col: blockCol))
                }
            }
        }

        return result
    }

    private func isValid(row: Int, col: Int) -> Bool {
        row >= 0 && row < Board.size && col >= 0 && col < Board.size
    }

    private func index(row: Int, col: Int) -> Int {
        row * Board.size + col
    }
}

struct BoardBlock: Equatable, Hashable {
    let row: Int
    let col: Int
}

struct PlacementResult: Equatable {
    let scoreGained: Int
    let clearedRows: [Int]
    let clearedColumns: [Int]
    let clearedBlocks: [BoardBlock]
    let didPlace: Bool

    var clearedAnything: Bool {
        !clearedRows.isEmpty || !clearedColumns.isEmpty || !clearedBlocks.isEmpty
    }
}
