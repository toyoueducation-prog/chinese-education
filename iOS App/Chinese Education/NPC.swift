import SpriteKit
import AVFoundation
#if os(iOS)
import UIKit
#endif

/**
 * NPC MANAGER - 森林守護者 (Forest Guardian) System
 *
 * Manages forest guardians on the map. Guardians are storybook animals
 * (fox / owl) the player meets for reading encounters — not monsters.
 */

struct PhysicsCategory {
    static let none: UInt32 = 0
    static let player: UInt32 = 0x1 << 0
    static let enemy: UInt32 = 0x1 << 1  // Collision bit for 森林守護者
}

class NPC {
    static let shared = NPC()

    /// Active guardian nodes on / across scenes (node name remains "enemy" for physics contacts).
    var enemyNodes: [SKNode] = []
    var completedEnemyIdentifiers: Set<String> = []
    var pendingEncounterEnemyId: String?

    private static let pendingEncounterKey = "pendingEncounterEnemyId"

    /// Two animal types for the pair of guardians on each map.
    private let guardianSpriteNames = ["GuardianFox", "GuardianOwl"]
    private let guardianWalkVideos = ["guardian_fox_walk", "guardian_owl_walk"]

    private init() {}

    func beginEncounter(enemyId: String) {
        pendingEncounterEnemyId = enemyId
        UserDefaults.standard.set(enemyId, forKey: Self.pendingEncounterKey)
    }

    func completePendingEncounter(enemyId: String? = nil) {
        let id = enemyId ?? pendingEncounterEnemyId ?? UserDefaults.standard.string(forKey: Self.pendingEncounterKey)
        if let id = id {
            completedEnemyIdentifiers.insert(id)
            print("✅ 森林守護者相遇完成。ID: \(id)")
        }
        clearPendingEncounter()
    }

    func abandonPendingEncounter() {
        if let id = pendingEncounterEnemyId ?? UserDefaults.standard.string(forKey: Self.pendingEncounterKey) {
            print("↩️ 離開提問；森林守護者仍在。ID: \(id)")
        }
        clearPendingEncounter()
    }

    private func clearPendingEncounter() {
        pendingEncounterEnemyId = nil
        UserDefaults.standard.removeObject(forKey: Self.pendingEncounterKey)
    }

