//
//  GameView.swift
//  FlatCube
//
//  Created by Radomyr Sidenko on 14.05.2026.
//

import SwiftUI
import UIKit

struct GameView: View {
    @StateObject private var viewModel = GameViewModel()

    @State private var activePiece: Piece?
    @State private var boardFrame: CGRect = .zero
    @State private var previewAnchor: GridAnchor?
    @State private var dragLocation: CGPoint = .zero
    @State private var dragPieceTileSize: CGFloat = 24
    @State private var hapticsEnabled = true

    private let dragStartHaptic = UIImpactFeedbackGenerator(style: .light)
    private let dragEndHaptic = UIImpactFeedbackGenerator(style: .medium)
    private let stepHaptic = UISelectionFeedbackGenerator()

    private let cellSpacing: CGFloat = 2
    private let blockSpacing: CGFloat = 10
    private let boardPadding: CGFloat = 8
    private let traySpacing: CGFloat = 14
    private let floatingPieceOffset = CGSize(width: 0, height: -48)

    var body: some View {
        NavigationStack {
            ZStack {
                VStack(spacing: 16) {
                    header

                    GeometryReader { geometry in
                        let width = geometry.size.width
                        let totalSpacing = cellSpacing * 6 + blockSpacing * 2
                        let tileSize = max(0, (width - boardPadding * 2 - totalSpacing) / 9)
                        let logicalStep = tileSize + cellSpacing
                        let boardSize = tileSize * 9 + totalSpacing
                        let trayTileSize = max(18, tileSize * 0.72)

                        VStack(spacing: 0) {
                            ZStack(alignment: .topLeading) {
                                boardGrid(tileSize: tileSize)
                                    .padding(boardPadding)
                                    .background(
                                        GeometryReader { proxy in
                                            Color.clear
                                                .onAppear {
                                                    boardFrame = proxy.frame(in: .global)
                                                }
                                                .onChange(of: proxy.frame(in: .global)) { _, newValue in
                                                    boardFrame = newValue
                                                }
                                        }
                                    )
                            }
                            .frame(width: boardSize + boardPadding * 2, height: boardSize + boardPadding * 2)
                            .background(.thinMaterial)
                            .clipShape(RoundedRectangle(cornerRadius: 16))

                            pieceTray(tileSize: trayTileSize, logicalStep: logicalStep)
                        }
                        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
                        .onAppear {
                            dragPieceTileSize = trayTileSize
                        }
                        .onChange(of: trayTileSize) { _, newValue in
                            dragPieceTileSize = newValue
                        }
                    }

                    if viewModel.isGameOver {
                        Text("Game Over")
                            .font(.headline)
                            .foregroundStyle(.red)
                    }
                }
                .padding()

                floatingDraggedPiece
            }
            .navigationTitle("Block Clone")
        }
    }

    private var header: some View {
        VStack(spacing: 12) {
            HStack {
                StatCard(title: "Score", value: "\(viewModel.score)")
                StatCard(title: "Best", value: "\(viewModel.bestScore)")
                StatCard(title: "Combo", value: "\(viewModel.combo)")
            }

            HStack {
                Button("New Game") {
                    clearDragState()
                    viewModel.newGame()
                }
                .buttonStyle(.borderedProminent)

                Button("Clear Board") {
                    clearDragState()
                    viewModel.resetBoard()
                }
                .buttonStyle(.bordered)
            }

            Toggle("Haptics", isOn: $hapticsEnabled)
                .toggleStyle(.switch)
                .font(.footnote)
        }
    }

    private func boardGrid(tileSize: CGFloat) -> some View {
        VStack(spacing: cellSpacing) {
            ForEach(0..<9, id: \.self) { row in
                HStack(spacing: cellSpacing) {
                    ForEach(0..<9, id: \.self) { col in
                        BoardCellView(
                            tile: viewModel.tile(row: row, col: col),
                            size: tileSize,
                            isPreview: isPreviewCell(row: row, col: col),
                            isPreviewValid: isPreviewValid(),
                            isClearHighlight: isClearHighlightCell(row: row, col: col)
                        )

                        if col == 2 || col == 5 {
                            Color.clear.frame(width: blockSpacing)
                        }
                    }
                }

                if row == 2 || row == 5 {
                    Color.clear.frame(height: blockSpacing)
                }
            }
        }
    }

