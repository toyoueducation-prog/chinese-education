import SpriteKit
import AVFoundation
#if os(iOS)
import UIKit
#endif

/**
 * GAME SCENE - Main Game World & Map
 * 
 * This is the primary game scene where players explore a 2D map, interact with NPCs (enemies),
 * and navigate to different educational activities. The scene features:
 * 
 * - 21x20 grid-based map with various terrain types (grass, trees, water, stone walls)
 * - Player movement system with camera following
 * - Enemy/NPC spawning and patrol system
 * - Mini-map showing player and enemy positions
 * - Navigation buttons to access Progress, Vocabulary, and Report scenes
 * - Claw machine mini-game access
 * - Collision detection for enemy interactions (triggers ConversationScene)
 * 
 * Game Flow:
 * 1. Player spawns on the map
 * 2. Player can move around using touch controls
 * 3. When player collides with an enemy, ConversationScene is triggered
 * 4. After completing questions, player returns to this scene
 * 5. Player can access various features via navigation buttons
 * 
 * Map Legend:
 * - "S" = Stone Walls (boundaries and obstacles)
 * - "." = Grass Paths (walkable)
 * - "T" = Trees (obstacles)
 * - "G" = Grass Areas (walkable)
 * - "W" = Water (obstacles)
 * - "P" = Player Spawn Point
 */
// MARK: - 🎮 MAIN GAME SCENE - Core Game World & Map
class GameScene: SKScene, SKPhysicsContactDelegate {
    
    // MARK: - 🎯 GAME ENTITIES
    private var enemy: SKSpriteNode!                    // Enemy sprite reference
    private var player: SKSpriteNode!                   // Player sprite reference
    
    // MARK: - 📷 CAMERA & MOVEMENT
    private var cameraNode: SKCameraNode!               // Camera that follows player
    private var isMoving = false                        // Player movement state
    private var moveDirection: CGVector = CGVector(dx: 0, dy: 0)  // Movement direction
    
    // MARK: - 🎮 UI LABELS (Gaming HUD)
    private var levelLabel: SKLabelNode!                // Player level display
    private var xpLabel: SKLabelNode!                   // Experience points display
    private var badgeLabel: SKLabelNode!                // Badge count display
    private var worldLabel: SKLabelNode!                // Current world display
    private var scoreLabel: SKLabelNode!                // Game score display
    private var crystalCoinLabel: SKLabelNode!          // Crystal coins display
    
    // MARK: - 🕹️ CONTROLS
    private var moveJoystick: SKNode!                   // Movement joystick (if implemented)
    private var clampingButton: SKLabelNode!            // Button to access claw game
    
    // MARK: - 💰 GAME STATS
    private var gameScore: Int = 0                      // Current game score
    private var crystalCoins: Int = 0                   // Current crystal coins
    
    // MARK: - 🎯 COLLISION & TRANSITION SYSTEM
    private var lastCollidedEnemy: SKNode?              // Tracks last touched enemy
    private var lastCollidedEnemyIdentifier: String?    // Track enemy identifier for persistence
    private var transitionCooldown = false              // Prevents looping transition
    
    // MARK: - 🗺️ MAP SYSTEM
    private var treePositions: [CGPoint] = []           // Tree obstacle positions
    // ✅ Removed hasGeneratedMap - always using modern map system
    
    // MARK: - 🗺️ MINI-MAP SYSTEM
    private var miniMap: SKSpriteNode!                  // Mini-map background
    private var playerDot: SKShapeNode!                 // Player position dot on mini-map
    private var NPCDot: SKShapeNode!                    // NPC position dot on mini-map
    private var npcDots: [SKShapeNode] = []             // Array of NPC dots on mini-map
    
    // MARK: - 👾 ENEMY & NPC SPAWNING
    private var hasSpawnedEnemies = false               // Enemy spawn flag
    private var hasSpawnedNPCs = false                  // NPC spawn flag
    
    // MARK: - 🗺️ MAP SYSTEM
    private var hasGeneratedMap = false                 // Map generation flag
    
    // MARK: - 📖 First-run movement tutorial
    private let gameMovementTutorialCompletedKey = "hasCompletedGameMovementTutorial"
    private var movementTutorialRoot: SKNode?
    private var movementTutorialStepIndex: Int = 0
    private var movementTutorialMessageLabel: SKLabelNode?
    // MARK: - 🗺️ GAME MAP LAYOUT (21x20 Grid)
    // Map Legend: "S"=Stone Walls, "."=Grass Paths, "T"=Trees, "G"=Grass Areas, "W"=Water, "P"=Player Spawn
    private var currentMapIndex = 0  // ✅ Track which map we're on
    private static let mapIndexKey = "currentMapIndex"
    private var mapLayout: [[Character]] = [
        ["S","S","S","S","S","S","S","S","S","S","S","S","S","S","S","S","S","S","S","S","S"], // Row 0: Top boundary
        ["S",".",".",".","T","G","G","G","T",".",".",".",".",".",".",".",".",".",".",".","S"], // Row 1: Forest area
        ["S",".",".",".","T","G","G","G","T",".",".",".",".",".",".",".",".",".",".",".","S"], // Row 2: Forest area
        ["S",".","W","W",".","G","T","G",".","W","W","W","W",".",".",".",".","T",".",".","S"], // Row 3: Water + Forest
        ["S",".","W","W",".","G","T","G",".","W","W","W","W",".",".",".",".","T",".",".","S"], // Row 4: Water + Forest
        ["S",".","W","W",".",".",".",".",".","W","W","W","W",".",".",".",".","T",".",".","S"], // Row 5: Water area
        ["S",".","W","W",".",".",".",".",".","W","W","W","W",".",".",".",".","T",".",".","S"], // Row 6: Water area
        ["S",".",".",".",".","T","G","G",".",".",".",".",".",".",".",".",".",".",".",".","S"], // Row 7: Grass paths
        ["S",".",".",".",".","T","G","G",".",".",".",".",".",".",".",".",".",".",".",".","S"], // Row 8: Grass paths
        ["S",".","T","T",".",".",".",".",".","T","T",".","T",".",".",".",".",".",".",".","S"], // Row 9: Tree obstacles
        ["S",".","T","T",".",".",".",".",".","T","T",".","T",".",".",".",".","T",".",".","S"], // Row 10: Tree obstacles
        ["S",".",".",".","G","G","G",".",".",".",".",".",".",".",".",".",".",".",".",".","S"], // Row 11: Grass clearing
        ["S",".",".",".","G","G","G",".",".",".",".",".",".",".",".",".",".",".",".",".","S"], // Row 12: Grass clearing
        ["S","T",".","W","W",".",".",".","T","T",".",".",".","T",".",".",".",".",".",".","S"], // Row 13: Mixed terrain
        ["S","T",".","W","W",".",".",".","T","T",".",".",".","T",".",".",".",".",".",".","S"], // Row 14: Mixed terrain
        ["S",".",".",".",".","G","G",".",".",".","G","G",".",".",".",".",".",".",".",".","S"], // Row 15: Grass areas
        ["S",".",".",".",".","G","G",".",".",".","G","G",".","X",".",".",".",".",".",".","S"], // Row 16: Treasury box
        ["S",".",".",".",".","G","G",".",".",".","G","G",".","P",".",".",".",".",".",".","S"], // Row 17: Player spawn area
        ["S",".",".",".",".","G","G",".",".",".","G","G",".","P",".",".",".",".",".",".","S"], // Row 18: Player spawn area
        ["S","S","S","S","S","S","S","S","S","S","S","S","S","S","S","S","S","S","S","S","S"]  // Row 19: Bottom boundary
    ]
    
