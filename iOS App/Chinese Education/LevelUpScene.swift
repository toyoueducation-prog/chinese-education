import SpriteKit
import AVFoundation

class LevelUpScene: SKScene {
    private var videoNode: SKVideoNode?
    private var avPlayer: AVPlayer?
    private var continueButton: SKLabelNode!
    private var continueButtonBackground: SKShapeNode!
    private var levelLabel: SKLabelNode!
    private var messageLabel: SKLabelNode!
    var newLevel: Int = 1  // ✅ Level to display
    
    override func didMove(to view: SKView) {
        backgroundColor = .black
        setupVideo()
        setupUI()
    }
    
    // MARK: - Setup Video
    func setupVideo() {
        // ✅ Try to load level-up video, fallback to moving video
        guard let videoURL = Bundle.main.url(forResource: "levelup", withExtension: "mp4") else {
            print("⚠️ levelup.mp4 not found, falling back to moving.mp4")
            guard let fallbackURL = Bundle.main.url(forResource: "moving", withExtension: "mp4") else {
                print("⚠️ moving.mp4 also not found, skipping video")
                return
            }
            setupVideoPlayer(url: fallbackURL)
            return
        }
        setupVideoPlayer(url: videoURL)
    }
    
    // MARK: - Setup Video Player
    private func setupVideoPlayer(url: URL) {
        avPlayer = AVPlayer(url: url)
        avPlayer?.actionAtItemEnd = .none
        
        // ✅ Loop video
        NotificationCenter.default.addObserver(
            forName: .AVPlayerItemDidPlayToEndTime,
            object: avPlayer?.currentItem,
            queue: .main
        ) { [weak self] _ in
            self?.avPlayer?.seek(to: CMTime.zero)
            self?.avPlayer?.play()
        }
        
        videoNode = SKVideoNode(avPlayer: avPlayer!)
        videoNode?.position = CGPoint(x: size.width / 2, y: size.height / 2)
        videoNode?.size = size
        videoNode?.zPosition = -1
        addChild(videoNode!)
        
        avPlayer?.play()
    }
    
    // MARK: - Setup UI
    func setupUI() {
        // ✅ Level label
        levelLabel = SKLabelNode(text: "🎉 等級 \(newLevel)")
        levelLabel.fontSize = 64
        levelLabel.fontColor = .systemYellow
        levelLabel.fontName = "AvenirNext-Bold"
        levelLabel.position = CGPoint(x: size.width / 2, y: size.height - 200)
        levelLabel.zPosition = 100
        addChild(levelLabel)
        
        // ✅ Message label
        let messageText = "恭喜升級到小學 \(newLevel) 年級！"
        messageLabel = SKLabelNode(text: messageText)
        messageLabel.fontSize = 32
        messageLabel.fontColor = .white
        messageLabel.fontName = "AvenirNext-Medium"
        messageLabel.position = CGPoint(x: size.width / 2, y: size.height - 280)
        messageLabel.zPosition = 100
        addChild(messageLabel)
        
        // ✅ Continue button (standardized style)
        let backButtonSize = CGSize(width: 150, height: 50)
        continueButtonBackground = SKShapeNode(rectOf: backButtonSize, cornerRadius: 8)
        continueButtonBackground.fillColor = UIColor.white.withAlphaComponent(0.9)
        continueButtonBackground.strokeColor = UIColor.systemGray4
        continueButtonBackground.lineWidth = 1
        continueButtonBackground.position = CGPoint(x: size.width / 2, y: 100)
        continueButtonBackground.name = "continueButton"
        continueButtonBackground.zPosition = 100
        addChild(continueButtonBackground)
        
        continueButton = SKLabelNode(text: "繼續遊戲")
        continueButton.fontSize = 20
        continueButton.fontColor = .systemBlue
        continueButton.fontName = "AvenirNext-Medium"
        continueButton.position = continueButtonBackground.position
        continueButton.name = "continueButton"
        continueButton.zPosition = 101
        addChild(continueButton)
    }
    
    // MARK: - Handle Touches
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard let touch = touches.first else { return }
        let location = touch.location(in: self)
        let touchedNode = atPoint(location)
        
        if touchedNode.name == "continueButton" {
            // ✅ Visual feedback
            enumerateChildNodes(withName: "continueButton") { node, _ in
                if let background = node as? SKShapeNode {
                    background.fillColor = UIColor.white.withAlphaComponent(0.7)
                } else if let label = node as? SKLabelNode {
                    label.fontColor = .systemBlue.withAlphaComponent(0.7)
                }
            }
        }
    }
    
    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard let touch = touches.first else { return }
        let location = touch.location(in: self)
        let touchedNode = atPoint(location)
        
        if touchedNode.name == "continueButton" {
            // ✅ Restore button
            enumerateChildNodes(withName: "continueButton") { node, _ in
                if let background = node as? SKShapeNode {
                    background.fillColor = UIColor.white.withAlphaComponent(0.9)
                } else if let label = node as? SKLabelNode {
                    label.fontColor = .systemBlue
                }
            }
            
            // ✅ Return to game
            returnToGameScene()
        }
    }
    
    // MARK: - Return to Game
    func returnToGameScene() {
        avPlayer?.pause()
        videoNode?.removeFromParent()
        
        let gameScene = GameScene(size: self.size)
        gameScene.scaleMode = .aspectFill
        let transition = SKTransition.fade(withDuration: 1.0)
        self.view?.presentScene(gameScene, transition: transition)
    }
    
    // MARK: - Cleanup
    override func willMove(from view: SKView) {
        super.willMove(from: view)
        avPlayer?.pause()
        videoNode?.removeFromParent()
        NotificationCenter.default.removeObserver(self)
    }
}