    /// Spawn up to `count` 森林守護者 (default 2: fox + owl).
    func spawnEnemies(in scene: SKScene, count: Int) {
        enemyNodes = enemyNodes.filter { node in
            let id = node.userData?["identifier"] as? String ?? ""
            return !completedEnemyIdentifiers.contains(id)
        }

        let currentActiveCount = enemyNodes.filter { node in
            let id = node.userData?["identifier"] as? String ?? ""
            return !completedEnemyIdentifiers.contains(id)
        }.count

        let toSpawn = max(0, count - currentActiveCount)
        guard toSpawn > 0 else {
            print("✅ 已有 \(currentActiveCount) 位森林守護者，無需再生成")
            return
        }

        let guardianSize = CGSize(width: 72, height: 72)
        var usedTypes = Set(enemyNodes.compactMap { $0.userData?["guardianType"] as? String })

        for i in 0..<toSpawn {
            var typeIndex = i % guardianSpriteNames.count
            // Prefer unused animal type so the pair is fox + owl.
            for (idx, name) in guardianSpriteNames.enumerated() where !usedTypes.contains(name) {
                typeIndex = idx
                break
            }
            let spriteName = guardianSpriteNames[typeIndex]
            let walkName = guardianWalkVideos[typeIndex]
            usedTypes.insert(spriteName)

            var position = CGPoint.zero
            var attempts = 0
            var found = false

            let tileSize: CGFloat = 64
            let mapWidth = 21 * tileSize
            let mapHeight = 20 * tileSize
            let mapBounds = (
                minX: -mapWidth / 2 + tileSize + 30,
                maxX: mapWidth / 2 - tileSize - 30,
                minY: -mapHeight / 2 + tileSize + 30,
                maxY: mapHeight / 2 - tileSize - 30
            )

            repeat {
                let candidate = CGPoint(
                    x: CGFloat.random(in: mapBounds.minX...mapBounds.maxX),
                    y: CGFloat.random(in: mapBounds.minY...mapBounds.maxY)
                )
                if !isPositionOccupied(candidate, scene: scene) && isValidMovementPosition(candidate, scene: scene) {
                    if let tileType = getTileTypeAtPosition(candidate, scene: scene) {
                        if !["S", "T", "W"].contains(tileType) {
                            position = candidate
                            found = true
                        }
                    } else {
                        position = candidate
                        found = true
                    }
                }
                attempts += 1
                if attempts > 200 {
                    let fallbacks = [
                        CGPoint(x: 0, y: 0), CGPoint(x: -200, y: 0),
                        CGPoint(x: 200, y: 0), CGPoint(x: 0, y: -200), CGPoint(x: 0, y: 200)
                    ]
                    for fallback in fallbacks where isValidMovementPosition(fallback, scene: scene) {
                        position = fallback
                        found = true
                        break
                    }
                    if !found {
                        position = .zero
                        found = true
                    }
                    break
                }
            } while !found

            position = clampToMapBounds(position, scene: scene)

            // Prefer named guardian art; fall back to Doll2 (fox).
            let imageName = UIImage(named: spriteName) != nil ? spriteName : "Doll2"
            let sprite = SKSpriteNode(imageNamed: imageName)
            sprite.size = guardianSize
            sprite.texture?.filteringMode = .linear
            sprite.name = "guardianSprite"

            let mask = SKShapeNode(ellipseOf: guardianSize)
            mask.fillColor = .white
            mask.strokeColor = .clear

            let crop = SKCropNode()
            crop.maskNode = mask
            crop.addChild(sprite)
            crop.position = position
            sprite.position = .zero
            crop.name = "enemy"  // keep physics contact name
            crop.zPosition = 8
            crop.xScale = 1  // art faces left by default

            let radius = min(guardianSize.width, guardianSize.height) / 2
            crop.physicsBody = SKPhysicsBody(circleOfRadius: radius)
            crop.physicsBody?.isDynamic = false
            crop.physicsBody?.categoryBitMask = PhysicsCategory.enemy
            crop.physicsBody?.contactTestBitMask = PhysicsCategory.player
            crop.physicsBody?.collisionBitMask = PhysicsCategory.none

            let identifier = "guardian_\(UUID().uuidString)"
            crop.userData = NSMutableDictionary()
            crop.userData?["identifier"] = identifier
            crop.userData?["guardianType"] = spriteName
            crop.userData?["displayName"] = "森林守護者"
            crop.userData?["walkVideo"] = walkName

            // Green-screen walk clip — keyed + frame-cached via ChromaKeyVideoNode (same as player).
            // Init starts background bake into the shared texture cache.
            if let url = Bundle.main.url(forResource: walkName, withExtension: "mp4") {
                let video = ChromaKeyVideoNode(url: url, size: guardianSize, loops: true, muted: true)
                video.position = .zero
                video.zPosition = max(sprite.zPosition + 1, 1)
                video.isHidden = true
                video.name = "guardianWalk"
                crop.addChild(video)
                crop.userData?["hasWalkVideo"] = true
                print("🎬 森林守護者 walk clip ready: \(walkName).mp4")
            } else {
                print("⚠️ Missing \(walkName).mp4 — guardian will use static sprite only")
            }

            scene.addChild(crop)
            enemyNodes.append(crop)
            patrolEnemy(enemy: crop, scene: scene)
            print("🦊 生成森林守護者 \(spriteName) @ \(position)")
        }
    }

    private func guardianWalkNode(in guardian: SKNode) -> ChromaKeyVideoNode? {
        if let walk = guardian.childNode(withName: "guardianWalk") as? ChromaKeyVideoNode {
            return walk
        }
        // Fallback: chroma nodes may keep their default name briefly.
        return guardian.children.compactMap { $0 as? ChromaKeyVideoNode }.first
    }