    // ✅ Map 2: Forest Clearing - Large central clearing with trees, paths, bushes, rocks, and logs
    private var mapLayout2: [[Character]] = [
        ["S","S","S","S","S","S","S","S","S","S","S","S","S","S","S","S","S","S","S","S","S"], // Row 0: Top boundary (hedge)
        ["S","T","T","G","G","G","G","G","G","G","G","G","G","G","G","G","G","G","T","T","S"], // Row 1: Trees + Grass
        ["S","T","G","G",".",".","G","G","G","G","G","G","G","G","G",".",".","G","G","T","S"], // Row 2: Paths + Grass
        ["S","G","G",".",".","B",".",".","G","G","G","G","G","G",".",".","B",".",".","G","S"], // Row 3: Paths + Bushes
        ["S","G",".",".","T","G","G","G","T",".",".","G","G",".",".","T","G","G","G",".","S"], // Row 4: Trees + Paths
        ["S","G",".","W","W","G","T","G","W","W","W","W","G","T","G","W","W",".",".","G","S"], // Row 5: Water streams + Trees
        ["S","G",".","W","W","G","G","G","W","W","W","W","G","G","G","W","W",".",".","G","S"], // Row 6: Water streams
        ["S","G","G",".",".","T","G","T",".",".","G","G",".",".","T","G","T",".",".","G","S"], // Row 7: Trees + Paths
        ["S","G","G","G",".",".","G","G",".","R",".","R",".","G","G",".",".","G","G","G","S"], // Row 8: Rocks + Paths
        ["S","G","T","G","G",".",".",".","G","G","G","G","G",".",".",".","G","G","T","G","S"], // Row 9: Trees + Clearing
        ["S","G","T","G","G","G",".",".","G","T","T","T","G",".",".","G","G","G","T","G","S"], // Row 10: Trees + Clearing
        ["S","G","G","G","G","G","G",".",".","G","G","G",".",".","G","G","G","G","G","G","S"], // Row 11: Large clearing
        ["S","G","G","L","L","G","G","G",".",".",".",".",".","G","G","G","L","L","G","G","S"], // Row 12: Logs + Clearing
        ["S","G","G","L","L","G","T","G","G",".",".",".","G","G","T","G","L","L","G","G","S"], // Row 13: Logs + Trees
        ["S","G","G","G","G","G","T","G","G","G","B","G","G","G","T","G","G","G","G","G","S"], // Row 14: Bushes + Trees
        ["S","G",".",".","G","G","G","G","G","G","G","G","G","G","G","G","G",".",".","G","S"], // Row 15: Paths + Clearing
        ["S","G",".",".",".","G","T","G",".",".",".",".",".","G","T","G",".",".",".","G","S"], // Row 16: Paths + Trees
        ["S","G","G","G","G","G","G","G","G","G","P","G","G","G","G","G","G","G","G","G","S"], // Row 17: Player spawn
        ["S","G","G","G","G","G","G","G","G","X","G","G","G","G","G","G","G","G","G","G","S"], // Row 18: Treasury box
        ["S","S","S","S","S","S","S","S","S","S","S","S","S","S","S","S","S","S","S","S","S"]  // Row 19: Bottom boundary (hedge)
    ]
    
    // ✅ Array of all available maps
    private var allMaps: [[[Character]]] {
        return [mapLayout, mapLayout2]  // Add more maps here: mapLayout3, mapLayout4, etc.
    }
    
    override func didMove(to view: SKView) {
        backgroundColor = UIColor(red: 0.2, green: 0.5, blue: 0.2, alpha: 1.0)  // ✅ Darker green background
        physicsWorld.contactDelegate = self
        physicsWorld.gravity = .zero // Disable gravity for 2D movement
        
        // ✅ Listen for enemy completion notification
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(handleEnemyCompleted),
            name: NSNotification.Name("EnemyCompleted"),
            object: nil
        )
        
