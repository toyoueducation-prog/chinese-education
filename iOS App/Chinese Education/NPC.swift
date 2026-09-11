import SpriteKit

/**
 * NPC MANAGER - Enemy & Non-Player Character System
 * 
 * Manages all non-player characters (enemies) in the game world.
 * This singleton class handles:
 * - Enemy spawning with position validation
 * - Enemy patrol/movement patterns
 * - Boundary clamping to keep enemies within map bounds
 * - Collision detection preparation
 * 
 * Enemy Behavior:
 * - Enemies spawn randomly within map boundaries
 * - They patrol in random directions
 * - Continuously clamped to stay within map bounds
 * - Round-shaped sprites (matching player appearance)
 * 
 * Spawning Logic:
 * - Validates positions to avoid obstacles and player spawn
 * - Uses map boundaries (21x20 grid, 64x64 tiles)
 * - Maximum 2 enemies spawned at once
 * - Enemies stored as SKNode (can be SKSpriteNode or SKCropNode)
 */

// MARK: - ⚡ PHYSICS CATEGORIES - Collision Detection System
/**
 * Defines physics categories for collision detection.
 * Used to identify different types of game objects in physics contacts.
 */
struct PhysicsCategory {
    static let none: UInt32 = 0          // No collision category
    static let player: UInt32 = 0x1 << 0 // Player collision category
    static let enemy: UInt32 = 0x1 << 1  // Enemy collision category
}

// MARK: - 👾 NPC MANAGER - Enemy & Non-Player Character System
class NPC {
    static let shared = NPC()  // Singleton pattern
    
    // MARK: - 🎯 ENEMY MANAGEMENT
    var enemyNodes: [SKNode] = []  // Array of spawned enemy nodes (can be SKSpriteNode or SKCropNode)
    var completedEnemyIdentifiers: Set<String> = []  // Track completed enemies by identifier

