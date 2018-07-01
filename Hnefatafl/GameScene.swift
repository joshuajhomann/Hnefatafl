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
    private var selectedIndex: Int?
    private var selectionNode: SKShapeNode!
    private var backgroundNodes: [SKNode] = []
    private var backgroundGroup = SKNode()
    private var pieceGroup = SKNode()
    private var pieceNodes: [SKShapeNode] = []
    private let colorForPiece: [Game.Piece: UIColor] = [.attacker: .red, .defender: .blue, .king: .green]

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
        let radius = (pointsPerSquare - 12) / 2
        selectionNode = SKShapeNode(path: UIBezierPath(roundedRect: CGRect(x: -radius, y:  -radius, width: 2*radius, height: 2*radius), cornerRadius: 12).cgPath)
        selectionNode.strokeColor = .clear
        addChild(selectionNode)
        setupPieces()
    }

    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard let location = touches.first?.location(in: self),
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
            selectionNode.removeAllActions()
            selectionNode.fillColor = .yellow
            selectionNode.position = node.position
            selectionNode.run(SKAction.repeatForever(
                SKAction.sequence(
                    [SKAction.fadeAlpha(to: 0.75, duration: 1.5),
                     SKAction.fadeAlpha(to: 0.25, duration: 1.5)])
                )
            )
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
        game.moveFrom((originX, originY), to: (x, y))
        setupPieces()
    }

    private func deselect() {
        selectionNode.fillColor = .clear
        selectionNode.removeAllActions()
        selectedIndex = nil
    }

    private func setupPieces() {
        (0..<game.dimension).forEach { y in
            (0..<game.dimension).forEach { x in
                self.pieceNodes[x+y*self.game.dimension].fillColor = self.game.pieceAt(x: x, y: y).flatMap{colorForPiece[$0]} ??
                                                                     .clear
            }
        }
    }
}



