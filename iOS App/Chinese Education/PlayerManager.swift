import SpriteKit
import AVFoundation

// MARK: - 👤 PLAYER MANAGER - Main Character Control System
class PlayerManager {
    static let shared = PlayerManager()  // Singleton pattern
    
    // MARK: - 🎮 PLAYER VISUAL COMPONENTS
    var playerImage: SKSpriteNode!       // Main player sprite (Doll1 texture)
    var playerCropNode: SKCropNode!      // ✅ Crop node for oval/circular shape
    /// Optional walk animation. Nil when Move2/moving.mp4 are absent (root `.gitignore` ignores `*.mp4`).
    var playerVideoNode: SKVideoNode?
    var avPlayer: AVPlayer?

    private init() {}  // Private initializer for singleton

    // MARK: - Setup Player
    func setupPlayer(in scene: SKScene) {
        let playerSize = CGSize(width: 60, height: 60)

        // ✅ Create player image with oval/circular shape (always available via Assets.xcassets/Doll1)
        let originalImage = SKSpriteNode(imageNamed: "Doll1")
        originalImage.size = playerSize
        
        // ✅ Create circular mask for oval shape
        let maskNode = SKShapeNode(ellipseOf: playerSize)
        maskNode.fillColor = .white
        maskNode.strokeColor = .clear
        
        // ✅ Use SKCropNode to create circular/oval visual shape
        playerCropNode = SKCropNode()
        playerCropNode.maskNode = maskNode
        playerCropNode.addChild(originalImage)
        playerCropNode.name = "player"
        
        // ✅ Store references
        playerImage = originalImage  // Keep reference for compatibility
        playerImage.name = "player"

        // ✅ Load saved position
        let savedX = UserDefaults.standard.dictionary(forKey: "playerPosition")?["x"] as? CGFloat ?? scene.size.width / 2
        let savedY = UserDefaults.standard.dictionary(forKey: "playerPosition")?["y"] as? CGFloat ?? scene.size.height / 2
        let playerPosition = CGPoint(x: savedX, y: savedY)
        
        playerCropNode.position = playerPosition
        playerImage.position = CGPoint.zero  // Relative to cropNode
        scene.addChild(playerCropNode)

        // Optional walk video: Move2.mp4 → moving.mp4 → Doll1 sprite only (never crash).
        // Packaging: add Move2.mp4 / moving.mp4 locally under the app target; they are gitignored as `*.mp4`.
        if let videoURL = Bundle.main.url(forResource: "Move2", withExtension: "mp4") {
            setupVideoPlayer(url: videoURL)
        } else if let fallbackURL = Bundle.main.url(forResource: "moving", withExtension: "mp4") {
            print("⚠️ Move2.mp4 not found, falling back to moving.mp4")
            setupVideoPlayer(url: fallbackURL)
        } else {
            print("⚠️ Move2.mp4 and moving.mp4 not found — using Doll1 sprite only")
            playerVideoNode = nil
            avPlayer = nil
        }
        
        setupPlayerPhysics(playerSize: playerSize)
    }
    
    // MARK: - Setup Video Player (with transparent background support)
    private func setupVideoPlayer(url: URL) {
        let playerSize = CGSize(width: 60, height: 60)
        
        avPlayer = AVPlayer(url: url)
        avPlayer?.actionAtItemEnd = .none
        NotificationCenter.default.addObserver(
            forName: .AVPlayerItemDidPlayToEndTime,
            object: avPlayer?.currentItem,
            queue: .main
        ) { [weak self] _ in
            self?.avPlayer?.seek(to: CMTime.zero)
            self?.avPlayer?.play()
        }

        let videoNode = SKVideoNode(avPlayer: avPlayer!)
        videoNode.size = playerSize
        videoNode.position = CGPoint.zero  // Relative to cropNode
        videoNode.zPosition = playerImage.zPosition
        videoNode.isHidden = true
        playerVideoNode = videoNode
        
        // ✅ For transparent background video, the video file itself needs to have alpha channel
        // SpriteKit's SKVideoNode will respect the video's alpha channel if present
        // Note: The video file (move2.mp4) should be encoded with alpha channel (e.g., ProRes 4444 or HEVC with alpha)
        playerCropNode.addChild(videoNode)
    }
    
    // MARK: - Setup Player Physics
    private func setupPlayerPhysics(playerSize: CGSize) {
        // ✅ Use circular physics body for oval/circular collision
        let radius = min(playerSize.width, playerSize.height) / 2
        playerCropNode.physicsBody = SKPhysicsBody(circleOfRadius: radius)
        playerCropNode.physicsBody?.isDynamic = true  // ✅ Allow movement
        playerCropNode.physicsBody?.affectedByGravity = false
        playerCropNode.physicsBody?.allowsRotation = false
        playerCropNode.physicsBody?.categoryBitMask = 0x1 << 0  // ✅ Player category
        playerCropNode.physicsBody?.collisionBitMask = 0x1 << 2 // ✅ Collides with obstacles
        playerCropNode.physicsBody?.contactTestBitMask = 0x1 << 1 // ✅ Detects enemy collision
    }

    // MARK: - Save Player Position
    func savePlayerPosition() {
        guard let cropNode = playerCropNode else { return }
        let positionDict: [String: CGFloat] = [
            "x": cropNode.position.x,
            "y": cropNode.position.y
        ]
        UserDefaults.standard.set(positionDict, forKey: "playerPosition")
    }
    
    /// Show walk animation when video assets exist; otherwise keep Doll1 visible.
    func setWalking(_ walking: Bool) {
        guard let videoNode = playerVideoNode, let player = avPlayer else {
            playerImage?.isHidden = false
            return
        }
        playerImage?.isHidden = walking
        videoNode.isHidden = !walking
        if walking {
            player.play()
        } else {
            player.pause()
        }
    }
}