    private func setGuardianWalking(_ guardian: SKNode, walking: Bool) {
        let sprite = guardian.childNode(withName: "guardianSprite")
        guard let walk = guardianWalkNode(in: guardian) else {
            sprite?.isHidden = false
            return
        }
        sprite?.isHidden = walking
        walk.isHidden = !walking
        if walking {
            walk.play()  // uses cached keyed frames
        } else {
            walk.pause()
        }
    }

    /// Idle/walk art faces left; flip when traveling right.
    private func setFacing(_ node: SKNode, dx: CGFloat) {
        guard abs(dx) > 0.5 else { return }
        let magnitude = abs(node.xScale) < 0.01 ? 1 : abs(node.xScale)
        node.xScale = dx > 0 ? -magnitude : magnitude
    }

    private func patrolEnemy(enemy: SKNode, scene: SKScene) {
        let moveDistance: CGFloat = 100
        let moveDuration: TimeInterval = 2.2
        let pauseDuration: TimeInterval = 1.2

        func nextPatrolTarget() -> CGPoint {
            var newPosition = enemy.position
            var attempts = 0
            repeat {
                let dx = [moveDistance, -moveDistance].randomElement()!
                let dy = [moveDistance, -moveDistance, CGFloat(0)].randomElement()!
                let proposed = CGPoint(x: enemy.position.x + dx, y: enemy.position.y + dy)
                newPosition = clampToMapBounds(proposed, scene: scene)
                if let tileType = getTileTypeAtPosition(newPosition, scene: scene),
                   ["S", "T", "W"].contains(tileType) {
                    attempts += 1
                    continue
                }
                attempts += 1
            } while attempts < 12 && (
                isPositionOccupied(newPosition, scene: scene)
                || !isValidMovementPosition(newPosition, scene: scene)
                || newPosition == enemy.position
            )
            return newPosition
        }

        // One patrol step = face + show walk video for the whole travel, then idle pause.
        // Single custom action so the walk clip stays on for the full travel duration.
        let step = SKAction.customAction(withDuration: moveDuration + pauseDuration) { [weak self] node, elapsed in
            guard let self = self else { return }
            let travelEnd = moveDuration
            if node.userData?["patrolActive"] as? Bool != true {
                let next = self.clampToMapBounds(nextPatrolTarget(), scene: scene)
                node.userData?["patrolStart"] = NSValue(cgPoint: node.position)
                node.userData?["patrolEnd"] = NSValue(cgPoint: next)
                node.userData?["patrolActive"] = true
                node.userData?["patrolWalking"] = true
                self.setFacing(node, dx: next.x - node.position.x)
                self.setGuardianWalking(node, walking: true)
            }
            guard let startVal = node.userData?["patrolStart"] as? NSValue,
                  let endVal = node.userData?["patrolEnd"] as? NSValue else { return }
            let start = startVal.cgPointValue
            let end = endVal.cgPointValue
            if elapsed <= travelEnd {
                let progress = CGFloat(min(elapsed / max(travelEnd, 0.001), 1.0))
                let x = start.x + (end.x - start.x) * progress
                let y = start.y + (end.y - start.y) * progress
                node.position = self.clampToMapBounds(CGPoint(x: x, y: y), scene: scene)
            } else {
                node.position = self.clampToMapBounds(end, scene: scene)
                if node.userData?["patrolWalking"] as? Bool == true {
                    node.userData?["patrolWalking"] = false
                    self.setGuardianWalking(node, walking: false)
                }
            }
            // Reset step bookkeeping when this cycle is about to finish so the next
            // repeatForever iteration picks a new target.
            if elapsed >= moveDuration + pauseDuration - 0.02 {
                node.userData?["patrolActive"] = false
            }
        }

        enemy.run(SKAction.repeatForever(step), withKey: "patrol")
    }

    func restartPatrol(for enemy: SKNode, in scene: SKScene) {
        enemy.removeAction(forKey: "patrol")
        patrolEnemy(enemy: enemy, scene: scene)
    }

