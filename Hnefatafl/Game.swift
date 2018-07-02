//
//  Game.swift
//  Hnefatafl
//
//  Created by Joshua Homann on 7/1/18.
//  Copyright © 2018 com.josh. All rights reserved.
//

import Foundation

struct Game {
    let dimension: Int
    private let cornerIndices: [Int]
    enum Piece: Int {
        case king = 1, defender = 2, attacker = 3
    }
    enum Player {
        case defender, attacker
    }
    enum State {
        case playing, defenderWon, attackerWon
    }
    var currentPlayer = Player.attacker
    var calculatedCurrentState: Game.State {
        guard board.contains(where: {$0 == .king}) else {
            return .attackerWon
        }
        guard cornerIndices.map({board[$0]}).contains(.king) == false else {
            return .defenderWon
        }
        return .playing
    }
    private var board: [Piece?]
    init() {
        board = [0,0,0,3,3,3,0,0,0,
                 0,0,0,0,3,0,0,0,0,
                 0,0,0,0,2,0,0,0,0,
                 3,0,0,0,2,0,0,0,3,
                 3,3,2,2,1,2,2,3,3,
                 3,0,0,0,2,0,0,0,3,
                 0,0,0,0,2,0,0,0,0,
                 0,0,0,0,3,0,0,0,0,
                 0,0,0,3,3,3,0,0,0].map(Piece.init(rawValue:))
        dimension = 9
        cornerIndices = [0, dimension-1, (dimension-1)*dimension, dimension*dimension-1]
    }
    func pieceAt(x: Int, y: Int) -> Piece? {
        return board[x + y * dimension]
    }
    func canSelect(x: Int, y: Int) -> Bool {
        guard let piece = board[x+y*dimension] else {
            return false
        }
        switch currentPlayer {
        case .attacker:
            return  piece == .attacker
        case .defender:
            return piece == .defender || piece == .king
        }
    }
    func validMovesFrom(x: Int, y: Int) -> [(Int, Int)] {
        guard canSelect(x: x, y: y) else {
            return []
        }
        let lower = ((0..<y).reversed().first { board[x+$0*dimension] != nil } ?? -1) + 1
        let left  = ((0..<x).reversed().first { board[$0+y*dimension] != nil } ?? -1) + 1
        let upper = ((y+1..<dimension).first { board[x+$0*dimension] != nil } ?? dimension)
        let right = ((x+1..<dimension).first { board[$0+y*dimension] != nil } ?? dimension)
        let vertical = (lower..<upper).filter {$0 != y}.map { (x, $0) }
        let horizontal = (left..<right).filter {$0 != x}.map { ($0, y) }
        let moves = [vertical, horizontal].flatMap {$0}
        return board[x+y*dimension] == .king ? moves : moves.filter {!cornerIndices.contains($0.0+$0.1*dimension)}
    }
    mutating func moveFrom(_ start: (x:Int,y:Int), to end: (Int,Int)) -> [(Int,Int)] {
        let (x,y) = end
        board.swapAt(x+y*dimension, start.x + start.y*dimension)
        let piecesToCaputure: Set<Piece> = currentPlayer == .defender ? [.attacker] : [.defender, .king]
        let capturingPieces: Set<Piece> = currentPlayer == .defender ?  [.defender, .king] : [.attacker]
        let adjacency: [(Int, Int)] = [(0,-1), (0, 1), (-1,0), (1, 0)]
        let capturedPieces = adjacency.compactMap { (offset: (Int, Int)) ->  (Int, Int)? in
            let (offsetX, offsetY) = offset
            let proposedCapturingX = x + offsetX * 2
            let proposedCapturingY = y + offsetY * 2
            guard (0..<dimension).contains(proposedCapturingX) && (0..<dimension).contains(proposedCapturingY),
                let capturingPiece = board[(x + offsetX * 2) + (y + offsetY * 2) * dimension],
                capturingPieces.contains(capturingPiece),
                let pieceToCapture = board[x + offsetX + (y + offsetY) * dimension],
                piecesToCaputure.contains(pieceToCapture) else {
                    return nil
            }
            return (x + offsetX, y + offsetY)
        }
        capturedPieces.forEach{ index in
            let (x, y) = index
            board[x + y * dimension] = nil
        }
        currentPlayer = currentPlayer == .attacker ? .defender : .attacker
        return capturedPieces
    }
}