    private func pieceTray(tileSize: CGFloat, logicalStep: CGFloat) -> some View {
        HStack(alignment: .bottom, spacing: traySpacing) {
            ForEach(Array(viewModel.availablePieces.enumerated()), id: \.element.id) { _, piece in
                PieceView(piece: piece, tileSize: tileSize)
                    .opacity(activePiece?.id == piece.id ? 0 : 1)
                    .gesture(pieceDragGesture(piece: piece, logicalStep: logicalStep, tileSize: tileSize))
            }
        }
        .frame(maxWidth: .infinity, minHeight: 132, alignment: .bottom)
    }

    @ViewBuilder
    private var floatingDraggedPiece: some View {
        if let piece = activePiece {
            PieceView(piece: piece, tileSize: dragPieceTileSize)
                .shadow(color: .black.opacity(0.16), radius: 10, y: 6)
                .scaleEffect(1.02)
                .position(
                    x: dragLocation.x + floatingPieceOffset.width,
                    y: dragLocation.y + floatingPieceOffset.height
                )
                .allowsHitTesting(false)
                .zIndex(1000)
        }
    }

    private func pieceDragGesture(piece: Piece, logicalStep: CGFloat, tileSize: CGFloat) -> some Gesture {
        DragGesture(minimumDistance: 6, coordinateSpace: .global)
            .onChanged { value in
                var transaction = Transaction()
                transaction.disablesAnimations = true

                withTransaction(transaction) {
                    if activePiece == nil {
                        activePiece = piece
                        dragPieceTileSize = tileSize
                        dragLocation = value.location

                        dragStartHaptic.prepare()
                        if hapticsEnabled {
                            dragStartHaptic.impactOccurred()
                        }
                    }

                    guard activePiece?.id == piece.id else { return }

                    dragLocation = value.location
                    updatePlacementTarget(for: piece, location: value.location, logicalStep: logicalStep)
                }
            }
            .onEnded { value in
                guard activePiece?.id == piece.id else { return }

                dragLocation = value.location
                updatePlacementTarget(for: piece, location: value.location, logicalStep: logicalStep)
                finishDrag(for: piece)
            }
    }

    private func updatePlacementTarget(for piece: Piece, location: CGPoint, logicalStep: CGFloat) {
        guard boardFrame != .zero else {
            previewAnchor = nil
            return
        }

        let localX = location.x - boardFrame.minX - boardPadding
        let localY = location.y - boardFrame.minY - boardPadding

        let anchorCol = projectedIndex(for: localX, logicalStep: logicalStep)
        let anchorRow = projectedIndex(for: localY, logicalStep: logicalStep)
        let anchor = GridAnchor(row: anchorRow, col: anchorCol)

        previewAnchor = anchor

        if hapticsEnabled, viewModel.canPlace(piece, at: anchor.row, col: anchor.col) {
            stepHaptic.prepare()
        }
    }

    private func finishDrag(for piece: Piece) {
        if let anchor = previewAnchor, viewModel.canPlace(piece, at: anchor.row, col: anchor.col) {
            if hapticsEnabled {
                dragEndHaptic.prepare()
                dragEndHaptic.impactOccurred()
            }

            viewModel.placePiece(piece, at: anchor.row, col: anchor.col)
        }

        clearDragState()
    }

    private func clearDragState() {
        activePiece = nil
        dragLocation = .zero
        previewAnchor = nil
    }

    private func isPreviewCell(row: Int, col: Int) -> Bool {
        guard let piece = activePiece, let anchor = previewAnchor else { return false }
        return piece.cells.contains { anchor.row + $0.row == row && anchor.col + $0.col == col }
    }

    private func isPreviewValid() -> Bool {
        guard let piece = activePiece, let anchor = previewAnchor else { return false }
        return viewModel.canPlace(piece, at: anchor.row, col: anchor.col)
    }

    private func isClearHighlightCell(row: Int, col: Int) -> Bool {
        guard let piece = activePiece,
              let anchor = previewAnchor,
              viewModel.canPlace(piece, at: anchor.row, col: anchor.col) else {
            return false
        }

        let previewCells = Set(
            piece.cells.map {
                CellPosition(row: anchor.row + $0.row, col: anchor.col + $0.col)
            }
        )

        let rowWillClear = (0..<9).allSatisfy { currentCol in
            previewCells.contains(CellPosition(row: row, col: currentCol)) ||
            viewModel.tile(row: row, col: currentCol) != nil
        }

        let colWillClear = (0..<9).allSatisfy { currentRow in
            previewCells.contains(CellPosition(row: currentRow, col: col)) ||
            viewModel.tile(row: currentRow, col: col) != nil
        }

        let blockRow = row / 3
        let blockCol = col / 3

        let blockWillClear = (0..<3).allSatisfy { localRow in
            (0..<3).allSatisfy { localCol in
                let targetRow = blockRow * 3 + localRow
                let targetCol = blockCol * 3 + localCol

                return previewCells.contains(CellPosition(row: targetRow, col: targetCol)) ||
                viewModel.tile(row: targetRow, col: targetCol) != nil
            }
        }

        return rowWillClear || colWillClear || blockWillClear
    }