    /// QA / debug: force walk clip visibility (uses cached chroma frames).
    func setWalkingAnimation(for guardian: SKNode, walking: Bool, facingDX: CGFloat? = nil) {
        if let dx = facingDX {
            setFacing(guardian, dx: dx)
        }
        setGuardianWalking(guardian, walking: walking)
    }

    private func isPositionOccupied(_ position: CGPoint, scene: SKScene) -> Bool {
        for node in scene.children {
            if node.name == "tree" && abs(node.position.x - position.x) < 60 && abs(node.position.y - position.y) < 100 {
                return true
            }
        }
        return false
    }

    private func clampToMapBounds(_ position: CGPoint, scene: SKScene) -> CGPoint {
        let tileSize: CGFloat = 64
        let mapWidth = 21 * tileSize
        let mapHeight = 20 * tileSize
        let mapBounds = (
            minX: -mapWidth / 2 + tileSize + 30,
            maxX: mapWidth / 2 - tileSize - 30,
            minY: -mapHeight / 2 + tileSize + 30,
            maxY: mapHeight / 2 - tileSize - 30
        )

        var clampedX = max(mapBounds.minX, min(mapBounds.maxX, position.x))
        var clampedY = max(mapBounds.minY, min(mapBounds.maxY, position.y))

        if let tileType = getTileTypeAtPosition(CGPoint(x: clampedX, y: clampedY), scene: scene),
           ["S", "T", "W"].contains(tileType) {
            let searchRadius = tileSize
            outer: for offsetX in stride(from: -searchRadius, through: searchRadius, by: tileSize / 2) {
                for offsetY in stride(from: -searchRadius, through: searchRadius, by: tileSize / 2) {
                    let test = CGPoint(x: clampedX + offsetX, y: clampedY + offsetY)
                    if let t = getTileTypeAtPosition(test, scene: scene), !["S", "T", "W"].contains(t) {
                        clampedX = test.x
                        clampedY = test.y
                        break outer
                    }
                }
            }
        }
        return CGPoint(x: clampedX, y: clampedY)
    }

    private func getTileTypeAtPosition(_ position: CGPoint, scene: SKScene) -> Character? {
        let tileSize: CGFloat = 64
        var closestTile: SKSpriteNode?
        var closestDistance = CGFloat.greatestFiniteMagnitude

        for node in scene.children {
            if let sprite = node as? SKSpriteNode,
               sprite.zPosition == -1,
               let nodeName = sprite.name,
               nodeName.hasPrefix("mapTile_") {
                let distance = hypot(sprite.position.x - position.x, sprite.position.y - position.y)
                if distance < tileSize && distance < closestDistance {
                    closestTile = sprite
                    closestDistance = distance
                }
            }
        }
        guard let tile = closestTile else { return nil }
        if tile.physicsBody != nil {
            if let textureName = tile.texture?.description.lowercased() {
                if textureName.contains("stone") { return "S" }
                if textureName.contains("tree") { return "T" }
                if textureName.contains("water") { return "W" }
            }
            return "S"
        }
        return "."
    }

    private func isValidMovementPosition(_ position: CGPoint, scene: SKScene) -> Bool {
        if let tileType = getTileTypeAtPosition(position, scene: scene),
           ["S", "T", "W"].contains(tileType) {
            return false
        }
        let tileSize: CGFloat = 64
        let checkRadius = tileSize / 2 + 10
        for node in scene.children {
            if node.name == "tree",
               hypot(node.position.x - position.x, node.position.y - position.y) < checkRadius {
                return false
            }
            if let sprite = node as? SKSpriteNode,
               sprite.zPosition == -1,
               let nodeName = sprite.name,
               nodeName.hasPrefix("mapTile_"),
               abs(sprite.position.x - position.x) < tileSize,
               abs(sprite.position.y - position.y) < tileSize,
               sprite.physicsBody != nil {
                return false
            }
        }
        return true
    }
}
