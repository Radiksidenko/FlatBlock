//
//  GameViewModel.swift
//  FlatCube
//
//  Created by Radomyr Sidenko on 14.05.2026.
//

import SwiftUI

final class GameViewModel: ObservableObject {
    @Published private(set) var board = Board()
    @Published private(set) var score = 0
    @Published private(set) var bestScore = 0
    @Published private(set) var combo = 0
    @Published private(set) var streak = 0
    @Published private(set) var isGameOver = false
    @Published private(set) var availablePieces: [Piece] = []
    @Published private(set) var lastPlacement: PlacementResult?

    init() {
        newGame()
    }

    func newGame() {
        board = Board()
        score = 0
        combo = 0
        streak = 0
        isGameOver = false
        lastPlacement = nil
        availablePieces = PieceLibrary.randomPieces(count: 3)
        updateGameOverState()
    }

    func resetBoard() {
        board = Board()
        score = 0
        combo = 0
        streak = 0
        isGameOver = false
        lastPlacement = nil
        availablePieces = PieceLibrary.randomPieces(count: 3)
        updateGameOverState()
    }

    func tile(row: Int, col: Int) -> Tile? {
        board.tileAt(row: row, col: col)
    }

    func piece(at index: Int) -> Piece? {
        guard availablePieces.indices.contains(index) else { return nil }
        return availablePieces[index]
    }

    func canPlace(_ piece: Piece, at row: Int, col: Int) -> Bool {
        board.canPlace(piece, at: row, col: col)
    }

    func allValidPlacements(for piece: Piece) -> [(row: Int, col: Int)] {
        board.allValidPlacements(for: piece)
    }

    func placePiece(_ piece: Piece, at row: Int, col: Int) {
        guard !isGameOver else { return }
        guard let pieceIndex = availablePieces.firstIndex(where: { $0.id == piece.id }) else { return }

        let result = board.place(piece, at: row, col: col)
        guard result.didPlace else { return }

        availablePieces.remove(at: pieceIndex)

        score += result.scoreGained

        if result.clearedAnything {
            combo += 1
            streak += 1
            score += combo * 10
        } else {
            combo = 0
        }

        bestScore = max(bestScore, score)
        lastPlacement = result

        refillPiecesIfNeeded()
        updateGameOverState()
    }

    func ghostCells(for piece: Piece, anchorRow: Int, anchorCol: Int) -> [(Int, Int)] {
        piece.cells.map { (anchorRow + $0.row, anchorCol + $0.col) }
    }

    private func refillPiecesIfNeeded() {
        if availablePieces.isEmpty {
            availablePieces = PieceLibrary.randomPieces(count: 3)
        }
    }

    private func updateGameOverState() {
        isGameOver = !availablePieces.contains { board.hasAnyValidPlacement(for: $0) }
    }
}
