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
        guard let videoURL = Bundle.main.url(forResource: "moving", withExtension: "mp4") else {
            fatalError("Badge video file not found")
        }

        let player = AVPlayer(url: videoURL)
        videoNode = SKVideoNode(avPlayer: player)
        videoNode?.position = CGPoint(x: size.width / 2, y: size.height / 2)
        videoNode?.size = size
        videoNode?.zPosition = -1
        addChild(videoNode!)

        player.play()
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
