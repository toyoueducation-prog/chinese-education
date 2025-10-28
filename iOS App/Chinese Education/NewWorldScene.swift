import SpriteKit
import AVFoundation

class NewWorldScene: SKScene, SKPhysicsContactDelegate {
    private var playerImage: SKSpriteNode!
    private var playerVideoNode: SKVideoNode!
    private var avPlayer: AVPlayer!
    private var enemy: SKSpriteNode!
    private var cameraNode: SKCameraNode!
    private var isMoving = false
    private var moveDirection: CGVector = CGVector(dx: 0, dy: 0)
    private var player: SKSpriteNode!
    private var levelLabel: SKLabelNode!
    private var xpLabel: SKLabelNode!
    private var badgeLabel: SKLabelNode!
    private var worldLabel: SKLabelNode!
    private var scoreLabel: SKLabelNode!
    private var crystalCoinLabel: SKLabelNode!
    private var moveJoystick: SKNode!
    private var gameScore: Int = 0
    private var crystalCoins: Int = 0
    
    override func didMove(to view: SKView) {
        backgroundColor = .green
        physicsWorld.contactDelegate = self
        physicsWorld.gravity = .zero // Disable gravity for 2D movement
        
        setupMap()
        setupPlayer()
        setupEnemies()
        setupObjects()
        setupCamera()
        setupUI()
        updateUI()
    }
    
    // MARK: - Setup Background Map
    func setupMap() {
        let mapSize = CGSize(width: size.width * 2, height: size.height * 2)
        let map = SKSpriteNode(imageNamed: "Background") // Use asset as center background
        map.position = CGPoint(x: mapSize.width / 2, y: mapSize.height / 2)
        map.size = mapSize
        map.zPosition = -1
        addChild(map)
        
        let border = SKPhysicsBody(edgeLoopFrom: CGRect(origin: .zero, size: mapSize))
        self.physicsBody = border
    }
    
    // MARK: - Setup Player
    func setupPlayer() {
        let playerSize = CGSize(width: 60, height: 60) // Reduceåd by 50%
        
        // Setup static image
        playerImage = SKSpriteNode(imageNamed: "Doll2")
        playerImage.size = playerSize
        playerImage.position = CGPoint(x: size.width / 2, y: size.height / 2)
        playerImage.name = "player"
        addChild(playerImage)
        
        // Setup video node
        guard let videoURL = Bundle.main.url(forResource: "Water", withExtension: "mp4") else {
            fatalError("Video file not found")
        }
        
        avPlayer = AVPlayer(url: videoURL)
        avPlayer.actionAtItemEnd = .none // Loop the video
        NotificationCenter.default.addObserver(
            forName: .AVPlayerItemDidPlayToEndTime,
            object: avPlayer.currentItem,
            queue: .main
        ) { _ in
            self.avPlayer.seek(to: CMTime.zero)
            self.avPlayer.play()
        }
        
        playerVideoNode = SKVideoNode(avPlayer: avPlayer)
        playerVideoNode.size = playerSize
        playerVideoNode.position = playerImage.position
        playerVideoNode.zPosition = playerImage.zPosition
        playerVideoNode.isHidden = true
        addChild(playerVideoNode)
        
        // Setup player physics (no gravity, 2D movement)
        playerImage.physicsBody = SKPhysicsBody(rectangleOf: playerImage.size)
        playerImage.physicsBody?.isDynamic = true
        playerImage.physicsBody?.affectedByGravity = false
        playerImage.physicsBody?.allowsRotation = false
        playerImage.physicsBody?.linearDamping = 0
        playerImage.physicsBody?.categoryBitMask = 0x1 << 0
        playerImage.physicsBody?.collisionBitMask = 0x1 << 1
        playerImage.physicsBody?.contactTestBitMask = 0x1 << 1
    }
    
    func setupObjects() {
        let treeTexture = SKTexture(imageNamed: "tree")
        
        for _ in 0..<5 {
            let tree = SKSpriteNode(texture: treeTexture)
            tree.size = CGSize(width: 60, height: 60)
            tree.position = CGPoint(x: CGFloat.random(in: 100...size.width - 100),
                                    y: CGFloat.random(in: 100...size.height - 100))
            tree.physicsBody = SKPhysicsBody(rectangleOf: tree.size)
            tree.physicsBody?.isDynamic = false
            tree.physicsBody?.categoryBitMask = 0x1 << 2
            addChild(tree)
        }
    }
    
    // MARK: - Setup Camera
    func setupCamera() {
        cameraNode = SKCameraNode()
        camera = cameraNode
        cameraNode.position = playerImage.position // ✅ Start centered on player
        addChild(cameraNode)
    }
    
    override func update(_ currentTime: TimeInterval) {
        if isMoving {
            playerImage.position.x += moveDirection.dx
            playerImage.position.y += moveDirection.dy
            playerVideoNode.position = playerImage.position
            cameraNode.position = playerImage.position
        }
    }
    
