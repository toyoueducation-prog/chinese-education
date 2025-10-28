import SpriteKit
import AVFoundation

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
    private var transitionCooldown = false              // Prevents looping transition
    
    // MARK: - 🗺️ MAP SYSTEM
    private var treePositions: [CGPoint] = []           // Tree obstacle positions
    private var hasGeneratedMap = false                 // Map generation flag
    
    // MARK: - 🗺️ MINI-MAP SYSTEM
    private var miniMap: SKSpriteNode!                  // Mini-map background
    private var playerDot: SKShapeNode!                 // Player position dot on mini-map
    private var NPCDot: SKShapeNode!                    // NPC position dot on mini-map
    private var npcDots: [SKShapeNode] = []             // Array of NPC dots on mini-map
    
    // MARK: - 👾 ENEMY & NPC SPAWNING
    private var hasSpawnedEnemies = false               // Enemy spawn flag
    private var hasSpawnedNPCs = false                  // NPC spawn flag
    
    // MARK: - 🗺️ MODERN MAP SYSTEM (Parallel Implementation)
    private var currentMapName: String = "level_1"      // Current map name
    private var useModernMapSystem: Bool = false        // Toggle between old and new systems
    // MARK: - 🗺️ GAME MAP LAYOUT (21x20 Grid)
    // Map Legend: "S"=Stone Walls, "."=Grass Paths, "T"=Trees, "G"=Grass Areas, "W"=Water, "P"=Player Spawn
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
        ["S",".",".",".",".","G","G",".",".",".","G","G",".",".",".",".",".",".",".",".","S"], // Row 16: Grass areas
        ["S",".",".",".",".","G","G",".",".",".","G","G",".","P",".",".",".",".",".",".","S"], // Row 17: Player spawn area
        ["S",".",".",".",".","G","G",".",".",".","G","G",".","P",".",".",".",".",".",".","S"], // Row 18: Player spawn area
        ["S","S","S","S","S","S","S","S","S","S","S","S","S","S","S","S","S","S","S","S","S"]  // Row 19: Bottom boundary
    ]
    
    
    override func didMove(to view: SKView) {
        backgroundColor = .green
        physicsWorld.contactDelegate = self
        physicsWorld.gravity = .zero // Disable gravity for 2D movement

        let isFreshStart = !UserDefaults.standard.bool(forKey: "hasSeenIntro")

        if isFreshStart {
            GameStats.shared.resetScore()  // ✅ Reset scores
            GameStats.shared.crystalCoins = 0
            print("✅ Debug: Game restarted from scratch")
        }
        
        // 🗺️ MODERN MAP SYSTEM - Check if enabled
        useModernMapSystem = UserDefaults.standard.bool(forKey: "useModernMapSystem")
        MapManager.shared.enableModernMapSystem(useModernMapSystem)
        
        if useModernMapSystem {
            // Load saved level or default to level 1
            currentMapName = UserDefaults.standard.string(forKey: "currentLevel") ?? "level_1"
            loadModernMap()
        } else {
            // Original map system
            if !hasGeneratedMap {
                renderFixedMap()
                hasGeneratedMap = true
            }
        }

        //setupObjects()
        if !hasSpawnedEnemies {
            if useModernMapSystem {
                // Spawn enemies based on current level
                if let mapInfo = MapManager.shared.getCurrentMapInfo() {
                    NPC.shared.spawnEnemies(in: self, count: mapInfo.enemyCount)
                }
            } else {
                NPC.shared.spawnEnemies(in: self, count: 2)
            }
            hasSpawnedEnemies = true
        }
        
        // ✅ Setup Player FIRST to avoid nil error
        PlayerManager.shared.setupPlayer(in: self)

        setupCamera()
        setupUI()
        setupMiniMap()  // ✅ Add Mini-Map
        setupMapSystemToggle()  // Add toggle button for testing
        updateUI()

        // ✅ Move player slightly away from enemy after returning
        if lastCollidedEnemy != nil {
                print("🔄 Moving player slightly away from enemy after return")
                PlayerManager.shared.playerImage?.position.x += 50  // ✅ Pushes player slightly to the right
            }

            // ✅ Activate Safe Zone (No Collision for 2 Seconds)
            transitionCooldown = true
            DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
                self.transitionCooldown = false
                print("✅ Collision re-enabled after safe zone")
            }

        print("✅ Debug: All Game Elements Initialized_v2 - Map System: \(useModernMapSystem ? "Modern" : "Original")")
    }

    private func renderFixedMap() {
        let tileSize = CGSize(width: 64, height: 64)
        for (row, tiles) in mapLayout.enumerated() {
            for (col, symbol) in tiles.enumerated() {
                let tileName = imageName(for: symbol)
                let tileNode = SKSpriteNode(imageNamed: tileName)
                tileNode.size = tileSize
                tileNode.anchorPoint = CGPoint(x: 0, y: 1)
                
                let xPos = CGFloat(col) * tileSize.width - size.width / 2
                let yPos = size.height / 2 - CGFloat(row) * tileSize.height
                tileNode.position = CGPoint(x: xPos, y: yPos)
                tileNode.zPosition = -1
                addChild(tileNode)
                
                if symbol == "P" {
                    PlayerManager.shared.playerImage?.position = CGPoint(x: xPos, y: yPos)
                }
                
                // Add physics body to block player movement
                if ["T", "W", "S"].contains(symbol) {
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

    private func imageName(for symbol: Character) -> String {
        switch symbol {
        case "G": return "grass2"
        case "W": return "water"
        case "S": return "stone2"
        case "T": return "tree"
        case ".", "P": return "path"
        default: return "grass"
        }
    }
    
    private func setupMiniMap() {
        let mapScale: CGFloat = 0.15

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

        // ✅ NPC markers on mini-map
        for _ in NPC.shared.enemyNodes {
            let npcDot = SKShapeNode(circleOfRadius: 3)
            npcDot.fillColor = .blue
            npcDot.zPosition = 22
            miniMap.addChild(npcDot)
            npcDots.append(npcDot)
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
            let clusterCenter = CGPoint(
                x: CGFloat.random(in: 100...(size.width - 100)),
                y: CGFloat.random(in: 100...(size.height - 100))
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
        cameraNode.position = PlayerManager.shared.playerImage.position // ✅ Start centered on player
        addChild(cameraNode)
    }

    
    func distanceBetween(_ pos1: CGPoint, _ pos2: CGPoint) -> CGFloat {
        return sqrt(pow(pos2.x - pos1.x, 2) + pow(pos2.y - pos1.y, 2))
    }
    
    override func update(_ currentTime: TimeInterval) {
        if isMoving {
            PlayerManager.shared.playerImage.position.x += moveDirection.dx
            PlayerManager.shared.playerImage.position.y += moveDirection.dy
            PlayerManager.shared.playerVideoNode.position = PlayerManager.shared.playerImage.position

            // ✅ Ensure camera follows the player
            cameraNode.position = PlayerManager.shared.playerImage.position
        }

        guard let playerNode = PlayerManager.shared.playerImage else { return }
        guard PlayerManager.shared.playerImage != nil else { return }
        guard let miniMap = miniMap, let playerDot = playerDot else { return }

        let _: CGFloat = 0.15
        let miniMapX = (playerNode.position.x / (size.width * 2)) * miniMap.size.width
        let miniMapY = (playerNode.position.y / (size.height * 2)) * miniMap.size.height
        playerDot.position = CGPoint(x: miniMapX, y: miniMapY)
        
        // ✅ Update NPC positions on the mini-map
        for (index, npc) in NPC.shared.enemyNodes.enumerated() {
            if index < npcDots.count {
                let npcMapX = (npc.position.x / (size.width * 2)) * miniMap.size.width
                let npcMapY = (npc.position.y / (size.height * 2)) * miniMap.size.height
                npcDots[index].position = CGPoint(x: npcMapX, y: npcMapY)
            }
        }

        // Update parallax background
        updateParallax()
        
        // Ensure orphaned NPC dots are removed
        while npcDots.count > NPC.shared.enemyNodes.count {
            npcDots.last?.removeFromParent()
            npcDots.removeLast()
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
        let location = touch.location(in: self)
        let touchedNode = atPoint(location)
        
        // ✅ Detect Click on Clamping Button
        if touchedNode.name == "clampingButton" {
            enterClampingMachine()
            return
        }
        
        // 🗺️ MODERN MAP SYSTEM - Handle new button touches
        if touchedNode.name == "mapSystemToggle" {
            toggleMapSystem()
            return
        }
        
        if touchedNode.name == "levelSelectorButton" {
            showLevelSelector()
            return
        }
        
        // Handle level selector overlay touches
        if let overlay = camera?.childNode(withName: "levelSelectorOverlay") {
            if touchedNode.name == "closeLevelSelector" {
                overlay.removeFromParent()
                return
            }
            
            // Check for level selection
            if let levelName = touchedNode.name?.replacingOccurrences(of: "level_", with: "") {
                if MapManager.shared.getAvailableMaps().contains(where: { $0.name == levelName }) {
                    handleLevelSelection(levelName)
                    return
                }
            }
        }
        
        isMoving = true
        moveDirection = CGVector(dx: (location.x - PlayerManager.shared.playerImage.position.x) * 0.01,
                                 dy: (location.y - PlayerManager.shared.playerImage.position.y) * 0.01)
        
        // Switch to video node
        PlayerManager.shared.playerImage.isHidden = true
        PlayerManager.shared.playerVideoNode.isHidden = false
        PlayerManager.shared.avPlayer.play()
    }
    
    override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard let touch = touches.first else { return }
        let location = touch.location(in: self)
        
        // Update movement direction based on new touch location
        moveDirection = CGVector(dx: (location.x - PlayerManager.shared.playerImage.position.x) * 0.01,
                                 dy: (location.y - PlayerManager.shared.playerImage.position.y) * 0.01)
    }
    
    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        isMoving = false
        moveDirection = CGVector(dx: 0, dy: 0)
        
        // Switch back to static image
        PlayerManager.shared.playerImage.isHidden = false
        PlayerManager.shared.playerVideoNode.isHidden = true
        PlayerManager.shared.avPlayer.pause()
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
            "x": PlayerManager.shared.playerImage.position.x,
            "y": PlayerManager.shared.playerImage.position.y
        ]
        UserDefaults.standard.set(positionDict, forKey: "playerPosition")
    }
    
    // MARK: - Handle Collision
    func didBegin(_ contact: SKPhysicsContact) {
        let bodyA = contact.bodyA.node
        let bodyB = contact.bodyB.node

        let playerNode = PlayerManager.shared.playerImage
        let enemyNode = bodyA == playerNode ? bodyB : bodyA  // ✅ Identify enemy

            let firstBody = contact.bodyA.categoryBitMask
            let secondBody = contact.bodyB.categoryBitMask

        
        if let enemy = enemyNode as? SKSpriteNode, enemy.name == "enemy" {
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
                
                // ✅ Store last collided enemy
                lastCollidedEnemy = enemyNode
                
                // ✅ Activate cooldown to prevent looping
                transitionCooldown = true
                
                // Remove enemy from scene
                enemy.removeFromParent()

                // Find the index of the enemy
                if let enemyIndex = NPC.shared.enemyNodes.firstIndex(of: enemy) {
                    // Remove enemy from enemyNodes list
                    NPC.shared.enemyNodes.remove(at: enemyIndex)

                    // Remove corresponding NPC dot from minimap
                    if npcDots.indices.contains(enemyIndex) {
                        npcDots[enemyIndex].removeFromParent()
                        npcDots.remove(at: enemyIndex)
                    }
                }
                
                // ✅ Transition to conversation scene
                transitionToConversationScene()
            }
        }

    }
    
    // MARK: - Transition to Conversation Scene on Collision
    func transitionToConversationScene() {
        
        let transitionScene = TransitionScene(size: self.size)
        transitionScene.scaleMode = .aspectFill
        let transition = SKTransition.fade(withDuration: 2.0)
        self.view?.presentScene(transitionScene, transition: transition)

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
    func enterClampingMachine() {
        
    }
    
    // MARK: - 🗺️ MODERN MAP SYSTEM FUNCTIONS (Parallel Implementation)
    
    // MARK: - Load Modern Map
    private func loadModernMap() {
        print("🗺️ Loading modern map: \(currentMapName)")
        
        guard let tileMap = MapManager.shared.loadMap(named: currentMapName, in: self) else {
            print("❌ Failed to load modern map, falling back to original system")
            useModernMapSystem = false
            UserDefaults.standard.set(false, forKey: "useModernMapSystem")
            if !hasGeneratedMap {
                renderFixedMap()
                hasGeneratedMap = true
            }
            return
        }
        
        // Position the tile map
        tileMap.position = CGPoint(x: 0, y: 0)
        tileMap.zPosition = -10
        addChild(tileMap)
        
        // Setup parallax background
        setupParallaxBackground()
        
        // Setup collision from modern map
        setupModernMapCollision()
        
        // Position player at spawn point
        let spawnPoint = MapManager.shared.getPlayerSpawnPoint()
        PlayerManager.shared.playerImage?.position = spawnPoint
        
        print("✅ Modern map loaded successfully")
    }
    
    // MARK: - Setup Modern Map Collision
    private func setupModernMapCollision() {
        let collisionNodes = MapManager.shared.getCollidableTiles()
        
        for collisionNode in collisionNodes {
            addChild(collisionNode)
        }
        
        print("✅ Modern map collision setup complete: \(collisionNodes.count) collision areas")
    }
    
    // MARK: - Map System Toggle UI
    private func setupMapSystemToggle() {
        let toggleButton = SKLabelNode(text: useModernMapSystem ? "🗺️ 現代地圖" : "🗺️ 原始地圖")
        toggleButton.fontSize = 16
        toggleButton.fontColor = .white
        toggleButton.fontName = "AvenirNext-Bold"
        toggleButton.position = CGPoint(x: size.width / 2 - 200, y: size.height / 2 - 250)
        toggleButton.zPosition = 17
        toggleButton.name = "mapSystemToggle"
        
        // Add background
        let bgNode = SKSpriteNode(color: UIColor.black.withAlphaComponent(0.7), size: CGSize(width: 120, height: 30))
        bgNode.position = toggleButton.position
        bgNode.zPosition = 16
        bgNode.name = "mapSystemToggleBG"
        
        camera?.addChild(bgNode)
        camera?.addChild(toggleButton)
        
        // Add level selector if modern system is enabled
        if useModernMapSystem {
            setupLevelSelector()
        }
    }
    
    // MARK: - Level Selector UI
    private func setupLevelSelector() {
        let levelButton = SKLabelNode(text: "🎮 選擇關卡")
        levelButton.fontSize = 16
        levelButton.fontColor = .white
        levelButton.fontName = "AvenirNext-Bold"
        levelButton.position = CGPoint(x: size.width / 2 - 200, y: size.height / 2 - 290)
        levelButton.zPosition = 17
        levelButton.name = "levelSelectorButton"
        
        // Add background
        let bgNode = SKSpriteNode(color: UIColor.systemBlue.withAlphaComponent(0.7), size: CGSize(width: 120, height: 30))
        bgNode.position = levelButton.position
        bgNode.zPosition = 16
        bgNode.name = "levelSelectorBG"
        
        camera?.addChild(bgNode)
        camera?.addChild(levelButton)
    }
    
    // MARK: - Level Transition
    func transitionToLevel(_ levelName: String) {
        guard useModernMapSystem else {
            print("⚠️ Modern map system not enabled")
            return
        }
        
        print("🔄 Transitioning to level: \(levelName)")
        
        // Save current level
        UserDefaults.standard.set(levelName, forKey: "currentLevel")
        
        // Fade out
        let fadeOut = SKAction.fadeOut(withDuration: 0.5)
        camera?.run(fadeOut) {
            // Load new map
            self.currentMapName = levelName
            self.loadModernMap()
            
            // Respawn enemies for new level
            NPC.shared.enemyNodes.forEach { $0.removeFromParent() }
            NPC.shared.enemyNodes.removeAll()
            
            if let mapInfo = MapManager.shared.getCurrentMapInfo() {
                NPC.shared.spawnEnemies(in: self, count: mapInfo.enemyCount)
            }
            
            // Update UI
            self.updateMapSystemUI()
            
            // Fade in
            let fadeIn = SKAction.fadeIn(withDuration: 0.5)
            self.camera?.run(fadeIn)
        }
    }
    
    // MARK: - Update Map System UI
    private func updateMapSystemUI() {
        // Update toggle button text
        if let toggleButton = camera?.childNode(withName: "mapSystemToggle") as? SKLabelNode {
            toggleButton.text = useModernMapSystem ? "🗺️ 現代地圖" : "🗺️ 原始地圖"
        }
        
        // Update level selector if modern system is enabled
        if useModernMapSystem {
            if let levelButton = camera?.childNode(withName: "levelSelectorButton") as? SKLabelNode {
                if let mapInfo = MapManager.shared.getCurrentMapInfo() {
                    levelButton.text = "🎮 \(mapInfo.displayName)"
                }
            }
        }
    }
    
    // MARK: - Setup Parallax Background
    private func setupParallaxBackground() {
        guard useModernMapSystem else { return }
        
        // Create background layers for depth
        let bgLayers = [
            ("Morning_Forest_Background", 0.1, -100),
            ("Background2", 0.3, -50)
        ]
        
        for (imageName, scrollFactor, zPos) in bgLayers {
            let bg = SKSpriteNode(imageNamed: imageName)
            bg.position = CGPoint(x: 0, y: 0)
            bg.zPosition = CGFloat(zPos)
            bg.name = "\(imageName)_layer"
            bg.size = CGSize(width: size.width * 2, height: size.height * 2)
            addChild(bg)
            
            // Store scroll factor in userData
            bg.userData = ["scrollFactor": scrollFactor]
        }
    }
    
    // MARK: - Update Parallax
    private func updateParallax() {
        guard useModernMapSystem else { return }
        
        enumerateChildNodes(withName: "//*_layer") { node, _ in
            if let scrollFactor = node.userData?["scrollFactor"] as? CGFloat {
                node.position.x = -cameraNode.position.x * scrollFactor
                node.position.y = -cameraNode.position.y * scrollFactor * 0.5
            }
        }
    }
    
    // MARK: - Toggle Map System
    private func toggleMapSystem() {
        useModernMapSystem.toggle()
        UserDefaults.standard.set(useModernMapSystem, forKey: "useModernMapSystem")
        MapManager.shared.enableModernMapSystem(useModernMapSystem)
        
        print("🔄 Toggled map system to: \(useModernMapSystem ? "Modern" : "Original")")
        
        // Restart the scene to apply changes
        let transition = SKTransition.fade(withDuration: 1.0)
        if let newScene = GameScene(fileNamed: "GameScene") {
            newScene.scaleMode = .aspectFill
            self.view?.presentScene(newScene, transition: transition)
        }
    }
    
    // MARK: - Show Level Selector
    private func showLevelSelector() {
        guard useModernMapSystem else { return }
        
        let availableMaps = MapManager.shared.getAvailableMaps()
        let currentLevel = PlayerProgress.shared.level
        
        // Create level selection overlay
        let overlay = SKSpriteNode(color: UIColor.black.withAlphaComponent(0.8), size: size)
        overlay.position = CGPoint(x: size.width / 2, y: size.height / 2)
        overlay.zPosition = 100
        overlay.name = "levelSelectorOverlay"
        camera?.addChild(overlay)
        
        // Add title
        let title = SKLabelNode(text: "選擇關卡")
        title.fontSize = 24
        title.fontColor = .white
        title.fontName = "AvenirNext-Bold"
        title.position = CGPoint(x: 0, y: 100)
        title.zPosition = 101
        overlay.addChild(title)
        
        // Add level buttons
        for (index, mapInfo) in availableMaps.enumerated() {
            let isUnlocked = currentLevel >= mapInfo.unlockLevel
            let buttonText = isUnlocked ? mapInfo.displayName : "🔒 \(mapInfo.displayName)"
            
            let levelButton = SKLabelNode(text: buttonText)
            levelButton.fontSize = 18
            levelButton.fontColor = isUnlocked ? .white : .gray
            levelButton.fontName = "AvenirNext-Bold"
            levelButton.position = CGPoint(x: 0, y: 50 - (index * 40))
            levelButton.zPosition = 101
            levelButton.name = "level_\(mapInfo.name)"
            levelButton.isUserInteractionEnabled = isUnlocked
            overlay.addChild(levelButton)
            
            // Add background for button
            let bgNode = SKSpriteNode(color: isUnlocked ? UIColor.systemBlue.withAlphaComponent(0.7) : UIColor.gray.withAlphaComponent(0.3), size: CGSize(width: 200, height: 35))
            bgNode.position = levelButton.position
            bgNode.zPosition = 100
            bgNode.name = "level_bg_\(mapInfo.name)"
            overlay.addChild(bgNode)
        }
        
        // Add close button
        let closeButton = SKLabelNode(text: "❌ 關閉")
        closeButton.fontSize = 18
        closeButton.fontColor = .white
        closeButton.fontName = "AvenirNext-Bold"
        closeButton.position = CGPoint(x: 0, y: -150)
        closeButton.zPosition = 101
        closeButton.name = "closeLevelSelector"
        overlay.addChild(closeButton)
    }
    
    // MARK: - Handle Level Selection
    private func handleLevelSelection(_ levelName: String) {
        // Remove overlay
        camera?.childNode(withName: "levelSelectorOverlay")?.removeFromParent()
        
        // Transition to selected level
        transitionToLevel(levelName)
    }
    
    // MARK: - Enter Clamping Machine (Complete Implementation)
    func enterClampingMachineComplete() {
        if GameStats.shared.crystalCoins >= 3 {  // ✅ Use stored value directly
            print("✅ Entering Clamping Scene")
            let clampingScene = ClampingScene(size: self.size)
            clampingScene.scaleMode = .aspectFill
            let transition = SKTransition.fade(withDuration: 1.0)
            self.view?.presentScene(clampingScene, transition: transition)
        } else {
            print("❌ Not enough crystals (Requires 3)")
        }
    }

struct PhysicsCategory {
    static let none: UInt32 = 0
    static let player: UInt32 = 0x1 << 0
    static let enemy: UInt32 = 0x1 << 1
}

}