    // ✅ Spawn enemies only once
    func spawnEnemies(in scene: SKScene, count: Int) {
        // ✅ Filter out completed enemies first
        enemyNodes = enemyNodes.filter { enemy in
            let enemyId = enemy.userData?["identifier"] as? String ?? ""
            return !completedEnemyIdentifiers.contains(enemyId)
        }
        
        // ✅ Calculate how many enemies we need to spawn
        // ✅ Only count enemies that are in the current scene and not completed
        let currentActiveCount = enemyNodes.filter { enemy in
            let enemyId = enemy.userData?["identifier"] as? String ?? ""
            return !completedEnemyIdentifiers.contains(enemyId) && 
                   enemy.parent === scene &&  // ✅ Must be in current scene
                   !enemy.isHidden
        }.count
        
        let enemiesToSpawn = max(0, count - currentActiveCount)
        
        guard enemiesToSpawn > 0 else {
            print("✅ Already have \(currentActiveCount) active enemies, no need to spawn more")
            return
        }
        
        let enemySize = CGSize(width: 60, height: 60)

        for _ in 0..<enemiesToSpawn {
            // ✅ Initialize with a safe default position (will be replaced if valid position found)
            var enemyPosition = CGPoint(x: 0, y: 0)
            var attempts = 0
            var foundValidPosition = false

            // ✅ Use map boundaries - exclude stone wall boundaries (first and last row/col)
            let tileSize: CGFloat = 64
            let mapWidth = 21 * tileSize
            let mapHeight = 20 * tileSize
            // ✅ Exclude outer stone walls (first and last row/col are walls)
            // Spawn within inner area (rows 1-18, cols 1-19) to avoid walls
            let mapBounds = (
                minX: -mapWidth / 2 + tileSize + 30,  // Skip first column (stone wall) + margin
                maxX: mapWidth / 2 - tileSize - 30,   // Skip last column (stone wall) - margin
                minY: -mapHeight / 2 + tileSize + 30, // Skip first row (stone wall) + margin
                maxY: mapHeight / 2 - tileSize - 30   // Skip last row (stone wall) - margin
            )

            repeat {
                // ✅ Spawn within map boundaries (excluding stone walls)
                let randomX = CGFloat.random(in: mapBounds.minX...mapBounds.maxX)
                let randomY = CGFloat.random(in: mapBounds.minY...mapBounds.maxY)
                let candidatePosition = CGPoint(x: randomX, y: randomY)
                
                // ✅ Validate position - must be walkable (not on walls, trees, or water)
                if !isPositionOccupied(candidatePosition, scene: scene) && isValidMovementPosition(candidatePosition, scene: scene) {
                    // ✅ Double-check: ensure not on stone wall, tree, or water tile
                    if let tileType = getTileTypeAtPosition(candidatePosition, scene: scene) {
                        // ✅ Only accept walkable tiles (not S, T, W)
                        if !["S", "T", "W"].contains(tileType) {
                            enemyPosition = candidatePosition
                            foundValidPosition = true
                        }
                    } else {
                        // ✅ If can't determine tile type, trust isValidMovementPosition result
                        enemyPosition = candidatePosition
                        foundValidPosition = true
                    }
                }
                
                attempts += 1
                if attempts > 200 {  // ✅ Increased attempts for better chance of finding valid position
                    // ✅ Fallback: try a few known walkable positions
                    let fallbackPositions = [
                        CGPoint(x: 0, y: 0),        // Center
                        CGPoint(x: -200, y: 0),     // Left center
                        CGPoint(x: 200, y: 0),      // Right center
                        CGPoint(x: 0, y: -200),     // Bottom center
                        CGPoint(x: 0, y: 200)        // Top center
                    ]
                    for fallbackPos in fallbackPositions {
                        if isValidMovementPosition(fallbackPos, scene: scene) {
                            if let tileType = getTileTypeAtPosition(fallbackPos, scene: scene) {
                                if !["S", "T", "W"].contains(tileType) {
                                    enemyPosition = fallbackPos
                                    foundValidPosition = true
                                    break
                                }
                            } else {
                                enemyPosition = fallbackPos
                                foundValidPosition = true
                                break
                            }
                        }
                    }
                    if !foundValidPosition {
                        enemyPosition = CGPoint(x: 0, y: 0)  // Last resort
                        foundValidPosition = true
                    }
                    break
                }
            } while !foundValidPosition

            // ✅ Ensure position is clamped to bounds (double-check)
            enemyPosition = clampToMapBounds(enemyPosition, scene: scene)

            // ✅ Create enemy image with oval/circular shape (same as player)
            let originalEnemyImage = SKSpriteNode(imageNamed: "Doll2")
            originalEnemyImage.size = enemySize
            
            // ✅ Create circular mask for oval shape
            let maskNode = SKShapeNode(ellipseOf: enemySize)
            maskNode.fillColor = .white
            maskNode.strokeColor = .clear
            
            // ✅ Use SKCropNode to create circular/oval visual shape
            let enemyCropNode = SKCropNode()
            enemyCropNode.maskNode = maskNode
            enemyCropNode.addChild(originalEnemyImage)
            enemyCropNode.position = enemyPosition  // ✅ Position is now guaranteed to be within bounds
            originalEnemyImage.position = CGPoint.zero  // Relative to cropNode
            enemyCropNode.name = "enemy"

            // ✅ Add physics body for collision detection (circular like player)
            let radius = min(enemySize.width, enemySize.height) / 2
            enemyCropNode.physicsBody = SKPhysicsBody(circleOfRadius: radius)
            enemyCropNode.physicsBody?.isDynamic = false
            enemyCropNode.physicsBody?.categoryBitMask = PhysicsCategory.enemy
            enemyCropNode.physicsBody?.contactTestBitMask = PhysicsCategory.player
            enemyCropNode.physicsBody?.collisionBitMask = PhysicsCategory.none

            scene.addChild(enemyCropNode)
            
            // ✅ Give each enemy a unique identifier
            let enemyIdentifier = "enemy_\(UUID().uuidString)"
            enemyCropNode.userData = NSMutableDictionary()
            enemyCropNode.userData?["identifier"] = enemyIdentifier
            
            // ✅ Store the cropNode directly
            enemyNodes.append(enemyCropNode)

            // ✅ Add patrol movement (pass the cropNode)
            patrolEnemy(enemy: enemyCropNode, scene: scene)
        }
    }

