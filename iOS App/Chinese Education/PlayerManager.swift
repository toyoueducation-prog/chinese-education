import SpriteKit
import AVFoundation

// MARK: - 👤 PLAYER MANAGER - Main Character Control System
class PlayerManager {
    static let shared = PlayerManager()  // Singleton pattern
    
    // MARK: - 🎮 PLAYER VISUAL COMPONENTS
    var playerImage: SKSpriteNode!       // Main player sprite (Doll1 texture)
    var playerVideoNode: SKVideoNode!    // Animated player video (moving.mp4)
    var avPlayer: AVPlayer!              // Video player for animations

    private init() {}  // Private initializer for singleton

    // MARK: - Setup Player
    func setupPlayer(in scene: SKScene) {
        let playerSize = CGSize(width: 60, height: 60)

        playerImage = SKSpriteNode(imageNamed: "Doll1")
        playerImage.size = playerSize
        playerImage.name = "player"

        // ✅ Load saved position
        if let savedPosition = UserDefaults.standard.dictionary(forKey: "playerPosition") as? [String: CGFloat] {
            playerImage.position = CGPoint(x: savedPosition["x"] ?? scene.size.width / 2,
                                           y: savedPosition["y"] ?? scene.size.height / 2)
        } else {
            playerImage.position = CGPoint(x: scene.size.width / 2, y: scene.size.height / 2)
        }

        scene.addChild(playerImage)

        // Setup video node
        guard let videoURL = Bundle.main.url(forResource: "moving", withExtension: "mp4") else {
            fatalError("Video file not found")
        }

        avPlayer = AVPlayer(url: videoURL)
        avPlayer.actionAtItemEnd = .none
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
        scene.addChild(playerVideoNode)

        // Setup player physics
        // ✅ Ensure the player has a physics body
        playerImage.physicsBody = SKPhysicsBody(rectangleOf: playerImage.size)
        playerImage.physicsBody?.isDynamic = true  // ✅ Allow movement
        playerImage.physicsBody?.affectedByGravity = false
        playerImage.physicsBody?.allowsRotation = false
        playerImage.physicsBody?.categoryBitMask = 0x1 << 0  // ✅ Player category
        playerImage.physicsBody?.collisionBitMask = 0x1 << 2 // ✅ Collides with obstacles
        playerImage.physicsBody?.contactTestBitMask = 0x1 << 1 // ✅ Detects enemy collision
    }

    // MARK: - Save Player Position
    func savePlayerPosition() {
        let positionDict: [String: CGFloat] = [
            "x": playerImage.position.x,
            "y": playerImage.position.y
        ]
        UserDefaults.standard.set(positionDict, forKey: "playerPosition")
    }
}
