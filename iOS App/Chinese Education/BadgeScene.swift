import SpriteKit
import AVFoundation

class BadgeScene: SKScene {
    private var videoNode: SKVideoNode?
    private var badgeLabel: SKLabelNode!
    private var continueButton: SKLabelNode!
    var badgeName: String = "New Badge!"  // ✅ Badge name to display

    override func didMove(to view: SKView) {
        backgroundColor = .black
        setupVideo()
        setupText()
    }

    // MARK: - Setup Background Video
    func setupVideo() {
        // Try Move2.mp4 → moving.mp4 → Doll1 sprite. Never crash when `*.mp4` are gitignored.
        if let videoURL = Bundle.main.url(forResource: "Move2", withExtension: "mp4") {
            setupVideoPlayer(url: videoURL)
        } else if let fallbackURL = Bundle.main.url(forResource: "moving", withExtension: "mp4") {
            print("⚠️ Move2.mp4 not found, falling back to moving.mp4")
            setupVideoPlayer(url: fallbackURL)
        } else {
            print("⚠️ Move2.mp4 and moving.mp4 not found — using Doll1 fallback for BadgeScene")
            setupDollFallback()
        }
    }
    
    // MARK: - Setup Video Player
    private func setupVideoPlayer(url: URL) {

        let player = AVPlayer(url: url)
        videoNode = SKVideoNode(avPlayer: player)
        videoNode?.position = CGPoint(x: size.width / 2, y: size.height / 2)
        videoNode?.size = size
        videoNode?.zPosition = -1
        
        // ✅ For transparent background video, the video file needs alpha channel
        // SpriteKit's SKVideoNode will respect the video's alpha channel if present
        // Note: The video file (Move2.mp4) should be encoded with alpha channel (e.g., ProRes 4444 or HEVC with alpha)
        if let videoNode = videoNode {
            addChild(videoNode)
        }

        player.play()
    }
    
    // MARK: - Doll1 Fallback (no video assets)
    private func setupDollFallback() {
        let doll = SKSpriteNode(imageNamed: "Doll1")
        doll.position = CGPoint(x: size.width / 2, y: size.height / 2)
        doll.setScale(2.5)
        doll.zPosition = -1
        doll.name = "badgeDollFallback"
        addChild(doll)
    }

    // MARK: - Setup Badge Text and Button
    func setupText() {
        badgeLabel = SKLabelNode(text: "🏅 \(badgeName)")
        badgeLabel.fontSize = 32
        badgeLabel.fontColor = .yellow
        badgeLabel.position = CGPoint(x: size.width / 2, y: size.height - 100)
        addChild(badgeLabel)

        continueButton = SKLabelNode(text: "點擊繼續")
        continueButton.fontSize = 28
        continueButton.fontColor = .white
        continueButton.position = CGPoint(x: size.width / 2, y: size.height / 4)
        continueButton.name = "continueButton"
        addChild(continueButton)
    }

    // MARK: - Handle User Touch to Return to Game
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard let touch = touches.first else { return }
        let location = touch.location(in: self)
        let touchedNode = atPoint(location)

        if touchedNode.name == "continueButton" {
            returnToGameScene()
        }
    }

    // MARK: - Transition Back to Game Scene
    func returnToGameScene() {
        let conversationScene = ConversationScene(size: self.size)
        conversationScene.scaleMode = .aspectFill
        let transition = SKTransition.fade(withDuration: 1.0)
        self.view?.presentScene(conversationScene, transition: transition)
    }
}
