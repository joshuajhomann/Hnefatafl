//
//  GameScene.swift
//  Hnefatafl
//
//  Created by Joshua Homann on 6/30/18.
//  Copyright © 2018 com.josh. All rights reserved.
//

import SpriteKit
import GameplayKit

class GameScene: SKScene {

    private var game = Game()
    private var lastCaluculatedState = Game.State.playing
    private var selectedIndex: Int?
    private var selectionGroup = SKShapeNode()
    private var selectionNodes: [SKShapeNode] = []
    private var backgroundGroup = SKNode()
    private var backgroundNodes: [SKNode] = []
    private var pieceGroup = SKNode()
    private var pieceNodes: [SKShapeNode] = []
    private var isAnimating = false
    private let colorForPiece: [Game.Piece: UIColor] = [.attacker: .red, .defender: .blue, .king: .green]
    private let titleNode = SKLabelNode()
    private let pulse = SKAction.repeatForever(SKAction.sequence([SKAction.fadeAlpha(to: 0.67, duration: 1.5),
                                                                  SKAction.fadeAlpha(to: 0.33, duration: 1.5)]))

    override func didMove(to view: SKView) {
        anchorPoint = CGPoint(x: 0.5, y: 0.5)
        size = view.bounds.size
        let minimumDimension = min(size.width, size.height)
        let pointsPerSquare = minimumDimension / CGFloat(game.dimension)
        backgroundNodes = (0 ..< game.dimension).flatMap { y in
            (0 ..< game.dimension).map { x in
                let color: UIColor = {
                    if (x == 0 || x == game.dimension - 1) && ( y == 0 || y == game.dimension - 1) {
                        return #colorLiteral(red: 1.0, green: 1.0, blue: 1.0, alpha: 1.0)
                    } else if (x == game.dimension / 2 && y == game.dimension / 2) {
                        return #colorLiteral(red: 0.2549019754, green: 0.2745098174, blue: 0.3019607961, alpha: 1)
                    }
                    return (x % 2 == y % 2) ? #colorLiteral(red: 0.501960814, green: 0.501960814, blue: 0.501960814, alpha: 1) : #colorLiteral(red: 0.8039215803, green: 0.8039215803, blue: 0.8039215803, alpha: 1)
                }()
                let node = SKSpriteNode(color: color, size: CGSize(width: pointsPerSquare - 1 , height: pointsPerSquare - 1 ))
                node.position.x = CGFloat(x) * pointsPerSquare - minimumDimension / 2 + pointsPerSquare / 2
                node.position.y = CGFloat(y) * pointsPerSquare - minimumDimension / 2 + pointsPerSquare / 2
                node.zPosition = -10
                return node
            }
        }
        backgroundNodes.forEach { self.backgroundGroup.addChild($0) }
        addChild(backgroundGroup)
        pieceNodes = (0 ..< game.dimension).flatMap { y in
            (0 ..< game.dimension).map { x in
                let diameter = pointsPerSquare - 24
                let node = SKShapeNode(ellipseIn: CGRect(x: 0, y: 0, width: diameter, height: diameter))
                node.strokeColor = .clear
                node.position.x = CGFloat(x) * pointsPerSquare - minimumDimension / 2 + (pointsPerSquare - diameter) / 2
                node.position.y = CGFloat(y) * pointsPerSquare - minimumDimension / 2 + (pointsPerSquare - diameter) / 2
                node.zPosition = 10
                return node
            }
        }
        pieceNodes.forEach { self.pieceGroup.addChild($0) }
        addChild(pieceGroup)
        selectionNodes = (0 ..< game.dimension).flatMap { y in
            (0 ..< game.dimension).map { x in
                let diameter = pointsPerSquare - 12
                let node = SKShapeNode(path: UIBezierPath(roundedRect: CGRect(x: -diameter/2, y:  -diameter/2, width: diameter, height: diameter), cornerRadius: 12).cgPath)
                node.strokeColor = .clear
                node.position.x = CGFloat(x) * pointsPerSquare - minimumDimension / 2 + (pointsPerSquare) / 2
                node.position.y = CGFloat(y) * pointsPerSquare - minimumDimension / 2 + (pointsPerSquare) / 2
                node.zPosition = 0
                return node
            }
        }
        selectionNodes.forEach { self.selectionGroup.addChild($0) }
        addChild(selectionGroup)
        titleNode.position = CGPoint(x: 0, y: minimumDimension / 2 + 10)
        addChild(titleNode)
        setupBoard()
    }

    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard isAnimating == false,
              lastCaluculatedState == .playing,
              let location = touches.first?.location(in: self),
              let node = backgroundGroup.nodes(at: location).first,
              let index = backgroundNodes.index(of: node) else {
            return
        }
        guard index != selectedIndex else {
            deselect()
            return
        }
        let x = index % game.dimension
        let y = index / game.dimension
        guard let previouslySelectedIndex = selectedIndex else {
            guard game.canSelect(x: x, y: y) else {
                return
            }
            highlightNode(x: x, y: y, color: #colorLiteral(red: 0.9686274529, green: 0.78039217, blue: 0.3450980484, alpha: 1))
            game.validMovesFrom(x: x, y: y).forEach { self.highlightNode(x: $0.0, y: $0.1, color: #colorLiteral(red: 0.4666666687, green: 0.7647058964, blue: 0.2666666806, alpha: 1))}
            selectedIndex = index
            return
        }
        let originX = previouslySelectedIndex % game.dimension
        let originY = previouslySelectedIndex / game.dimension
        let possibleMoves = game.validMovesFrom(x: originX, y: originY)
        guard possibleMoves.contains(where: {$0.0 == x && $0.1 == y }) else {
            return
        }
        deselect()
        let capturedPieces = game.moveFrom((originX, originY), to: (x, y))
                             .map {($0.0, $0.1, self.pieceNodes[$0.0 + $0.1 * self.game.dimension].fillColor)}
        setupBoard()
        let origin = pieceNodes[originX+originY*game.dimension].position
        let destination = pieceNodes[x+y*game.dimension].position
        pieceNodes[x+y*game.dimension].position = origin
        isAnimating = true
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.66) { self.isAnimating = false }
        pieceNodes[x+y*game.dimension].run(SKAction.move(to: destination, duration: 0.33))
        capturedPieces.forEach { pieceInfo in
            let (x,y,color) = pieceInfo
            self.pieceNodes[x+y*game.dimension].fillColor = color
            self.pieceNodes[x+y*game.dimension].run(SKAction.sequence([SKAction.wait(forDuration: 0.33),
                                                                       SKAction.fadeAlpha(to: 0, duration: 0.33)]))
        }
    }

    private func highlightNode(x: Int, y: Int, color: UIColor) {
        selectionNodes[x+y*game.dimension].fillColor = color
        selectionNodes[x+y*game.dimension].run(pulse)
    }

    private func deselect() {
        selectionNodes.forEach { node in
            node.fillColor = .clear
            node.removeAllActions()
        }
        selectedIndex = nil
    }

    private func setupBoard() {
        (0..<game.dimension).forEach { y in
            (0..<game.dimension).forEach { x in
                self.pieceNodes[x+y*self.game.dimension].fillColor = self.game.pieceAt(x: x, y: y).flatMap{colorForPiece[$0]} ??
                                                                     .clear
            }
        }
        lastCaluculatedState = game.calculatedCurrentState
        let titleText: NSAttributedString
        switch lastCaluculatedState {
        case .playing:
            titleText = NSAttributedString(string: game.currentPlayer == .attacker ? "Attackers Turn" : "Defender's Turn",
                                           attributes: [.font: UIFont.systemFont(ofSize: 50),
                                                        .foregroundColor: game.currentPlayer == .attacker ? #colorLiteral(red: 1, green: 0.6702818274, blue: 0.6999756694, alpha: 1) : #colorLiteral(red: 0.6327980757, green: 0.8252108097, blue: 0.8650574088, alpha: 1)])
        case .defenderWon:
            titleText =  NSAttributedString(string: "Defender Won!",
                                            attributes: [.font: UIFont.boldSystemFont(ofSize: 72),.foregroundColor: #colorLiteral(red: 0.2392156869, green: 0.6745098233, blue: 0.9686274529, alpha: 1)])
        case .attackerWon:
            titleText =  NSAttributedString(string: "Attacker Won!",
                                            attributes: [.font: UIFont.boldSystemFont(ofSize: 72),.foregroundColor: #colorLiteral(red: 0.8549019694, green: 0.250980407, blue: 0.4784313738, alpha: 1)])
        }
        titleNode.attributedText = titleText
    }
}