    private func projectedIndex(for value: CGFloat, logicalStep: CGFloat) -> Int {
        let blockOffset1 = 3 * logicalStep + (blockSpacing - cellSpacing)
        let blockOffset2 = 6 * logicalStep + (blockSpacing * 2 - cellSpacing * 2)

        if value < 0 { return -1 }
        if value >= blockOffset2 {
            return Int(((value - (blockSpacing * 2 - cellSpacing * 2)) / logicalStep).rounded(.down))
        }
        if value >= blockOffset1 {
            return Int(((value - (blockSpacing - cellSpacing)) / logicalStep).rounded(.down))
        }
        return Int((value / logicalStep).rounded(.down))
    }
}

private struct GridAnchor: Equatable {
    let row: Int
    let col: Int
}

private struct CellPosition: Hashable {
    let row: Int
    let col: Int
}

private struct StatCard: View {
    let title: String
    let value: String

    var body: some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(title)
                .font(.caption)
                .foregroundStyle(.secondary)
            Text(value)
                .font(.title3.bold())
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(12)
        .background(.thinMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 14))
    }
}

private struct BoardCellView: View {
    let tile: Tile?
    let size: CGFloat
    let isPreview: Bool
    let isPreviewValid: Bool
    let isClearHighlight: Bool

    var body: some View {
        RoundedRectangle(cornerRadius: 4)
            .fill(fillStyle)
            .frame(width: size, height: size)
            .overlay {
                RoundedRectangle(cornerRadius: 4)
                    .stroke(strokeStyle, lineWidth: strokeWidth)
            }
            .shadow(color: .black.opacity(tile == nil ? 0.02 : 0.08), radius: 1, y: 1)
    }

    private var fillStyle: AnyShapeStyle {
        if isClearHighlight {
            return AnyShapeStyle(Color.yellow.opacity(tile == nil ? 0.28 : 0.22))
        }

        if let tile {
            if isPreview {
                return AnyShapeStyle(tile.color.color.opacity(isPreviewValid ? 0.45 : 0.25))
            }
            return AnyShapeStyle(tile.color.color.gradient)
        }

        if isPreview {
            return AnyShapeStyle((isPreviewValid ? Color.green : Color.red).opacity(0.18))
        }

        return AnyShapeStyle(Color.primary.opacity(0.07))
    }

    private var strokeStyle: Color {
        if isClearHighlight {
            return .yellow.opacity(0.9)
        }

        if isPreview {
            return isPreviewValid ? .green : .red
        }

        return .white.opacity(tile == nil ? 0.08 : 0.25)
    }

    private var strokeWidth: CGFloat {
        if isClearHighlight { return 2.2 }
        if isPreview { return 1.6 }
        return 1
    }
}

private struct PieceView: View {
    let piece: Piece
    let tileSize: CGFloat

    private let cellSpacing: CGFloat = 2

    var body: some View {
        ZStack(alignment: .topLeading) {
            ForEach(piece.cells) { cell in
                RoundedRectangle(cornerRadius: 4)
                    .fill(piece.color.color.gradient)
                    .frame(width: tileSize, height: tileSize)
                    .overlay {
                        RoundedRectangle(cornerRadius: 4)
                            .stroke(.white.opacity(0.25), lineWidth: 1)
                    }
                    .position(
                        x: CGFloat(cell.col) * (tileSize + cellSpacing) + tileSize / 2,
                        y: CGFloat(cell.row) * (tileSize + cellSpacing) + tileSize / 2
                    )
            }
        }
        .frame(
            width: CGFloat(piece.width) * tileSize + CGFloat(max(0, piece.width - 1)) * cellSpacing,
            height: CGFloat(piece.height) * tileSize + CGFloat(max(0, piece.height - 1)) * cellSpacing,
            alignment: .topLeading
        )
        .padding(10)
        .background(.thinMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 14))
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("\(piece.color.accessibilityName) piece with \(piece.tileCount) blocks")
    }
}
