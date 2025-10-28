import SpriteKit
import AVFoundation

// MARK: - 🎬 WELCOME BACK SCENE - Return Player Video Player
class WelcomeBackScene: SKScene {
    
    // MARK: - 🎥 VIDEO COMPONENTS
    private var videoNode: SKVideoNode?  // Video display node
    
    // MARK: - 🎮 VIDEO CONTROLS
    private var skipButton: SKLabelNode!              // Skip video button
    private var pauseResumeButton: SKLabelNode!       // Pause/Resume button
    private var pauseResumeButtonBackground: SKShapeNode!  // Button background
    override func didMove(to view: SKView) {
        backgroundColor = .black
        playIntroductionVideo()
        addSkipButton()
    }

    // ✅ Play the Introduction Video
    private func playIntroductionVideo() {
        guard let videoURL = Bundle.main.url(forResource: "welcomeback", withExtension: "mp4") else {
            print("❌ Video file not found")
            transitionToGameScene() // Fallback if video missing
            return
        }

        let player = AVPlayer(url: videoURL)
        videoNode = SKVideoNode(avPlayer: player)

        // ✅ Get original video size using modern API
        let asset = AVURLAsset(url: videoURL)
        Task {
            do {
                let tracks = try await asset.loadTracks(withMediaType: .video)
                if let track = tracks.first {
                    let naturalSize = try await track.load(.naturalSize)
                    let preferredTransform = try await track.load(.preferredTransform)
                    let videoSize = naturalSize.applying(preferredTransform)
                    
                    // ✅ Calculate scale factor while maintaining aspect ratio
                    let scaleFactor = min(size.width / videoSize.width, size.height / videoSize.height)
                    
                    // ✅ Set the video node size proportionally
                    await MainActor.run {
                        videoNode?.size = CGSize(width: videoSize.width * scaleFactor, height: videoSize.height * scaleFactor)
                    }
                } else {
                    // ✅ Fallback to default size if no video track found
                    await MainActor.run {
                        videoNode?.size = CGSize(width: 1920, height: 1080)
                    }
                }
            } catch {
                // ✅ Fallback to default size if loading fails
                await MainActor.run {
                    videoNode?.size = CGSize(width: 1920, height: 1080)
                }
            }
        }

        videoNode?.position = CGPoint(x: size.width / 2, y: size.height / 2)
        videoNode?.zPosition = 0
        addChild(videoNode!)

        // ✅ Play video
        player.play()

        // ✅ Automatically transition when video ends
        NotificationCenter.default.addObserver(
            forName: .AVPlayerItemDidPlayToEndTime,
            object: player.currentItem,
            queue: .main
        ) { _ in
            self.transitionToGameScene()
        }
    }


    // ✅ Add Skip Button
    private func addSkipButton() {
        skipButton = SKLabelNode(text: "跳過")
        skipButton.fontSize = 28
        skipButton.fontColor = .white
        skipButton.position = CGPoint(x: size.width / 2, y: 50)  // ✅ Bottom center
        skipButton.name = "skipButton"
        addChild(skipButton)
    }
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard let touch = touches.first else { return }
        let location = touch.location(in: self)
        let touchedNode = atPoint(location)
        if touchedNode.name == "skipButton" {
            stopVideoAndTransition()
        }
    
    }

    private func stopVideoAndTransition() {
        // ✅ Stop the video playback
        videoNode?.removeFromParent()
        videoNode = nil  // ✅ Remove reference

        // ✅ Transition to GameScene
        transitionToGameScene()
    }

    // ✅ Transition to Game Scene
    private func transitionToGameScene() {
        UserDefaults.standard.set(true, forKey: "hasSeenIntro")  // ✅ Mark intro as seen

        let gameScene = GameScene(size: size)
        gameScene.scaleMode = .aspectFill
        self.view?.presentScene(gameScene, transition: SKTransition.fade(withDuration: 1.5))
    }
}
