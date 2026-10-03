import SpriteKit
import AVFoundation

class TransitionScene: SKScene, AVSpeechSynthesizerDelegate {
    private var videoNode: SKVideoNode?
    private var doll2VideoNode: ChromaKeyVideoNode?
    private var doll2AVPlayer: AVPlayer?
    private var explanationLabel: SKLabelNode!
    private var continueButton: SKLabelNode!
    private var shouldPlayVideo: Bool = false  // ✅ Set to `true` for video transitions
    private var continueButtonBackground: SKShapeNode!
    private var synthesizer = AVSpeechSynthesizer()  // ✅ Speech synthesizer
    private var playPauseButton: SKLabelNode?  // ✅ Play/pause button
    private var isPronunciationPlaying = false  // ✅ Track pronunciation state
    private var explanationText = "你遇到了森林的守護者...\n它想向你提問一個問題！"
    
    override func didMove(to view: SKView) {
        backgroundColor = .black
        setupBackground()
        setupDoll2Character()  // ✅ Setup doll2 character video
        synthesizer.delegate = self
        
        // ✅ Delay text setup slightly to ensure background is set first
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            self.setupText()
            self.setupPlayPauseButton()
            self.readExplanationAloud()
        }
    }
    
    // MARK: - Setup Doll2 Character Video
    func setupDoll2Character() {
        // ✅ Try to load doll2.mp4 video
        guard let videoURL = Bundle.main.url(forResource: "doll2", withExtension: "mp4") else {
            print("⚠️ doll2.mp4 not found, using fallback image")
            // Fallback to image if video not found
            let dollImage = SKSpriteNode(imageNamed: "Doll2")
            dollImage.size = CGSize(width: 200, height: 200)
            dollImage.position = CGPoint(x: size.width * 0.2, y: size.height * 0.4)
            dollImage.zPosition = 10  // Above background, below text
            addChild(dollImage)
            return
        }
        
        let node = ChromaKeyVideoNode(
            url: videoURL,
            size: CGSize(width: 200, height: 200),
            loops: true,
            muted: true
        )
        node.position = CGPoint(x: size.width * 0.2, y: size.height * 0.4)
        node.zPosition = 10
        node.name = "doll2Character"
        doll2VideoNode = node
        doll2AVPlayer = node.player
        addChild(node)
        node.play()
    }

    // MARK: - Setup Play/Pause Button
    func setupPlayPauseButton() {
        playPauseButton = SKLabelNode(text: "▶️")
        playPauseButton?.fontSize = 30
        playPauseButton?.fontColor = .white
        playPauseButton?.name = "playPauseButton"
        playPauseButton?.position = CGPoint(x: size.width - 50, y: size.height - 50)
        playPauseButton?.zPosition = 100
        addChild(playPauseButton!)
    }
    
    // MARK: - Update Play/Pause Button
    func updatePlayPauseButton() {
        if isPronunciationPlaying {
            playPauseButton?.text = "⏸️"
        } else {
            playPauseButton?.text = "▶️"
        }
    }
    
    // MARK: - Read Explanation Aloud
    func readExplanationAloud() {
        if synthesizer.isSpeaking { return }
        isPronunciationPlaying = true
        updatePlayPauseButton()
        
        let utterance = AVSpeechUtterance(string: explanationText)
        if let mandarinVoice = AVSpeechSynthesisVoice(language: "zh-CN") {
            utterance.voice = mandarinVoice
        } else if let cantoneseVoice = AVSpeechSynthesisVoice(language: "zh-HK") {
            utterance.voice = cantoneseVoice
        }
        utterance.rate = 0.5
        synthesizer.speak(utterance)
    }
    
    // MARK: - AVSpeechSynthesizerDelegate
    func speechSynthesizer(_ synthesizer: AVSpeechSynthesizer, didFinish utterance: AVSpeechUtterance) {
        isPronunciationPlaying = false
        updatePlayPauseButton()
    }
    
    func speechSynthesizer(_ synthesizer: AVSpeechSynthesizer, didStart utterance: AVSpeechUtterance) {
        isPronunciationPlaying = true
        updatePlayPauseButton()
    }

    // MARK: - Setup Text and Button
    func setupText() {
        explanationLabel = SKLabelNode(text: explanationText)
        explanationLabel.fontSize = 30
        explanationLabel.fontColor = .black
        explanationLabel.numberOfLines = 0
        explanationLabel.preferredMaxLayoutWidth = size.width - 120
        explanationLabel.lineBreakMode = .byWordWrapping
        explanationLabel.horizontalAlignmentMode = .center
        explanationLabel.verticalAlignmentMode = .center
        // ✅ Position text to the right side to make room for doll2 character on the left
        explanationLabel.position = CGPoint(x: size.width * 0.65, y: size.height / 2 + 100)
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
        
        // ✅ Add speech bubble pointer pointing to doll2 character
        let bubblePointer = SKShapeNode()
        let pointerPath = CGMutablePath()
        pointerPath.move(to: CGPoint(x: -20, y: 0))
        pointerPath.addLine(to: CGPoint(x: 0, y: -15))
        pointerPath.addLine(to: CGPoint(x: 20, y: 0))
        pointerPath.closeSubpath()
        bubblePointer.path = pointerPath
        bubblePointer.fillColor = .white
        bubblePointer.strokeColor = .black
        bubblePointer.lineWidth = 2
        bubblePointer.position = CGPoint(x: textBackground.position.x - backgroundSize.width / 2 - 10, y: textBackground.position.y - backgroundSize.height / 2)
        bubblePointer.zPosition = 5
        addChild(bubblePointer)

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
        if shouldPlayVideo,
           let videoURL = Bundle.main.url(forResource: "transition_video", withExtension: "mp4") {
            // ✅ Play a full-screen video before transitioning
            let player = AVPlayer(url: videoURL)
            videoNode = SKVideoNode(avPlayer: player)
            videoNode?.position = CGPoint(x: size.width / 2, y: size.height / 2)
            videoNode?.size = size
            videoNode?.zPosition = -1
            if let videoNode = videoNode {
                addChild(videoNode)
            }
            player.play()
        } else {
            if shouldPlayVideo {
                print("⚠️ transition_video.mp4 not found — using Transition_Image fallback")
            }
            // ✅ Show a full-screen image instead (also soft-fallback when video is missing)
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
        
        // ✅ Handle play/pause button
        if touchedNode.name == "playPauseButton" {
            if isPronunciationPlaying {
                synthesizer.stopSpeaking(at: .immediate)
                isPronunciationPlaying = false
            } else {
                readExplanationAloud()
            }
            updatePlayPauseButton()
            return
        }

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
        // ✅ Stop and cleanup video player before transitioning
        doll2VideoNode?.stop()
        doll2AVPlayer = nil
        doll2VideoNode?.removeFromParent()
        doll2VideoNode = nil
        NotificationCenter.default.removeObserver(self)
        
        let conversationScene = ConversationScene(size: self.size)
        conversationScene.scaleMode = .aspectFill
        let transition = SKTransition.fade(withDuration: 1.5)
        self.view?.presentScene(conversationScene, transition: transition)
    }
    
    // MARK: - Cleanup
    override func willMove(from view: SKView) {
        super.willMove(from: view)
        
        // ✅ Stop and cleanup video player
        doll2VideoNode?.stop()
        doll2AVPlayer = nil
        doll2VideoNode?.removeFromParent()
        doll2VideoNode = nil
        
        // ✅ Remove notification observers
        NotificationCenter.default.removeObserver(self)
    }
}
