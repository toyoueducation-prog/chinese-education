import SpriteKit

// MARK: - ⚡ PHYSICS CATEGORIES - Collision Detection System
struct PhysicsCategory {
    static let none: UInt32 = 0          // No collision category
    static let player: UInt32 = 0x1 << 0 // Player collision category
    static let enemy: UInt32 = 0x1 << 1  // Enemy collision category
}

// MARK: - 👾 NPC MANAGER - Enemy & Non-Player Character System
class NPC {
    static let shared = NPC()  // Singleton pattern
    
    // MARK: - 🎯 ENEMY MANAGEMENT
    var enemyNodes: [SKSpriteNode] = []  // Array of spawned enemy sprites

    // ✅ Spawn enemies only once
    func spawnEnemies(in scene: SKScene, count: Int) {
        let enemyTexture = SKTexture(imageNamed: "Doll2")

        for _ in 0..<count {
            var enemyPosition: CGPoint

            repeat {
                enemyPosition = CGPoint(x: CGFloat.random(in: 100...scene.size.width - 800),
                                        y: CGFloat.random(in: 100...scene.size.height - 800))
            } while isPositionOccupied(enemyPosition, scene: scene)

            let enemy = SKSpriteNode(texture: enemyTexture)
            enemy.position = enemyPosition
            enemy.size = CGSize(width: 60, height: 60)

            // ✅ Add physics body for collision detection
            enemy.physicsBody = SKPhysicsBody(rectangleOf: enemy.size)
            enemy.physicsBody?.isDynamic = false
            enemy.physicsBody?.categoryBitMask = PhysicsCategory.enemy
            enemy.physicsBody?.contactTestBitMask = PhysicsCategory.player
            enemy.physicsBody?.collisionBitMask = PhysicsCategory.none

            enemy.name = "enemy"
            scene.addChild(enemy)
            enemyNodes.append(enemy)

            // ✅ Add patrol movement
            patrolEnemy(enemy: enemy,scene: scene)
        }
    }

    // ✅ Enemy patrol logic
    private func patrolEnemy(enemy: SKSpriteNode, scene: SKScene) {
        let moveDistance: CGFloat = 100  // Distance per move
        let moveDuration: TimeInterval = 2  // Speed of movement

        func getValidRandomPosition() -> CGPoint {
            var newPosition: CGPoint
            var attempts = 0  // ✅ Prevent infinite loops
            repeat {
                let dx = [moveDistance, -moveDistance].randomElement()!
                let dy = [moveDistance, -moveDistance].randomElement()!
                newPosition = CGPoint(x: enemy.position.x + dx, y: enemy.position.y + dy)
                attempts += 1
                if attempts > 10 { break }  // ✅ Fallback to avoid infinite loops
            } while isPositionOccupied(newPosition, scene: scene)

            return newPosition
        }

        let moveAction = SKAction.run {
            let nextPosition = getValidRandomPosition()
            let move = SKAction.move(to: nextPosition, duration: moveDuration)
            enemy.run(move)
        }

        let wait = SKAction.wait(forDuration: 2)
        let patrolSequence = SKAction.sequence([moveAction, wait])
        let repeatPatrol = SKAction.repeatForever(patrolSequence)

        enemy.run(repeatPatrol)
    }



    // ✅ Check if position is occupied by trees
    private func isPositionOccupied(_ position: CGPoint, scene: SKScene) -> Bool {
        for node in scene.children {
            if node.name == "tree" && abs(node.position.x - position.x) < 60 && abs(node.position.y - position.y) < 100 {
                return true  // ✅ Prevents NPCs from moving into trees
            }
        }
        return false
    }

}
