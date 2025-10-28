import SpriteKit
import AVFoundation

class TransitionScene: SKScene {
    private var videoNode: SKVideoNode?
    private var explanationLabel: SKLabelNode!
    private var continueButton: SKLabelNode!
    private var shouldPlayVideo: Bool = false  // ✅ Set to `true` for video transitions
    private var continueButtonBackground: SKShapeNode!
    override func didMove(to view: SKView) {
        backgroundColor = .black
        setupBackground()
        
        // ✅ Delay text setup slightly to ensure background is set first
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            self.setupText()
        }
    }

    // MARK: - Setup Text and Button
    func setupText() {
        explanationLabel = SKLabelNode(text: "你遇到了森林的守護者...\n它想向你提問一個問題！")
        explanationLabel.fontSize = 30
        explanationLabel.fontColor = .black
        explanationLabel.numberOfLines = 0
        explanationLabel.preferredMaxLayoutWidth = size.width - 120
        explanationLabel.lineBreakMode = .byWordWrapping
        explanationLabel.horizontalAlignmentMode = .center
        explanationLabel.verticalAlignmentMode = .center
        explanationLabel.position = CGPoint(x: size.width / 2, y: size.height / 2 + 100)
        addChild(explanationLabel)

        // ✅ Dynamically adjust background size
        let labelFrame = explanationLabel.calculateAccumulatedFrame()
        let padding: CGFloat = 30
        let backgroundSize = CGSize(width: labelFrame.width + padding * 2, height: labelFrame.height + padding * 2)

        let textBackground = SKShapeNode(rectOf: backgroundSize, cornerRadius: 15)
        textBackground.fillColor = .white
        textBackground.strokeColor = .black
        textBackground.lineWidth = 2
        textBackground.position = explanationLabel.position
        textBackground.zPosition = 5
        addChild(textBackground)

        explanationLabel.zPosition = 6

        // ✅ Create Button Background (Default White)
        continueButtonBackground = SKShapeNode(rectOf: CGSize(width: 200, height: 60), cornerRadius: 15)
        continueButtonBackground.fillColor = .white  // ✅ Default background color
        continueButtonBackground.strokeColor = .black
        continueButtonBackground.position = CGPoint(x: size.width / 2, y: size.height / 5)
        continueButtonBackground.zPosition = 5
        addChild(continueButtonBackground)

        // ✅ Create Button Label
        continueButton = SKLabelNode(text: "點擊繼續")
        continueButton.fontSize = 28
        continueButton.fontColor = .black  // ✅ Default text color
        continueButton.position = continueButtonBackground.position
        continueButton.name = "continueButton"
        continueButton.zPosition = 6
        addChild(continueButton)
    }

    
    // MARK: - Setup Background (Video or Image)
    func setupBackground() {
        if shouldPlayVideo {
            // ✅ Play a full-screen video before transitioning
            guard let videoURL = Bundle.main.url(forResource: "transition_video", withExtension: "mp4") else {
                fatalError("Transition video file not found")
            }

            let player = AVPlayer(url: videoURL)
            videoNode = SKVideoNode(avPlayer: player)
            videoNode?.position = CGPoint(x: size.width / 2, y: size.height / 2)
            videoNode?.size = size
            videoNode?.zPosition = -1
            addChild(videoNode!)

            player.play()
        } else {
            // ✅ Show a full-screen image instead
            let backgroundImage = SKSpriteNode(imageNamed: "Transition_Image")
            backgroundImage.position = CGPoint(x: size.width / 2, y: size.height / 2)
            backgroundImage.size = size
            backgroundImage.zPosition = -1
            addChild(backgroundImage)
        }
    }

    // MARK: - Handle User Touch to Transition
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard let touch = touches.first else { return }
        let location = touch.location(in: self)
        let touchedNode = atPoint(location)

        if touchedNode.name == "continueButton" {
            // ✅ Change button appearance when pressed
            continueButtonBackground.fillColor = .black
            continueButton.fontColor = .white
        }
    }

    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard let touch = touches.first else { return }
        let location = touch.location(in: self)
        let touchedNode = atPoint(location)

        if touchedNode.name == "continueButton" {
            // ✅ Restore button appearance after release
            continueButtonBackground.fillColor = .white
            continueButton.fontColor = .black

            // ✅ Proceed to the next scene
            transitionToConversationScene()
        }
    }


    // MARK: - Transition to Conversation Scene
    func transitionToConversationScene() {
        let conversationScene = ConversationScene(size: self.size)
        conversationScene.scaleMode = .aspectFill
        let transition = SKTransition.fade(withDuration: 1.5)
        self.view?.presentScene(conversationScene, transition: transition)
    }
}
