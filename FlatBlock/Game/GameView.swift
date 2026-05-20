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
    @State private var dragOffset: CGSize = .zero
    @State private var boardFrame: CGRect = .zero
    @State private var previewAnchor: GridAnchor?
    @State private var hapticsEnabled = true
    @State private var didTriggerPlacementHaptic = false

    private let dragStartHaptic = UIImpactFeedbackGenerator(style: .light)
    private let dragEndHaptic = UIImpactFeedbackGenerator(style: .medium)
    private let stepHaptic = UISelectionFeedbackGenerator()

    private let cellSpacing: CGFloat = 2
    private let blockSpacing: CGFloat = 10
    private let boardPadding: CGFloat = 8
    private let traySpacing: CGFloat = 14

    var body: some View {
        NavigationStack {
            VStack(spacing: 16) {
                header

                GeometryReader { geometry in
                    let width = geometry.size.width
                    let totalSpacing = cellSpacing * 6 + blockSpacing * 2
                    let tileSize = max(0, (width - boardPadding * 2 - totalSpacing) / 9)
                    let logicalStep = tileSize + cellSpacing
                    let boardSize = tileSize * 9 + totalSpacing

                    VStack(spacing: 0) {
                        ZStack(alignment: .topLeading) {
                            boardGrid(tileSize: tileSize)
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

                        pieceTray(tileSize: tileSize, logicalStep: logicalStep)
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
                }

                if viewModel.isGameOver {
                    Text("Game Over")
                        .font(.headline)
                        .foregroundStyle(.red)
                }
            }
            .padding()
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
                            isPreviewValid: isPreviewValid()
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
            ForEach(Array(viewModel.availablePieces.enumerated()), id: \.element.id) { index, piece in
                PieceView(piece: piece, tileSize: max(18, tileSize * 0.72))
                    .scaleEffect(activePiece?.id == piece.id ? 1.06 : 1)
                    .offset(activePiece?.id == piece.id ? dragOffset : .zero)
                    .opacity(activePiece?.id == piece.id ? 0.96 : 1)
                    .gesture(pieceDragGesture(piece: piece, index: index, logicalStep: logicalStep))
                    .animation(.interactiveSpring(response: 0.22, dampingFraction: 0.82), value: activePiece?.id)
            }
        }
        .frame(maxWidth: .infinity, minHeight: 132, alignment: .bottom)
    }

    private func pieceDragGesture(piece: Piece, index: Int, logicalStep: CGFloat) -> some Gesture {
        DragGesture(minimumDistance: 6, coordinateSpace: .global)
            .onChanged { value in
                if activePiece == nil {
                    activePiece = piece
                    dragStartHaptic.prepare()
                    if hapticsEnabled {
                        dragStartHaptic.impactOccurred()
                    }
                }

                guard activePiece?.id == piece.id else { return }
                dragOffset = value.translation
                updatePreview(for: piece, location: value.location, logicalStep: logicalStep)
            }
            .onEnded { value in
                guard activePiece?.id == piece.id else { return }
                updatePreview(for: piece, location: value.location, logicalStep: logicalStep)
                finishDrag(for: piece)
            }
    }

    private func updatePreview(for piece: Piece, location: CGPoint, logicalStep: CGFloat) {
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

        if hapticsEnabled, viewModel.canPlace(piece, at: anchor.row, col: anchor.col), !didTriggerPlacementHaptic {
            stepHaptic.prepare()
            stepHaptic.selectionChanged()
            didTriggerPlacementHaptic = true
        }

        if !viewModel.canPlace(piece, at: anchor.row, col: anchor.col) {
            didTriggerPlacementHaptic = false
        }
    }

    private func finishDrag(for piece: Piece) {
        if let anchor = previewAnchor, viewModel.canPlace(piece, at: anchor.row, col: anchor.col) {
            if hapticsEnabled {
                dragEndHaptic.prepare()
                dragEndHaptic.impactOccurred()
            }
            withAnimation(.interactiveSpring(response: 0.22, dampingFraction: 0.84)) {
                viewModel.placePiece(piece, at: anchor.row, col: anchor.col)
            }
        }

        clearDragState()
    }

    private func clearDragState() {
        activePiece = nil
        dragOffset = .zero
        previewAnchor = nil
        didTriggerPlacementHaptic = false
    }

    private func isPreviewCell(row: Int, col: Int) -> Bool {
        guard let piece = activePiece, let anchor = previewAnchor else { return false }
        return piece.cells.contains { anchor.row + $0.row == row && anchor.col + $0.col == col }
    }

    private func isPreviewValid() -> Bool {
        guard let piece = activePiece, let anchor = previewAnchor else { return false }
        return viewModel.canPlace(piece, at: anchor.row, col: anchor.col)
    }

    private func position(forRow row: Int, col: Int, tileSize: CGFloat) -> CGPoint {
        CGPoint(
            x: leadingOffset(for: col, tileSize: tileSize) + tileSize / 2,
            y: leadingOffset(for: row, tileSize: tileSize) + tileSize / 2
        )
    }

    private func leadingOffset(for index: Int, tileSize: CGFloat) -> CGFloat {
        let blockJumps = index / 3
        let normalGaps = index - blockJumps
        return CGFloat(index) * tileSize + CGFloat(normalGaps) * cellSpacing + CGFloat(blockJumps) * blockSpacing
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

    var body: some View {
        RoundedRectangle(cornerRadius: 4)
            .fill(fillStyle)
            .frame(width: size, height: size)
            .overlay {
                RoundedRectangle(cornerRadius: 4)
                    .stroke(strokeStyle, lineWidth: isPreview ? 1.6 : 1)
            }
            .shadow(color: .black.opacity(tile == nil ? 0.02 : 0.08), radius: 1, y: 1)
    }

    private var fillStyle: AnyShapeStyle {
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
        if isPreview {
            return isPreviewValid ? .green : .red
        }
        return .white.opacity(tile == nil ? 0.08 : 0.25)
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
