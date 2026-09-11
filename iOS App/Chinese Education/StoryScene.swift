// Legacy scene — not wired from SignInScene / GameScene (kept for reference).
import SpriteKit

class StoryScene: SKScene {
    private var storyLabel: SKLabelNode!
    private var continueButton: SKLabelNode!

    override func didMove(to view: SKView) {
        backgroundColor = .black
        setupStory()
    }

    func setupStory() {
        let storyText = "You have reached level \(PlayerProgress.shared.level)!\n"
            + "New challenges await you in \(PlayerProgress.shared.unlockedWorlds.last ?? "the unknown world")!"
        
        storyLabel = SKLabelNode(text: storyText)
        storyLabel.fontSize = 24
        storyLabel.fontColor = .white
        storyLabel.position = CGPoint(x: size.width / 2, y: size.height / 2)
        storyLabel.numberOfLines = 2
        addChild(storyLabel)

        continueButton = SKLabelNode(text: "Continue")
        continueButton.fontSize = 28
        continueButton.fontColor = .blue
        continueButton.position = CGPoint(x: size.width / 2, y: size.height / 4)
        continueButton.name = "continueButton"
        addChild(continueButton)
    }

    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard let touch = touches.first else { return }
        let location = touch.location(in: self)
        let touchedNode = atPoint(location)

        if touchedNode.name == "continueButton" {
            let gameScene = GameScene(size: self.size)
            gameScene.scaleMode = .aspectFill
            self.view?.presentScene(gameScene)
        }
    }
}