        // ✅ Listen for level up notification
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(handleLevelUp),
            name: NSNotification.Name("PlayerLevelUp"),
            object: nil
        )

        let isFreshStart = !UserDefaults.standard.bool(forKey: "hasSeenIntro")

        if isFreshStart {
            GameStats.shared.resetScore()  // ✅ Reset scores
            GameStats.shared.crystalCoins = 0
            UserDefaults.standard.set(0, forKey: Self.mapIndexKey)
            currentMapIndex = 0
            print("✅ Debug: Game restarted from scratch")
        } else {
            // ✅ Restore map across Conversation / Hint / Treasury / etc. scene recreations
            currentMapIndex = UserDefaults.standard.integer(forKey: Self.mapIndexKey)
        }
        
        // 🗺️ ORIGINAL MAP SYSTEM - Render fixed map
        if !hasGeneratedMap {
            // ✅ Use the current map index to select which map to render
            if currentMapIndex < allMaps.count {
                mapLayout = allMaps[currentMapIndex]
            }
            renderFixedMap()
            hasGeneratedMap = true
        }

        //setupObjects()
        // ✅ FIRST: Remove all completed enemies from the array immediately
        // ✅ This must happen before any other enemy processing
        NPC.shared.enemyNodes = NPC.shared.enemyNodes.filter { enemy in
            let enemyId = enemy.userData?["identifier"] as? String ?? ""
            let isCompleted = NPC.shared.completedEnemyIdentifiers.contains(enemyId)
            if isCompleted {
                // ✅ Remove from scene if still attached
                enemy.removeFromParent()
                enemy.isHidden = true
                print("🗑️ Removed completed enemy on scene load: \(enemyId)")
            }
            return !isCompleted  // ✅ Only keep non-completed enemies
        }
        
        // ✅ Clean up stale enemies (enemies not in this scene but not completed)
        // ✅ IMPORTANT: Don't filter out enemies from old scenes - we need to re-add them to this scene
        // ✅ Just remove enemies that are completed (already done above)
        // ✅ Keep all non-completed enemies so we can re-add them to this scene
        
        // ✅ Remove completed enemies from scene (double-check)
        removeCompletedEnemies()
        
        // ✅ Refresh minimap immediately after cleanup to remove dots for completed enemies
        // ✅ Note: minimap will be set up later, but we'll refresh it then too
        
        // ✅ Count active (non-completed) enemies — include those detached from the previous scene
        // so returning mid-quiz does not re-spawn duplicates.
        let nonCompletedEnemies = NPC.shared.enemyNodes.filter { enemy in
            let enemyId = enemy.userData?["identifier"] as? String ?? ""
            return !NPC.shared.completedEnemyIdentifiers.contains(enemyId)
        }
        var activeEnemyCount = nonCompletedEnemies.filter { enemy in
            return enemy.parent != nil && !enemy.isHidden
        }.count
        
        print("📊 Enemy Status: \(activeEnemyCount) active in-scene, \(nonCompletedEnemies.count) non-completed, \(NPC.shared.enemyNodes.count) total in array, \(NPC.shared.completedEnemyIdentifiers.count) completed")
        print("📊 Scene children count: \(children.count)")
        
        // ✅ Check if all enemies are completed
        // ✅ Use non-completed count == 0 AND we have completed enemies (meaning we've defeated them all)
        let allEnemiesCompleted = nonCompletedEnemies.isEmpty && !NPC.shared.completedEnemyIdentifiers.isEmpty && NPC.shared.completedEnemyIdentifiers.count >= 2
        
        // ✅ Spawn only when we have fewer than 2 living guardians and none defeated yet (fresh map)
        let needsSpawn = nonCompletedEnemies.count < 2 && NPC.shared.completedEnemyIdentifiers.isEmpty
        
        // ✅ Only spawn/manage enemies if we haven't completed all of them
        if allEnemiesCompleted {
            // ✅ All enemies completed, will transition to new map (handled below)
            print("✅ All enemies completed, will transition to new map")
        } else if needsSpawn {
            // ✅ Need to spawn enemies - calculate how many we need
            let enemiesToSpawn = 2 - activeEnemyCount
            print("🎯 Spawning \(enemiesToSpawn) enemy(ies) to reach 2 total. Current active: \(activeEnemyCount)")
            NPC.shared.spawnEnemies(in: self, count: 2)  // ✅ spawnEnemies will calculate how many are actually needed
            hasSpawnedEnemies = true
            
            // ✅ Verify enemies were actually added to scene
            let enemiesInScene = NPC.shared.enemyNodes.filter { $0.parent == self }
            print("✅ Spawned enemies. Total in array: \(NPC.shared.enemyNodes.count), In scene: \(enemiesInScene.count)")
            
            // ✅ Immediately refresh minimap after spawning
            DispatchQueue.main.async { [weak self] in
                self?.refreshMiniMapDots()
            }
        } else {
            // ✅ Already spawned - just ensure active enemies are in scene and patrolling
            // ✅ DO NOT spawn new enemies - we want to keep the remaining enemy after one is removed
            
            // ✅ First, remove any completed enemies that might still be in the array
            let completedEnemies = NPC.shared.enemyNodes.filter { enemy in
                let enemyId = enemy.userData?["identifier"] as? String ?? ""
                return NPC.shared.completedEnemyIdentifiers.contains(enemyId)
            }
            
            for completedEnemy in completedEnemies {
                completedEnemy.removeFromParent()
                completedEnemy.isHidden = true
                if let index = NPC.shared.enemyNodes.firstIndex(of: completedEnemy) {
                    NPC.shared.enemyNodes.remove(at: index)
                    print("✅ Removed completed enemy from array on return")
                }
            }
            
            // ✅ Now ensure only active enemies are in scene and patrolling
            for enemy in NPC.shared.enemyNodes {
                let enemyId = enemy.userData?["identifier"] as? String ?? ""
                // ✅ Skip completed enemies (shouldn't happen after cleanup above, but double-check)
                if NPC.shared.completedEnemyIdentifiers.contains(enemyId) {
                    continue
                }
                
                // ✅ If enemy is not in THIS scene (parent is nil or different scene), add it back
                if enemy.parent !== self {
                    // ✅ Remove from old scene if it has one
                    if enemy.parent != nil {
                        enemy.removeFromParent()
                    }
                    enemy.isHidden = false
                    // Restore contact after a mid-quiz abandon (disabled on collision)
                    enemy.physicsBody?.contactTestBitMask = PhysicsCategory.player
                    enemy.physicsBody?.categoryBitMask = PhysicsCategory.enemy
                    addChild(enemy)
                    print("✅ Re-added active enemy to scene. ID: \(enemyId)")
                    NPC.shared.restartPatrol(for: enemy, in: self)
                } else if enemy.action(forKey: "patrol") == nil {
                    // ✅ Enemy is in scene but not patrolling - restart patrol
                    print("✅ Restarting patrol for active enemy. ID: \(enemyId)")
                    NPC.shared.restartPatrol(for: enemy, in: self)
                }
            }
            
            // ✅ Refresh minimap after cleanup to ensure dots match active enemies
            refreshMiniMapDots()
        }
        
        // ✅ Setup Player FIRST to avoid nil error
        PlayerManager.shared.setupPlayer(in: self)

        setupCamera()
        setupUI()
        setupMiniMap()  // ✅ Add Mini-Map (will be synced after enemies spawn)
        setupNavigationButtons()  // ✅ Add navigation to Progress and Vocabulary scenes
        updateUI()  // ✅ Update UI to show current level and XP
        
        // ✅ Listen for UI update notifications (e.g., when returning from ConversationScene)
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(updateUIFromNotification),
            name: NSNotification.Name("UpdateGameUI"),
            object: nil
        )

        // ✅ Refresh minimap AFTER enemies are spawned/processed to sync dots with actual enemies
        // ✅ Use a small delay to ensure all enemy processing is complete
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) { [weak self] in
            guard let self = self else { return }
            self.refreshMiniMapDots()
            let activeCount = NPC.shared.enemyNodes.filter { enemy in
                let enemyId = enemy.userData?["identifier"] as? String ?? ""
                return !NPC.shared.completedEnemyIdentifiers.contains(enemyId) && 
                       enemy.parent != nil &&
                       !enemy.isHidden
            }.count
            print("✅ Mini-map synced: \(self.npcDots.count) dots for \(activeCount) active enemies (out of \(NPC.shared.enemyNodes.count) total)")
        }
        
        // ✅ Check if all enemies are completed - transition to new map BEFORE spawning new ones
        // ✅ Recalculate active enemy count after removing completed enemies
        activeEnemyCount = NPC.shared.enemyNodes.filter { enemy in
            let enemyId = enemy.userData?["identifier"] as? String ?? ""
            return !NPC.shared.completedEnemyIdentifiers.contains(enemyId) &&
                   enemy.parent != nil &&
                   !enemy.isHidden
        }.count
        
        // ✅ Check if all enemies are completed (2 enemies defeated)
        // ✅ Don't rely on hasSpawnedEnemies since it resets on new scene creation
        // ✅ Instead check if we have 2 completed enemies and 0 active enemies
        if activeEnemyCount == 0 && NPC.shared.completedEnemyIdentifiers.count >= 2 {
            print("🎉 All enemies completed! (\(NPC.shared.completedEnemyIdentifiers.count) completed) Transitioning to new map...")
            transitionToNewMap()
            return
        }
        
        // ✅ Move player slightly away from enemy after returning
        if lastCollidedEnemy != nil {
                print("🔄 Moving player slightly away from enemy after return")
                PlayerManager.shared.playerCropNode?.position.x += 50  // ✅ Pushes player slightly to the right
            }

            // ✅ Activate Safe Zone (No Collision for 2 Seconds)
            transitionCooldown = true
            DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
                self.transitionCooldown = false
                print("✅ Collision re-enabled after safe zone")
            }
        
        // ✅ Refresh minimap dots after a short delay to ensure enemies are ready
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            self.refreshMiniMapDots()
            print("✅ Mini-map refreshed: \(self.npcDots.count) dots for \(NPC.shared.enemyNodes.count) enemies")
        }

        print("✅ Debug: All Game Elements Initialized - Using Original Map System")
        
        #if DEBUG
        let cov = QuestionBank.shared.buildCoverageReport()
        print("📊 Question bank coverage: \(cov.totalQuestions) questions, \(cov.passageCount) passages | PIRLS \(cov.pirlsCountsDescription) | difficulties \(cov.difficultyHistogram)")
        #endif
        
        setupMovementTutorialIfNeeded()
    }

    private func renderFixedMap() {
        // ✅ Remove any existing background that might cover tiles
        enumerateChildNodes(withName: "//background") { node, _ in
            if node.zPosition == -1 {
                node.removeFromParent()
            }
        }
        
        let tileSize = CGSize(width: 64, height: 64)
        for (row, tiles) in mapLayout.enumerated() {
            for (col, symbol) in tiles.enumerated() {
                let tileName = imageName(for: symbol)
                
                // ✅ Check if image exists using UIImage (more reliable than SKTexture)
                let uiImage = UIImage(named: tileName)
                let tileNode: SKSpriteNode
                
                if uiImage == nil {
                    // ✅ Image doesn't exist - log detailed error
                    let mapName = currentMapIndex == 1 ? "Map 2 (Forest)" : "Map 1"
                    print("⚠️ [MAP TILE ERROR] Missing image for \(mapName):")
                    print("   - Image name: '\(tileName)'")
                    print("   - Symbol: '\(symbol)'")
                    print("   - Position: Row \(row), Column \(col)")
                    print("   - Map coordinates: (\(col), \(row))")
                    print("   - Tile name: mapTile_\(row)_\(col)")
                    
                    // Use a fallback image
                    let fallbackImage = UIImage(named: "forest_grass1")
                    if fallbackImage != nil {
                        tileNode = SKSpriteNode(texture: SKTexture(image: fallbackImage!))
                        print("   - Using fallback: 'forest_grass1'")
                    } else {
                        // Ultimate fallback - create a colored square
                        tileNode = SKSpriteNode(color: .gray, size: tileSize)
                        print("   - Fallback image 'forest_grass1' also failed! Using gray placeholder")
                    }
                } else {
                    // ✅ Image exists - create node normally
                    tileNode = SKSpriteNode(imageNamed: tileName)
                }
                
                tileNode.size = tileSize
                tileNode.anchorPoint = CGPoint(x: 0, y: 1)
                
                let xPos = CGFloat(col) * tileSize.width - size.width / 2
                let yPos = size.height / 2 - CGFloat(row) * tileSize.height
                tileNode.position = CGPoint(x: xPos, y: yPos)
                tileNode.zPosition = -1
                tileNode.name = "mapTile_\(row)_\(col)" // ✅ Add unique name for debugging
                
                // ✅ Rotate stone2 tiles if vertically aligned
                if symbol == "S" {
                    let isVerticallyAligned = isStoneVerticallyAligned(row: row, col: col)
                    if isVerticallyAligned {
                        tileNode.zRotation = .pi / 2  // Rotate 90 degrees
                    }
                }
                
                addChild(tileNode)
                
                if symbol == "P" {
                    PlayerManager.shared.playerCropNode?.position = CGPoint(x: xPos, y: yPos)
                }
                
                // ✅ Add treasury box with collision detection
                if symbol == "X" {
                    let treasuryBox = SKSpriteNode(imageNamed: "treasury")
                    treasuryBox.size = tileSize
                    treasuryBox.anchorPoint = CGPoint(x: 0, y: 1)
                    treasuryBox.position = CGPoint(x: xPos, y: yPos)
                    treasuryBox.zPosition = 5  // Above ground tiles
                    treasuryBox.name = "treasuryBox"
                    addChild(treasuryBox)
                    
                    // ✅ Add physics body for collision detection
                    let bodySize = CGSize(width: tileSize.width, height: tileSize.height)
                    treasuryBox.physicsBody = SKPhysicsBody(rectangleOf: bodySize, center: CGPoint(x: tileSize.width / 2, y: -tileSize.height / 2))
                    treasuryBox.physicsBody?.isDynamic = false
                    treasuryBox.physicsBody?.categoryBitMask = 0x1 << 3  // Treasury category
                    treasuryBox.physicsBody?.collisionBitMask = 0x1 << 0  // Collide with player
                    treasuryBox.physicsBody?.contactTestBitMask = 0x1 << 0  // Detect player contact
                }
                
                // Add physics body to block player movement
                // Obstacles: Trees, Water, Stone walls, Bushes, Rocks, Logs
                if ["T", "W", "S", "B", "R", "L"].contains(symbol) {
                    let bodySize = CGSize(width: tileSize.width, height: tileSize.height)
                    tileNode.physicsBody = SKPhysicsBody(rectangleOf: bodySize, center: CGPoint(x: tileSize.width / 2, y: -tileSize.height / 2))
                    tileNode.physicsBody?.isDynamic = false
                    tileNode.physicsBody?.categoryBitMask = 0x1 << 2
                    tileNode.physicsBody?.collisionBitMask = 0xFFFFFFFF
                    tileNode.physicsBody?.contactTestBitMask = 0xFFFFFFFF
                }
            }
        }
    }
    
    // MARK: - Check if stone tile is vertically aligned (same column, adjacent rows)
    private func isStoneVerticallyAligned(row: Int, col: Int) -> Bool {
        // Check if there's a stone above or below this stone
        let hasStoneAbove = row > 0 && mapLayout[row - 1][col] == "S"
        let hasStoneBelow = row < mapLayout.count - 1 && mapLayout[row + 1][col] == "S"
        return hasStoneAbove || hasStoneBelow
    }

    private func imageName(for symbol: Character) -> String {
        // Use forest-themed images for map 2, original images for map 1
        if currentMapIndex == 1 {
            // Map 2: Forest Clearing - use forest-themed assets
            switch symbol {
            case "G": 
                // Randomly choose between forest grass variants for variety
                // Note: forest_grass3 needs to be in an imageset folder to work properly
                let variants = ["forest_grass1", "forest_grass2"]  // Removed forest_grass3 until it's in imageset
                return variants.randomElement() ?? "forest_grass1"
            case "W": return "water_stream"  // Use stream for forest
            case "S": return "wall_hedge"  // Use hedge wall for forest theme
            case "T": 
                // Randomly choose between tree types
                // Note: tree_oak has a double .png extension issue - using tree_pine and tree_birch for now
                let treeTypes = ["tree_pine", "tree_birch"]  // Removed tree_oak until file is renamed
                return treeTypes.randomElement() ?? "tree_pine"
            case ".", "P": return "forest_path"  // Use forest path (will fallback if missing)
            case "F": return "forest_grass1"  // Forest floor - using grass as fallback until forest_floor image is added
            case "B": return "bush_berry"  // Berry bush
            case "R": return "rock_large"  // Large rock
            case "L": return "tree_log"  // Fallen log
            case "M": return "mushroom"  // Mushroom (decorative)
            case "X": return "treasury"  // Treasury box
            default: return "forest_grass1"
            }
        } else {
            // Map 1: Original theme
            switch symbol {
            case "G": return "grass2"
            case "W": return "water"
            case "S": return "stone2"
            case "T": return "tree"
                case ".", "P": return "grass3"
                case "X": return "treasury"  // Treasury box
                default: return "grass"
            }
        }
    }
    
    private func setupMiniMap() {
        let mapScale: CGFloat = 0.15

        // ✅ Clean up existing mini-map if it exists
        if let existingMiniMap = camera?.childNode(withName: "miniMap") {
            // ✅ Remove all dot nodes from the old minimap before removing it
            existingMiniMap.enumerateChildNodes(withName: "npcDot") { node, _ in
                node.removeFromParent()
            }
            existingMiniMap.removeFromParent()
        }
        // ✅ Clear and remove all existing dots
        for dot in npcDots {
            dot.removeFromParent()
        }
        npcDots.removeAll()  // ✅ Clear existing dots array

        // ✅ Mini-map background with transparency
        miniMap = SKSpriteNode(color: UIColor.white.withAlphaComponent(0.8),
                               size: CGSize(width: size.width * mapScale, height: size.height * mapScale))
        miniMap.anchorPoint = CGPoint(x: 0, y: 0)  // ✅ Ensure proper center alignment
        miniMap.position = CGPoint(x: size.width / 2 - miniMap.size.width - 20,
                                   y: size.height / 2 - miniMap.size.height - 20)
        miniMap.zPosition = 20
        miniMap.name = "miniMap"

        camera?.addChild(miniMap)

        // ✅ Properly align the border around the mini-map
        //let border = SKShapeNode(rectOf: miniMap.size, cornerRadius: 10)
        //border.strokeColor = .black
        //border.lineWidth = 3
        //border.position = miniMap.position  // ✅ Matches mini-map position
        //border.zPosition = 21
        //camera?.addChild(border)

        // ✅ Player marker on mini-map
        playerDot = SKShapeNode(circleOfRadius: 5)
        playerDot.fillColor = .red
        playerDot.zPosition = 22
        playerDot.position = CGPoint(x: miniMap.size.width / 2, y: miniMap.size.height / 2)
        miniMap.addChild(playerDot)

        // ✅ NPC markers on mini-map - don't create dots here, they'll be created by refreshMiniMapDots()
        // ✅ Dots will be created based on actual active enemies after spawning
    }
    
    // MARK: - Refresh Mini-Map Dots
    /**
     * Refreshes the minimap dots to match the current enemy count.
     * Called when returning from ConversationScene to ensure dots are synced.
     */
    func refreshMiniMapDots() {
        guard let miniMap = miniMap else {
            print("⚠️ Cannot refresh minimap: miniMap is nil")
            return
        }
        
        // ✅ Get only active (non-completed) enemies that are in the scene
        let activeEnemies = NPC.shared.enemyNodes.filter { enemy in
            let enemyId = enemy.userData?["identifier"] as? String ?? ""
            return !NPC.shared.completedEnemyIdentifiers.contains(enemyId) && 
                   enemy.parent != nil &&
                   !enemy.isHidden
        }
        
        let currentEnemyCount = activeEnemies.count
        print("🔄 Refreshing minimap: \(currentEnemyCount) active enemies (out of \(NPC.shared.enemyNodes.count) total), \(npcDots.count) dots")
        
        // ✅ Remove excess dots if we have more dots than active enemies
        while npcDots.count > currentEnemyCount {
            npcDots.last?.removeFromParent()
            npcDots.removeLast()
        }
        
        // ✅ Add missing dots if we have fewer dots than active enemies
        while npcDots.count < currentEnemyCount {
            let npcDot = SKShapeNode(circleOfRadius: 3)
            npcDot.fillColor = .blue
            npcDot.zPosition = 22
            npcDot.name = "npcDot"  // ✅ Give it a name for easier cleanup
            npcDot.isHidden = true  // Initially hidden until position is calculated
            miniMap.addChild(npcDot)
            npcDots.append(npcDot)
        }
        
        // ✅ Verify sync
        if npcDots.count == currentEnemyCount {
            print("✅ Mini-map synced: \(npcDots.count) dots for \(activeEnemies.count) active enemies")
        } else {
            print("⚠️ Mini-map sync issue: \(npcDots.count) dots vs \(currentEnemyCount) active enemies")
        }
    }


    
    // MARK: - Setup Background Map
    func setupMap() {
        let smallTexture = SKTexture(imageNamed: "Background2")
        _ = smallTexture.size()
        
        let mapNode = SKSpriteNode(texture: nil, color: .clear, size: CGSize(width: size.width * 2, height: size.height * 2))
        mapNode.anchorPoint = CGPoint(x: 0, y: 0)
        mapNode.position = CGPoint(x: 0, y: 0)
        
        let shader = SKShader(source: """
        void main() {
            vec2 coord = fract(v_tex_coord * 50);
            gl_FragColor = texture2D(u_texture, coord);
        }
        """)
        
        mapNode.shader = shader
        mapNode.texture = smallTexture
        mapNode.zPosition = -1
        addChild(mapNode)
        
        let border = SKPhysicsBody(edgeLoopFrom: CGRect(origin: .zero, size: mapNode.size))
        self.physicsBody = border
    }
    
    func setupObjects() {
        let treeTexture = SKTexture(imageNamed: "tree")
        let treeSize = CGSize(width: 60, height: 100)

        let totalClusters = 80
        let treesPerCluster = 20...30
        let clusterRadius: CGFloat = 150
        let walkableZones: [CGRect] = [
            CGRect(x: size.width * 0.3, y: size.height * 0.3, width: 200, height: 200),  // central path
            CGRect(x: size.width * 0.7, y: size.height * 0.5, width: 150, height: 150)   // near NPC zone
        ]

        var placedTrees: [CGPoint] = []

        for _ in 0..<totalClusters {
            // ✅ Ensure valid range bounds (upperBound >= lowerBound)
            let maxX = max(100, size.width - 100)
            let maxY = max(100, size.height - 100)
            
            let clusterCenter = CGPoint(
                x: CGFloat.random(in: 100...maxX),
                y: CGFloat.random(in: 100...maxY)
            )

            let numTrees = Int.random(in: treesPerCluster)

            for _ in 0..<numTrees {
                let angle = CGFloat.random(in: 0...(2 * .pi))
                let radius = CGFloat.random(in: 0...(clusterRadius / 2))
                let offsetX = cos(angle) * radius
                let offsetY = sin(angle) * radius

                let position = CGPoint(x: clusterCenter.x + offsetX, y: clusterCenter.y + offsetY)

                // ✅ Ensure tree is not inside a walkable zone
                let insideWalkable = walkableZones.contains { $0.contains(position) }
                let tooCloseToOthers = placedTrees.contains { abs($0.x - position.x) < 60 && abs($0.y - position.y) < 100 }

                if !insideWalkable && !tooCloseToOthers {
                    let tree = SKSpriteNode(texture: treeTexture)
                    tree.position = position
                    tree.size = treeSize
                    tree.physicsBody = SKPhysicsBody(rectangleOf: treeSize)
                    tree.physicsBody?.isDynamic = false
                    tree.name = "tree"
                    addChild(tree)
                    placedTrees.append(position)
                }
            }
        }

        print("🌲 Placed \(placedTrees.count) trees in \(totalClusters) clusters with paths left open.")
    }
    
    
    // MARK: - Setup Camera
    func setupCamera() {
        cameraNode = SKCameraNode()
        camera = cameraNode
        cameraNode.position = PlayerManager.shared.playerCropNode.position // ✅ Start centered on player
        addChild(cameraNode)
    }

    
    func distanceBetween(_ pos1: CGPoint, _ pos2: CGPoint) -> CGFloat {
        return sqrt(pow(pos2.x - pos1.x, 2) + pow(pos2.y - pos1.y, 2))
    }
    
    override func update(_ currentTime: TimeInterval) {
        if isMoving {
            let newX = PlayerManager.shared.playerCropNode.position.x + moveDirection.dx
            let newY = PlayerManager.shared.playerCropNode.position.y + moveDirection.dy
            
            // ✅ Original map boundaries: 21x20 grid, 64x64 tiles
            // ✅ Map is rendered with col 0 at (-size.width/2) and col 20 at (20*64 - size.width/2)
            let tileSize: CGFloat = 64
            let mapColumns = 21
            let mapRows = 20
            let mapWidth = CGFloat(mapColumns) * tileSize  // 1344
            let mapHeight = CGFloat(mapRows) * tileSize     // 1280
            // ✅ Calculate actual map bounds based on tile positions
            // ✅ First tile (col 0) is at: 0 * 64 - size.width / 2
            // ✅ Last tile (col 20) is at: 20 * 64 - size.width / 2 = 1280 - size.width / 2
            let mapBounds = (
                minX: 0 * tileSize - size.width / 2 + 30,           // First column + margin
                maxX: CGFloat(mapColumns - 1) * tileSize - size.width / 2 - 30,  // Last column - margin
                minY: -(CGFloat(mapRows - 1) * tileSize) + size.height / 2 - 30,  // Last row - margin
                maxY: 0 * tileSize + size.height / 2 - 30          // First row - margin
            )
            
            // ✅ Clamp player position to map boundaries
            let clampedX = max(mapBounds.minX, min(mapBounds.maxX, newX))
            let clampedY = max(mapBounds.minY, min(mapBounds.maxY, newY))
            
            // ✅ Update cropNode position (main player node)
            PlayerManager.shared.playerCropNode.position.x = clampedX
            PlayerManager.shared.playerCropNode.position.y = clampedY
            PlayerManager.shared.playerVideoNode?.position = CGPoint.zero  // Relative to cropNode

            // ✅ Ensure camera follows the player
            cameraNode.position = PlayerManager.shared.playerCropNode.position
        }

        guard let playerNode = PlayerManager.shared.playerCropNode else { return }
        guard let miniMap = miniMap, let playerDot = playerDot else { return }

        // ✅ Original map bounds for mini-map scaling: 21x20 grid, 64x64 tiles (same as player movement)
        let tileSize: CGFloat = 64
        let mapColumns = 21
        let mapRows = 20
        let margin: CGFloat = 30  // Same margin as player movement
        // ✅ Match player movement bounds calculation
        let mapBounds = (
            width: CGFloat(mapColumns - 1) * tileSize - 2 * margin,
            height: CGFloat(mapRows - 1) * tileSize - 2 * margin,
            minX: 0 * tileSize - size.width / 2 + margin,
            minY: -(CGFloat(mapRows - 1) * tileSize) + size.height / 2 - margin,
            maxX: CGFloat(mapColumns - 1) * tileSize - size.width / 2 - margin,
            maxY: 0 * tileSize + size.height / 2 - margin
        )
        
        // ✅ Convert world position to mini-map position (0 to miniMap.size)
        let normalizedX = (playerNode.position.x - mapBounds.minX) / mapBounds.width
        let normalizedY = (playerNode.position.y - mapBounds.minY) / mapBounds.height
        let miniMapX = normalizedX * miniMap.size.width
        let miniMapY = normalizedY * miniMap.size.height
        playerDot.position = CGPoint(x: miniMapX, y: miniMapY)
        
        // ✅ Get only active (non-completed) enemies that are in the scene
        let activeEnemies = NPC.shared.enemyNodes.filter { enemy in
            let enemyId = enemy.userData?["identifier"] as? String ?? ""
            return !NPC.shared.completedEnemyIdentifiers.contains(enemyId) && 
                   enemy.parent != nil && 
                   !enemy.isHidden
        }
        
        let currentEnemyCount = activeEnemies.count
        
        // ✅ Sync npcDots array with active enemy count
        while npcDots.count > currentEnemyCount {
            npcDots.last?.removeFromParent()
            npcDots.removeLast()
        }
        
        while npcDots.count < currentEnemyCount {
            let npcDot = SKShapeNode(circleOfRadius: 3)
            npcDot.fillColor = .blue
            npcDot.zPosition = 22
            npcDot.isHidden = true
            miniMap.addChild(npcDot)
            npcDots.append(npcDot)
        }
        
        // ✅ Sync npcDots array with active enemy count
        while npcDots.count > currentEnemyCount {
            npcDots.last?.removeFromParent()
            npcDots.removeLast()
        }
        
        while npcDots.count < currentEnemyCount {
            let npcDot = SKShapeNode(circleOfRadius: 3)
            npcDot.fillColor = .blue
            npcDot.zPosition = 22
            npcDot.isHidden = true
            miniMap.addChild(npcDot)
            npcDots.append(npcDot)
        }
        
        // ✅ Update each active enemy's position on minimap in real-time
        for (index, npc) in activeEnemies.enumerated() {
            if index < npcDots.count {
                // ✅ Check if enemy is within map bounds (use same calculation as player movement)
                let tileSize: CGFloat = 64
                let mapColumns = 21
                let mapRows = 20
                let margin: CGFloat = 30
                let enemyMapBounds = (
                    minX: 0 * tileSize - size.width / 2 + margin,
                    maxX: CGFloat(mapColumns - 1) * tileSize - size.width / 2 - margin,
                    minY: -(CGFloat(mapRows - 1) * tileSize) + size.height / 2 - margin,
                    maxY: 0 * tileSize + size.height / 2 - margin
                )
                let isWithinBounds = npc.position.x >= enemyMapBounds.minX && 
                                    npc.position.x <= enemyMapBounds.maxX &&
                                    npc.position.y >= enemyMapBounds.minY && 
                                    npc.position.y <= enemyMapBounds.maxY
                
                if isWithinBounds {
                    // ✅ Show dot and update position in real-time
                    npcDots[index].isHidden = false
                    let boundsWidth = enemyMapBounds.maxX - enemyMapBounds.minX
                    let boundsHeight = enemyMapBounds.maxY - enemyMapBounds.minY
                    let npcNormalizedX = (npc.position.x - enemyMapBounds.minX) / boundsWidth
                    let npcNormalizedY = (npc.position.y - enemyMapBounds.minY) / boundsHeight
                    // ✅ Clamp normalized values to [0, 1] range
                    let clampedX = max(0, min(1, npcNormalizedX))
                    let clampedY = max(0, min(1, npcNormalizedY))
                    let npcMapX = clampedX * miniMap.size.width
                    let npcMapY = clampedY * miniMap.size.height
                    
                    // ✅ Update dot position in real-time as enemy moves
                    npcDots[index].position = CGPoint(x: npcMapX, y: npcMapY)
                } else {
                    // ✅ Hide dot if enemy is outside bounds
                    npcDots[index].isHidden = true
                    // ✅ Clamp the enemy position back to bounds immediately
                    let clampedPosition = CGPoint(
                        x: max(enemyMapBounds.minX, min(enemyMapBounds.maxX, npc.position.x)),
                        y: max(enemyMapBounds.minY, min(enemyMapBounds.maxY, npc.position.y))
                    )
                    npc.position = clampedPosition
                    print("⚠️ Enemy \(index) was outside bounds, clamped to: \(clampedPosition)")
                }
            }
        }
        
        // ✅ Hide any extra dots
        for index in activeEnemies.count..<npcDots.count {
            npcDots[index].isHidden = true
        }

        
        if let lastEnemy = lastCollidedEnemy {
            if distanceBetween(playerNode.position, lastEnemy.position) > 80 {
                print("🔄 Reset Collision: Player moved away")
                lastCollidedEnemy = nil
                transitionCooldown = false  // ✅ Re-enable collision only when player moves away
            }
        }
    }

    
    // MARK: - Handle Touch to Move Player
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard let touch = touches.first else { return }
        if handleMovementTutorialTouch(touch) { return }
        let location = touch.location(in: self)
        
        // ✅ Check camera nodes first (buttons are children of camera)
        if let camera = camera {
            let cameraLocation = touch.location(in: camera)
            let cameraNode = camera.atPoint(cameraLocation)
            
            // ✅ Check if button or its child was tapped
            if cameraNode.name == "progressButton" || cameraNode.parent?.name == "progressButton" {
                print("✅ Progress button tapped")
                saveCurrentMapIndex()
                let progressScene = ProgressScene(size: self.size)
                progressScene.scaleMode = .aspectFill
                let transition = SKTransition.fade(withDuration: 0.5)
                self.view?.presentScene(progressScene, transition: transition)
                return
            }
            
            if cameraNode.name == "vocabularyButton" || cameraNode.parent?.name == "vocabularyButton" {
                print("✅ Vocabulary button tapped")
                saveCurrentMapIndex()
                let vocabularyScene = VocabularyScene(size: self.size)
                vocabularyScene.scaleMode = .aspectFill
                let transition = SKTransition.fade(withDuration: 0.5)
                self.view?.presentScene(vocabularyScene, transition: transition)
                return
            }
            
            if cameraNode.name == "reportButton" || cameraNode.parent?.name == "reportButton" {
                print("✅ Report button tapped")
                ReportGenerator.shared.generatePDFReport { url in
                    DispatchQueue.main.async {
                        if let url = url {
                            print("✅ Report generated at: \(url)")
                            ReportGenerator.shared.exportReportToServer { success in
                                print(success ? "✅ Report exported to server" : "❌ Failed to export report")
                            }
                        } else {
                            print("❌ Failed to generate report")
                        }
                    }
                }
                return
            }
        }
        
        // ✅ Fallback: check scene nodes
        let touchedNode = atPoint(location)
        
        // ✅ Detect Click on Navigation Buttons (fallback)
        if touchedNode.name == "progressButton" || touchedNode.parent?.name == "progressButton" {
            print("✅ Progress button tapped (fallback)")
            saveCurrentMapIndex()
            let progressScene = ProgressScene(size: self.size)
            progressScene.scaleMode = .aspectFill
            let transition = SKTransition.fade(withDuration: 0.5)
            self.view?.presentScene(progressScene, transition: transition)
            return
        }
        
        if touchedNode.name == "vocabularyButton" || touchedNode.parent?.name == "vocabularyButton" {
            print("✅ Vocabulary button tapped (fallback)")
            saveCurrentMapIndex()
            let vocabularyScene = VocabularyScene(size: self.size)
            vocabularyScene.scaleMode = .aspectFill
            let transition = SKTransition.fade(withDuration: 0.5)
            self.view?.presentScene(vocabularyScene, transition: transition)
            return
        }
        
        if touchedNode.name == "reportButton" || touchedNode.parent?.name == "reportButton" {
            print("✅ Report button tapped (fallback)")
            ReportGenerator.shared.generatePDFReport { url in
                DispatchQueue.main.async {
                    if let url = url {
                        print("✅ Report generated at: \(url)")
                        ReportGenerator.shared.exportReportToServer { success in
                            print(success ? "✅ Report exported to server" : "❌ Failed to export report")
                        }
                    } else {
                        print("❌ Failed to generate report")
                    }
                }
            }
            return
        }
        
        // ✅ Detect Click on Clamping Button (check both button and background)
        if touchedNode.name == "clampingButton" || touchedNode.name == "clampingButtonBackground" {
            enterClampingMachine()
            return
        }
        
        // Handle other touches
        
        isMoving = true
        moveDirection = CGVector(dx: (location.x - PlayerManager.shared.playerCropNode.position.x) * 0.01,
                                 dy: (location.y - PlayerManager.shared.playerCropNode.position.y) * 0.01)
        
        // Switch to video node when walk clips exist; otherwise keep Doll1
        PlayerManager.shared.setWalking(true)
    }
    
    override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard movementTutorialRoot == nil else { return }
        guard let touch = touches.first else { return }
        let location = touch.location(in: self)
        
        // Update movement direction based on new touch location
        moveDirection = CGVector(dx: (location.x - PlayerManager.shared.playerCropNode.position.x) * 0.01,
                                 dy: (location.y - PlayerManager.shared.playerCropNode.position.y) * 0.01)
    }
    
    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        if movementTutorialRoot != nil { return }
        isMoving = false
        moveDirection = CGVector(dx: 0, dy: 0)
        
        // Switch back to static image
        PlayerManager.shared.setWalking(false)
    }
    

    private func spawnPlayer() {
        var playerPosition: CGPoint

        repeat {
            playerPosition = CGPoint(x: CGFloat.random(in: 100...size.width - 100),
                                     y: CGFloat.random(in: 100...size.height - 100))
        } while isPositionOccupied(playerPosition)  // ✅ Ensure player does not spawn on a tree

        let player = SKSpriteNode(imageNamed: "Doll1")
        player.position = playerPosition
        player.size = CGSize(width: 60, height: 60)
        player.physicsBody = SKPhysicsBody(rectangleOf: player.size)
        addChild(player)
    }

    private func isPositionOccupied(_ position: CGPoint) -> Bool {
        for treePos in treePositions {
            if abs(treePos.x - position.x) < 60 && abs(treePos.y - position.y) < 100 {
                return true  // ✅ Position is too close to a tree
            }
        }
        return false
    }
    
    func savePlayerPosition() {
        let positionDict: [String: CGFloat] = [
            "x": PlayerManager.shared.playerCropNode.position.x,
            "y": PlayerManager.shared.playerCropNode.position.y
        ]
        UserDefaults.standard.set(positionDict, forKey: "playerPosition")
    }
    
    // MARK: - Handle Collision
    func didBegin(_ contact: SKPhysicsContact) {
        let bodyA = contact.bodyA.node
        let bodyB = contact.bodyB.node

        let playerNode = PlayerManager.shared.playerCropNode
        // Determine which node is the enemy (the one that's not the player)
        let enemyNode = (bodyA === playerNode) ? bodyB : bodyA  // ✅ Identify enemy node

            let firstBody = contact.bodyA.categoryBitMask
            let secondBody = contact.bodyB.categoryBitMask

        
        // ✅ Check for treasury box collision
        if let treasuryNode = (bodyA.name == "treasuryBox" ? bodyA : (bodyB.name == "treasuryBox" ? bodyB : nil)) {
            if (bodyA === playerNode || bodyB === playerNode) && !transitionCooldown {
                print("💰 Treasury box collision detected!")
                transitionCooldown = true
                transitionToTreasuryScene()
                return
            }
        }
        
        guard let enemy = enemyNode, enemy.name == "enemy" else {
            return
        }
        
        if transitionCooldown || lastCollidedEnemy == enemy {
            print("❌ Collision ignored (cooldown active)")
            return
        }
        
        print("🚨 Collision Detected with Enemy!")
        
        
        if (firstBody == PhysicsCategory.player && secondBody == PhysicsCategory.enemy) ||
            (firstBody == PhysicsCategory.enemy && secondBody == PhysicsCategory.player) {
            print("🚨 Collision Detected with Enemy!")
            // ✅ Stop player movement
            isMoving = false
            moveDirection = CGVector(dx: 0, dy: 0)
            
            // ✅ Save player position on collision
            savePlayerPosition()
            saveCurrentMapIndex()
            
            // ✅ Store last collided enemy and its identifier (do NOT defeat yet)
            lastCollidedEnemy = enemy
            lastCollidedEnemyIdentifier = enemy.userData?["identifier"] as? String
            
            // ✅ Begin encounter only — guardian stays until quiz completion succeeds
            if let enemyId = lastCollidedEnemyIdentifier {
                NPC.shared.beginEncounter(enemyId: enemyId)
                // Soften contact so overlapping bodies don't re-fire if scene teardown is slow
                enemy.physicsBody?.contactTestBitMask = PhysicsCategory.none
                print("⚔️ Started encounter with enemy. ID: \(enemyId) (not defeated yet)")
            }
            
            // ✅ Activate cooldown to prevent looping
            transitionCooldown = true
            
            print("🚨 Collided with enemy. Identifier: \(lastCollidedEnemyIdentifier ?? "unknown") — awaiting quiz result")
            
            // ✅ Transition to conversation scene
            transitionToConversationScene()
        }
    }
    
    // MARK: - Remove Completed Enemies
    func removeCompletedEnemies() {
        // ✅ Remove all completed enemies
        let enemiesToRemove = NPC.shared.enemyNodes.filter { enemy in
            let enemyId = enemy.userData?["identifier"] as? String ?? ""
            return NPC.shared.completedEnemyIdentifiers.contains(enemyId)
        }
        
        for enemy in enemiesToRemove {
            removeCompletedEnemy(enemy)
        }
    }
    
    // MARK: - Remove Completed Enemy
    func removeCompletedEnemy(_ enemy: SKNode) {
        let enemyId = enemy.userData?["identifier"] as? String ?? "unknown"
        print("🗑️ Removing completed enemy: \(enemyId)")
        
        // ✅ Remove from scene
        enemy.removeFromParent()
        enemy.isHidden = true
        
        // ✅ Remove from enemyNodes list
        if let enemyIndex = NPC.shared.enemyNodes.firstIndex(of: enemy) {
            NPC.shared.enemyNodes.remove(at: enemyIndex)
            print("✅ Removed enemy from enemyNodes array. Remaining: \(NPC.shared.enemyNodes.count)")
        } else {
            print("⚠️ Enemy not found in enemyNodes array")
        }
        
        // ✅ Remove ALL minimap dots and recreate them based on active enemies
        // ✅ This ensures dots are properly synced with remaining enemies
        for dot in npcDots {
            dot.removeFromParent()
        }
        npcDots.removeAll()
        
        // ✅ Immediately refresh minimap to sync dots with remaining active enemies
        refreshMiniMapDots()
        let activeCount = NPC.shared.enemyNodes.filter { enemy in
            let id = enemy.userData?["identifier"] as? String ?? ""
            return !NPC.shared.completedEnemyIdentifiers.contains(id) && enemy.parent != nil
        }.count
        print("✅ Refreshed minimap after enemy removal. Active enemies: \(activeCount), Dots: \(npcDots.count)")
    }
    
    // MARK: - Handle Enemy Completion Notification
    @objc func handleEnemyCompleted() {
        NPC.shared.completePendingEncounter(enemyId: lastCollidedEnemyIdentifier)
    }
    
    // MARK: - Persist current map across scene recreations
    func saveCurrentMapIndex() {
        UserDefaults.standard.set(currentMapIndex, forKey: Self.mapIndexKey)
    }
    
    // MARK: - First-run tutorial
    private var movementTutorialNextLabel: SKLabelNode?
    
    private func setupMovementTutorialIfNeeded() {
        guard !UserDefaults.standard.bool(forKey: gameMovementTutorialCompletedKey) else { return }
        guard movementTutorialRoot == nil, let cam = camera else { return }
        movementTutorialStepIndex = 0
        
        let root = SKNode()
        root.zPosition = 500
        root.name = "movementTutorialRoot"
        
        let panelW = min(size.width - 48, 360)
        let panelH: CGFloat = 240
        let bg = SKShapeNode(rectOf: CGSize(width: panelW, height: panelH), cornerRadius: 16)
        bg.fillColor = UIColor.black.withAlphaComponent(0.85)
        bg.strokeColor = UIColor.white.withAlphaComponent(0.4)
        bg.lineWidth = 2
        bg.position = .zero
        root.addChild(bg)
        
        let title = SKLabelNode(text: "新手指引")
        title.fontName = "AvenirNext-Bold"
        title.fontSize = 22
        title.fontColor = .white
        title.position = CGPoint(x: 0, y: panelH / 2 - 38)
        root.addChild(title)
        
        let msg = SKLabelNode(fontNamed: "AvenirNext-Medium")
        msg.fontSize = 17
        msg.fontColor = .white
        msg.numberOfLines = 0
        msg.preferredMaxLayoutWidth = panelW - 36
        msg.verticalAlignmentMode = .center
        msg.horizontalAlignmentMode = .center
        msg.position = CGPoint(x: 0, y: 8)
        movementTutorialMessageLabel = msg
        root.addChild(msg)
        
        let nextBg = SKShapeNode(rectOf: CGSize(width: 150, height: 46), cornerRadius: 10)
        nextBg.fillColor = UIColor.systemBlue
        nextBg.strokeColor = .clear
        nextBg.position = CGPoint(x: 0, y: -panelH / 2 + 44)
        nextBg.name = "movementTutorialNext"
        root.addChild(nextBg)
        
        let nextLbl = SKLabelNode(text: "下一步")
        nextLbl.fontName = "AvenirNext-Bold"
        nextLbl.fontSize = 18
        nextLbl.fontColor = .white
        nextLbl.verticalAlignmentMode = .center
        nextLbl.horizontalAlignmentMode = .center
        nextLbl.position = nextBg.position
        nextLbl.name = "movementTutorialNext"
        root.addChild(nextLbl)
        movementTutorialNextLabel = nextLbl
        
        root.position = CGPoint(x: 0, y: 0)
        cam.addChild(root)
        movementTutorialRoot = root
        applyMovementTutorialStepContent()
    }
    
    private func applyMovementTutorialStepContent() {
        let steps = [
            "用手指在畫面上拖曳，角色會往你的方向移動；放開手指就會停下來。",
            "地圖上的圓形角色是閱讀守護者，碰到他們就會進入文章與題目。",
            "左上角顯示等級與經驗值。上方藍色按鈕可開啟「進度」與「詞彙」頁面。",
            "還有夾娃娃機可以收集獎勵。祝你學習愉快！"
        ]
        guard movementTutorialStepIndex < steps.count else { return }
        movementTutorialMessageLabel?.text = steps[movementTutorialStepIndex]
        let isLast = movementTutorialStepIndex == steps.count - 1
        movementTutorialNextLabel?.text = isLast ? "開始遊戲" : "下一步"
    }
    
    private func advanceMovementTutorial() {
        let totalSteps = 4
        if movementTutorialStepIndex >= totalSteps - 1 {
            dismissMovementTutorial()
            return
        }
        movementTutorialStepIndex += 1
        applyMovementTutorialStepContent()
    }
    
    private func dismissMovementTutorial() {
        movementTutorialRoot?.removeFromParent()
        movementTutorialRoot = nil
        movementTutorialMessageLabel = nil
        movementTutorialNextLabel = nil
        UserDefaults.standard.set(true, forKey: gameMovementTutorialCompletedKey)
    }
    
    private func handleMovementTutorialTouch(_ touch: UITouch) -> Bool {
        guard movementTutorialRoot != nil, let cam = camera else { return false }
        let loc = touch.location(in: cam)
        var node: SKNode? = cam.atPoint(loc)
        while let n = node {
            if n.name == "movementTutorialNext" {
                advanceMovementTutorial()
                return true
            }
            node = n.parent
        }
        return true
    }
    
    // MARK: - Cleanup
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
    
    // MARK: - Transition to New Map
    func transitionToNewMap() {
        // ✅ Reset enemy tracking
        hasSpawnedEnemies = false
        NPC.shared.completedEnemyIdentifiers.removeAll()
        NPC.shared.abandonPendingEncounter()
        lastCollidedEnemy = nil
        lastCollidedEnemyIdentifier = nil
        NPC.shared.enemyNodes.removeAll()
        
        // ✅ Reset player position to center (will be set to spawn point in new map)
        PlayerManager.shared.playerCropNode?.position = CGPoint(x: 0, y: 0)
        
        // ✅ Clear saved player position so new map can set spawn point
        UserDefaults.standard.removeObject(forKey: "playerPosition")
        
        // ✅ Cycle to next map
        currentMapIndex = (currentMapIndex + 1) % allMaps.count
        mapLayout = allMaps[currentMapIndex]
        saveCurrentMapIndex()
        
        // ✅ Reset map generation flag to generate new map
        hasGeneratedMap = false
        
        // ✅ Create new scene with the new map
        let newGameScene = GameScene(size: self.size)
        newGameScene.currentMapIndex = self.currentMapIndex  // ✅ Pass the map index
        newGameScene.scaleMode = .aspectFill
        let transition = SKTransition.fade(withDuration: 1.5)
        self.view?.presentScene(newGameScene, transition: transition)
        
        print("🎉 Transitioned to map \(currentMapIndex + 1) of \(allMaps.count)!")
    }
    
    // MARK: - Transition to Conversation Scene on Collision
    func transitionToConversationScene() {
        saveCurrentMapIndex()
        
        let transitionScene = TransitionScene(size: self.size)
        transitionScene.scaleMode = .aspectFill
        let transition = SKTransition.fade(withDuration: 2.0)
        self.view?.presentScene(transitionScene, transition: transition)

    }
    
    // MARK: - Transition to Treasury Scene
    func transitionToTreasuryScene() {
        saveCurrentMapIndex()
        // ✅ Reset cooldown after a delay
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) { [weak self] in
            self?.transitionCooldown = false
        }
        
        let treasuryScene = TreasuryScene(size: self.size)
        treasuryScene.scaleMode = .aspectFill
        let transition = SKTransition.fade(withDuration: 1.0)
        self.view?.presentScene(treasuryScene, transition: transition)
    }
    
    // MARK: - Handle Level Up
    @objc func handleLevelUp(_ notification: Notification) {
        guard let userInfo = notification.userInfo,
              let newLevel = userInfo["newLevel"] as? Int else {
            return
        }
        
        saveCurrentMapIndex()
        
        // ✅ Transition to level up scene
        let levelUpScene = LevelUpScene(size: self.size)
        levelUpScene.newLevel = newLevel
        levelUpScene.scaleMode = .aspectFill
        let transition = SKTransition.fade(withDuration: 1.0)
        self.view?.presentScene(levelUpScene, transition: transition)
    }
    
    // MARK: - 🎮 Setup UI Elements - Enhanced Gaming HUD
    private func setupUI() {
        // ✅ Create main stats panel with modern design
        let statsPanelSize = CGSize(width: 280, height: 200)
        let statsPanel = SKSpriteNode(color: UIColor.black.withAlphaComponent(0.7), size: statsPanelSize)
        statsPanel.position = CGPoint(x: -size.width / 2 + 150, y: size.height / 2 - 100)
        statsPanel.zPosition = 19
        statsPanel.name = "statsPanel"
        camera?.addChild(statsPanel)

        // ✅ Add gradient-like border effect
        let border = SKShapeNode(rectOf: statsPanelSize, cornerRadius: 15)
        border.strokeColor = UIColor.systemBlue
        border.lineWidth = 4
        border.position = statsPanel.position
        border.zPosition = 20
        camera?.addChild(border)

        // ✅ Add inner glow effect
        let innerBorder = SKShapeNode(rectOf: CGSize(width: statsPanelSize.width - 8, height: statsPanelSize.height - 8), cornerRadius: 11)
        innerBorder.strokeColor = UIColor.white.withAlphaComponent(0.3)
        innerBorder.lineWidth = 2
        innerBorder.position = statsPanel.position
        innerBorder.zPosition = 21
        camera?.addChild(innerBorder)

        // ✅ Enhanced label creation function with better styling
        func createStyledLabel(withText text: String, fontSize: CGFloat, position: CGPoint, color: UIColor = .white) -> SKLabelNode {
            let label = SKLabelNode(text: text)
            label.fontSize = fontSize
            label.fontColor = color
            label.fontName = "AvenirNext-Bold"
            label.position = position
            label.zPosition = 22
            label.horizontalAlignmentMode = .left
            
            // ✅ Add text shadow effect
            let shadowLabel = SKLabelNode(text: text)
            shadowLabel.fontSize = fontSize
            shadowLabel.fontColor = UIColor.black.withAlphaComponent(0.5)
            shadowLabel.fontName = "AvenirNext-Bold"
            shadowLabel.position = CGPoint(x: position.x + 2, y: position.y - 2)
            shadowLabel.zPosition = 21
            shadowLabel.horizontalAlignmentMode = .left
            
            camera?.addChild(shadowLabel)
            camera?.addChild(label)
            return label
        }

        // ✅ Improved positioning with better spacing
        let startX: CGFloat = -size.width / 2 + 30
        let startY: CGFloat = size.height / 2 - 50
        let spacing: CGFloat = 40

        // ✅ Create stats with icons and better organization
        levelLabel = createStyledLabel(withText: "🏆 等級: \(PlayerProgress.shared.level)", fontSize: 20, position: CGPoint(x: startX, y: startY), color: UIColor.systemYellow)
        xpLabel = createStyledLabel(withText: "⭐ 經驗值: \(PlayerProgress.shared.xp)", fontSize: 18, position: CGPoint(x: startX, y: startY - spacing), color: UIColor.systemOrange)
        scoreLabel = createStyledLabel(withText: "🎯 積分: \(GameStats.shared.gameScore)", fontSize: 22, position: CGPoint(x: startX, y: startY - spacing * 2), color: UIColor.systemGreen)
        crystalCoinLabel = createStyledLabel(withText: "💎 水晶: \(GameStats.shared.crystalCoins)", fontSize: 20, position: CGPoint(x: startX, y: startY - spacing * 3), color: UIColor.systemPurple)
        
        // ✅ Enhanced button design
        setupClampingButton()
        
        // ✅ Add subtle animation to stats panel
        let pulseAction = SKAction.sequence([
            SKAction.scale(to: 1.02, duration: 2.0),
            SKAction.scale(to: 1.0, duration: 2.0)
        ])
        let repeatPulse = SKAction.repeatForever(pulseAction)
        statsPanel.run(repeatPulse)
    }
    
    // MARK: - 🎰 Setup Clamping Button - Enhanced Design
    private func setupClampingButton() {
        let buttonSize = CGSize(width: 180, height: 50)
        let buttonPosition = CGPoint(x: -size.width / 2 + 150, y: size.height / 2 - 250)
        
        // ✅ Create button background with gradient effect
        let buttonBackground = SKSpriteNode(color: UIColor.systemBlue.withAlphaComponent(0.9), size: buttonSize)
        buttonBackground.position = buttonPosition
        buttonBackground.zPosition = 15
        buttonBackground.name = "clampingButtonBackground"
        camera?.addChild(buttonBackground)
        
        // ✅ Add button border
        let buttonBorder = SKShapeNode(rectOf: buttonSize, cornerRadius: 12)
        buttonBorder.strokeColor = UIColor.white
        buttonBorder.lineWidth = 3
        buttonBorder.position = buttonPosition
        buttonBorder.zPosition = 16
        camera?.addChild(buttonBorder)
        
        // ✅ Create button text with shadow
        clampingButton = SKLabelNode(text: "🎰 水晶收集")
        clampingButton.fontSize = 20
        clampingButton.fontColor = .white
        clampingButton.fontName = "AvenirNext-Bold"
        clampingButton.position = buttonPosition
        clampingButton.zPosition = 17
        clampingButton.name = "clampingButton"
        
        // ✅ Add text shadow
        let buttonShadow = SKLabelNode(text: "🎰 水晶收集")
        buttonShadow.fontSize = 20
        buttonShadow.fontColor = UIColor.black.withAlphaComponent(0.5)
        buttonShadow.fontName = "AvenirNext-Bold"
        buttonShadow.position = CGPoint(x: buttonPosition.x + 2, y: buttonPosition.y - 2)
        buttonShadow.zPosition = 16
        camera?.addChild(buttonShadow)
        camera?.addChild(clampingButton)
    }
    
    // MARK: - Create Clamping Button with Background
    func createButton(withText text: String, position: CGPoint) -> SKLabelNode {
        let button = SKLabelNode(text: text)
        button.fontSize = 24
        button.fontColor = .black
        button.position = position
        button.zPosition = 11
        button.name = "clampingButton"

        let bgNode = SKSpriteNode(color: UIColor.gray, size: CGSize(width: 150, height: 40))
        bgNode.position = position
        bgNode.zPosition = 10
        cameraNode.addChild(bgNode)

        cameraNode.addChild(button)
        return button
    }
    
    // MARK: - 🧭 Navigation Buttons Setup
    func setupNavigationButtons() {
        // Progress Dashboard Button (moved to the left)
        let progressButton = createNavigationButton(text: "📊 進度", name: "progressButton", position: CGPoint(x: size.width / 2 - 150, y: -size.height / 2 + 50))  // ✅ Moved left (from -100 to -150)
        camera?.addChild(progressButton)
        
        // Vocabulary Button (moved to the left to fit on screen)
        let vocabularyButton = createNavigationButton(text: "📖 詞彙", name: "vocabularyButton", position: CGPoint(x: size.width / 2 - 50, y: -size.height / 2 + 50))  // ✅ Moved left (from center to -50)
        camera?.addChild(vocabularyButton)
        
        // Report Button (moved to the left)
        let reportButton = createNavigationButton(text: "📄 報告", name: "reportButton", position: CGPoint(x: size.width / 2 + 50, y: -size.height / 2 + 50))  // ✅ Moved left (from +100 to +50)
        camera?.addChild(reportButton)
    }
    
    func createNavigationButton(text: String, name: String, position: CGPoint) -> SKNode {
        let buttonBackground = SKShapeNode(rectOf: CGSize(width: 80, height: 40), cornerRadius: 8)
        buttonBackground.fillColor = UIColor.systemBlue.withAlphaComponent(0.8)
        buttonBackground.strokeColor = UIColor.white
        buttonBackground.lineWidth = 2
        buttonBackground.position = position
        buttonBackground.name = name
        buttonBackground.zPosition = 20
        
        let buttonLabel = SKLabelNode(text: text)
        buttonLabel.fontSize = 16
        buttonLabel.fontColor = .white
        buttonLabel.position = CGPoint(x: 0, y: -8)
        buttonBackground.addChild(buttonLabel)
        
        return buttonBackground
    }
    
    // MARK: - 🎮 Update UI - Enhanced Stats Display
    func updateUI() {
        // ✅ Update stats with icons and improved formatting
        levelLabel.text = "🏆 等級: \(PlayerProgress.shared.level)"
        xpLabel.text = "⭐ 經驗值: \(PlayerProgress.shared.xp)"
        scoreLabel.text = "🎯 積分: \(GameStats.shared.gameScore)"
        crystalCoinLabel.text = "💎 水晶: \(GameStats.shared.crystalCoins)"
        
        // ✅ Add visual feedback for level changes
        if PlayerProgress.shared.level > 1 {
            levelLabel.fontColor = UIColor.systemYellow
        }
        
        // ✅ Add visual feedback for high scores
        if GameStats.shared.gameScore > 100 {
            scoreLabel.fontColor = UIColor.systemGreen
        }
        
        // ✅ Add visual feedback for crystal collection
        if GameStats.shared.crystalCoins > 5 {
            crystalCoinLabel.fontColor = UIColor.systemPurple
        }
    }
    
    // ✅ Update UI from notification (called when returning from other scenes)
    @objc func updateUIFromNotification() {
        updateUI()
    }

    
    // MARK: - Handle Correct Answer
    func handleCorrectAnswer() {
        PlayerProgress.shared.addXP(amount: 20)
        checkForBadges()
        updateUI()
    }
    
    // MARK: - Badge System
    func checkForBadges() {
        if PlayerProgress.shared.level == 5 {
           // PlayerProgress.shared.unlockBadge("Level 5 Master!")
        }
    }
    // MARK: - Enter Clamping Machine
    func enterClampingMachine() {
        if GameStats.shared.crystalCoins >= 3 {  // ✅ Use stored value directly
            print("✅ Entering Clamping Scene")
            saveCurrentMapIndex()
            let clampingScene = ClampingScene(size: self.size)
            clampingScene.scaleMode = .aspectFill
            let transition = SKTransition.fade(withDuration: 1.0)
            self.view?.presentScene(clampingScene, transition: transition)
        } else {
            print("❌ Not enough crystals (Requires 3)")
            // ✅ Show feedback to user (optional: add a label or alert)
        }
    }
}