    // ✅ Enemy patrol logic
    private func patrolEnemy(enemy: SKNode, scene: SKScene) {
        let moveDistance: CGFloat = 100  // Distance per move
        let moveDuration: TimeInterval = 2  // Speed of movement

        func getValidRandomPosition() -> CGPoint {
            var newPosition: CGPoint
            var attempts = 0  // ✅ Prevent infinite loops
            repeat {
                let dx = [moveDistance, -moveDistance].randomElement()!
                let dy = [moveDistance, -moveDistance].randomElement()!
                let proposedPosition = CGPoint(x: enemy.position.x + dx, y: enemy.position.y + dy)
                
                // ✅ Clamp to map boundaries (excluding stone walls)
                newPosition = clampToMapBounds(proposedPosition, scene: scene)
                
                // ✅ Ensure the new position is walkable (not on walls, trees, or water)
                if let tileType = getTileTypeAtPosition(newPosition, scene: scene) {
                    if ["S", "T", "W"].contains(tileType) {
                        // ✅ Position is on a wall/tree/water, try again
                        attempts += 1
                        if attempts > 10 { break }  // ✅ Fallback to avoid infinite loops
                        continue
                    }
                }
                
                attempts += 1
                if attempts > 10 { break }  // ✅ Fallback to avoid infinite loops
            } while isPositionOccupied(newPosition, scene: scene) || !isValidMovementPosition(newPosition, scene: scene)

            return newPosition
        }

        let moveAction = SKAction.run { [weak self] in
            guard let self = self else { return }
            // ✅ Clamp current position first (in case enemy somehow moved outside)
            let currentClamped = self.clampToMapBounds(enemy.position, scene: scene)
            if enemy.position != currentClamped {
                enemy.position = currentClamped
                print("⚠️ Enemy position corrected before movement: \(currentClamped)")
            }
            
            let nextPosition = getValidRandomPosition()
            // ✅ Ensure final position is within bounds BEFORE starting movement
            let clampedPosition = self.clampToMapBounds(nextPosition, scene: scene)
            
            // ✅ Only move if position changed
            guard clampedPosition != enemy.position else {
                return  // Skip movement if already at target
            }
            
            // ✅ Use custom action that clamps during movement
            let startPosition = enemy.position
            let move = SKAction.customAction(withDuration: moveDuration) { [weak self] node, elapsedTime in
                guard let self = self else { return }
                // ✅ Interpolate position
                let progress = min(elapsedTime / moveDuration, 1.0)
                let currentX = startPosition.x + (clampedPosition.x - startPosition.x) * CGFloat(progress)
                let currentY = startPosition.y + (clampedPosition.y - startPosition.y) * CGFloat(progress)
                let interpolatedPos = CGPoint(x: currentX, y: currentY)
                
                // ✅ Clamp the interpolated position continuously
                let clamped = self.clampToMapBounds(interpolatedPos, scene: scene)
                enemy.position = clamped
            }
            
            enemy.run(move) { [weak self] in
                // ✅ Final check and clamp after movement completes
                guard let self = self else { return }
                let finalClamped = self.clampToMapBounds(enemy.position, scene: scene)
                if enemy.position != finalClamped {
                    enemy.position = finalClamped
                }
            }
        }

        let wait = SKAction.wait(forDuration: 2)
        let patrolSequence = SKAction.sequence([moveAction, wait])
        let repeatPatrol = SKAction.repeatForever(patrolSequence)

        enemy.run(repeatPatrol, withKey: "patrol")  // ✅ Add key to track patrol action
    }
    