    // MARK: - Handle Touch to Move Player
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard let touch = touches.first else { return }
        let location = touch.location(in: self)
        
        isMoving = true
        moveDirection = CGVector(dx: (location.x - playerImage.position.x) * 0.01,
                                 dy: (location.y - playerImage.position.y) * 0.01)
        
        // Switch to video node
        playerImage.isHidden = true
        playerVideoNode.isHidden = false
        avPlayer.play()
    }
    
    override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard let touch = touches.first else { return }
        let location = touch.location(in: self)
        
        // Update movement direction based on new touch location
        moveDirection = CGVector(dx: (location.x - playerImage.position.x) * 0.01,
                                 dy: (location.y - playerImage.position.y) * 0.01)
    }
    
    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        isMoving = false
        moveDirection = CGVector(dx: 0, dy: 0)
        
        // Switch back to static image
        playerImage.isHidden = false
        playerVideoNode.isHidden = true
        avPlayer.pause()
    }
    
    // MARK: - Setup Enemy
    func setupEnemies() {
        let texture = SKTexture(imageNamed: "Doll1")
        enemy = SKSpriteNode(texture: texture)
        enemy.size = CGSize(width: 60, height: 60)
        enemy.position = CGPoint(x: size.width / 2 + 100, y: size.height - 300)
        
        // Add physics body for collision detection
        enemy.physicsBody = SKPhysicsBody(rectangleOf: enemy.size)
        enemy.physicsBody?.isDynamic = false
        enemy.physicsBody?.affectedByGravity = false
        enemy.physicsBody?.categoryBitMask = 0x1 << 1
        enemy.physicsBody?.contactTestBitMask = 0x1 << 0
        enemy.physicsBody?.collisionBitMask = 0x1 << 0
        addChild(enemy)
    }
    
    // MARK: - Handle Collision
    func didBegin(_ contact: SKPhysicsContact) {
        let contactA = contact.bodyA.categoryBitMask
        let contactB = contact.bodyB.categoryBitMask
        
        if (contactA == 0x1 << 0 && contactB == 0x1 << 1) ||
            (contactA == 0x1 << 1 && contactB == 0x1 << 0) {
            transitionToConversationScene()
        }
    }
    
    // MARK: - Transition to Conversation Scene on Collision
    func transitionToConversationScene() {
        let conversationScene = ConversationScene(size: self.size)
        conversationScene.scaleMode = .aspectFill
        let transition = SKTransition.fade(withDuration: 1.0)
        self.view?.presentScene(conversationScene, transition: transition)
    }
    
    // MARK: - Setup UI Elements
    func setupUI() {
        levelLabel = SKLabelNode(text: "Level: \(PlayerProgress.shared.level)")
        levelLabel.fontSize = 20
        levelLabel.position = CGPoint(x: size.width / 2, y: size.height - 50)
        addChild(levelLabel)
        
        xpLabel = SKLabelNode(text: "XP: \(PlayerProgress.shared.xp)")
        xpLabel.fontSize = 20
        xpLabel.position = CGPoint(x: size.width / 2, y: size.height - 80)
        addChild(xpLabel)
        
        badgeLabel = SKLabelNode(text: "Badges: \(PlayerProgress.shared.badges.count)")
        badgeLabel.fontSize = 20
        badgeLabel.position = CGPoint(x: size.width / 2, y: size.height - 110)
        addChild(badgeLabel)
        
        worldLabel = SKLabelNode(text: "Unlocked Worlds: \(PlayerProgress.shared.unlockedWorlds.joined(separator: ", "))")
        worldLabel.fontSize = 16
        worldLabel.position = CGPoint(x: size.width / 2, y: size.height - 140)
        addChild(worldLabel)
        
        scoreLabel = SKLabelNode(text: "Score: \(gameScore)")
        scoreLabel.fontSize = 24
        scoreLabel.fontColor = .white
        scoreLabel.position = CGPoint(x: -size.width / 2 + 100, y: size.height / 2 - 50)
        scoreLabel.zPosition = 10
        cameraNode.addChild(scoreLabel)

        crystalCoinLabel = SKLabelNode(text: "Crystals: \(crystalCoins)")
        crystalCoinLabel.fontSize = 24
        crystalCoinLabel.fontColor = .yellow
        crystalCoinLabel.position = CGPoint(x: -size.width / 2 + 100, y: size.height / 2 - 80)
        crystalCoinLabel.zPosition = 10
        cameraNode.addChild(crystalCoinLabel)
    }
    
    // MARK: - Update UI
    func updateUI() {
        levelLabel.text = "Level: \(PlayerProgress.shared.level)"
        xpLabel.text = "XP: \(PlayerProgress.shared.xp)"
        badgeLabel.text = "Badges: \(PlayerProgress.shared.badges.count)"
        worldLabel.text = "Unlocked Worlds: \(PlayerProgress.shared.unlockedWorlds.joined(separator: ", "))"
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
    
}