    // ✅ Restart patrol for an enemy (used when re-adding enemies to scene)
    func restartPatrol(for enemy: SKNode, in scene: SKScene) {
        // ✅ Remove existing patrol action if any
        enemy.removeAction(forKey: "patrol")
        // ✅ Start new patrol
        patrolEnemy(enemy: enemy, scene: scene)
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
    
    // ✅ Clamp enemy position to map boundaries (excluding stone walls)
    private func clampToMapBounds(_ position: CGPoint, scene: SKScene) -> CGPoint {
        // ✅ Original map boundaries: 21x20 grid, 64x64 tiles
        // ✅ Exclude outer stone walls to keep enemies within walkable area
        let tileSize: CGFloat = 64
        let mapWidth = 21 * tileSize
        let mapHeight = 20 * tileSize
        // ✅ Keep enemies within inner area (not on stone wall boundaries)
        let mapBounds = (
            minX: -mapWidth / 2 + tileSize + 30,  // Skip first column (stone wall) + margin
            maxX: mapWidth / 2 - tileSize - 30,   // Skip last column (stone wall) - margin
            minY: -mapHeight / 2 + tileSize + 30, // Skip first row (stone wall) + margin
            maxY: mapHeight / 2 - tileSize - 30   // Skip last row (stone wall) - margin
        )
        
        // ✅ Clamp position to map boundaries (within walkable area)
        var clampedX = max(mapBounds.minX, min(mapBounds.maxX, position.x))
        var clampedY = max(mapBounds.minY, min(mapBounds.maxY, position.y))
        
        // ✅ Additional check: if clamped position is on a wall/tree/water, try to find nearby walkable position
        if let tileType = getTileTypeAtPosition(CGPoint(x: clampedX, y: clampedY), scene: scene) {
            if ["S", "T", "W"].contains(tileType) {
                // ✅ Try to find a nearby walkable position
                let searchRadius: CGFloat = tileSize
                var foundWalkable = false
                for offsetX in stride(from: -searchRadius, through: searchRadius, by: tileSize / 2) {
                    for offsetY in stride(from: -searchRadius, through: searchRadius, by: tileSize / 2) {
                        let testPos = CGPoint(x: clampedX + offsetX, y: clampedY + offsetY)
                        if let testTileType = getTileTypeAtPosition(testPos, scene: scene) {
                            if !["S", "T", "W"].contains(testTileType) {
                                clampedX = testPos.x
                                clampedY = testPos.y
                                foundWalkable = true
                                break
                            }
                        }
                    }
                    if foundWalkable { break }
                }
            }
        }
        
        return CGPoint(x: clampedX, y: clampedY)
    }
    
    // ✅ Get tile type at a given position by checking nearby tile nodes
    private func getTileTypeAtPosition(_ position: CGPoint, scene: SKScene) -> Character? {
        let tileSize: CGFloat = 64
        
        // ✅ Find the tile node closest to this position
        var closestTile: SKSpriteNode? = nil
        var closestDistance: CGFloat = CGFloat.greatestFiniteMagnitude
        
        for node in scene.children {
            if let sprite = node as? SKSpriteNode,
               sprite.zPosition == -1,
               let nodeName = sprite.name,
               nodeName.hasPrefix("mapTile_") {
                let distanceX = abs(sprite.position.x - position.x)
                let distanceY = abs(sprite.position.y - position.y)
                let distance = sqrt(distanceX * distanceX + distanceY * distanceY)
                
                // ✅ If within one tile distance, this is the tile
                if distance < tileSize && distance < closestDistance {
                    closestTile = sprite
                    closestDistance = distance
                }
            }
        }
        
        guard let tile = closestTile else { return nil }
        
        // ✅ Check if it has a physics body (collision tile: S, T, W)
        if tile.physicsBody != nil {
            // ✅ Determine type by checking texture name or image name
            // Try to get the texture name from the node
            if let textureName = tile.texture?.description.lowercased() {
                if textureName.contains("stone") {
                    return "S"  // Stone wall
                } else if textureName.contains("tree") {
                    return "T"  // Tree
                } else if textureName.contains("water") {
                    return "W"  // Water
                }
            }
            // ✅ Default to stone if has physics body but can't determine type
            return "S"
        } else {
            // ✅ Walkable tile (grass, path) - no physics body
            return "."  // Walkable
        }
    }
    
    // ✅ Check if position is valid for movement (not in collision areas)
    private func isValidMovementPosition(_ position: CGPoint, scene: SKScene) -> Bool {
        // ✅ First check if position is on a stone wall, tree, or water using tile type
        if let tileType = getTileTypeAtPosition(position, scene: scene) {
            // ✅ Only walkable tiles are ".", "G", "P" (grass paths, grass areas, player spawn)
            if ["S", "T", "W"].contains(tileType) {
                return false  // Stone walls, trees, and water are not walkable
            }
        }
        
        // ✅ Also check collision with trees by name (backup check)
        let tileSize: CGFloat = 64
        let checkRadius: CGFloat = tileSize / 2 + 10  // Half tile + small margin
        
        for node in scene.children {
            // Check for trees (by name)
            if node.name == "tree" {
                let distance = sqrt(pow(node.position.x - position.x, 2) + pow(node.position.y - position.y, 2))
                if distance < checkRadius {
                    return false
                }
            }
            
            // ✅ Check for collision tiles (water, stone) by checking map tiles with physics bodies
            if let sprite = node as? SKSpriteNode,
               sprite.zPosition == -1,
               let nodeName = sprite.name,
               nodeName.hasPrefix("mapTile_") {
                // Check if this tile is within one tile distance
                let distanceX = abs(sprite.position.x - position.x)
                let distanceY = abs(sprite.position.y - position.y)
                
                // If within tile bounds, check if it's a collision tile
                if distanceX < tileSize && distanceY < tileSize {
                    // ✅ Collision tiles have physics bodies (water, stone, trees)
                    // If the tile has a physics body, it's a collision area
                    if sprite.physicsBody != nil {
                        return false
                    }
                }
            }
        }
        
        return true
    }

}
