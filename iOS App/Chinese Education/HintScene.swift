import SpriteKit

class HintScene: SKScene {
    var incorrectQuestions: Set<String> = []  // ✅ Stores incorrect question keys
    private var continueButtonBackground: SKShapeNode!
    private var continueButton: SKLabelNode!
    override func didMove(to view: SKView) {
        backgroundColor = .white

        // ✅ Fetch passage from question bank
        var passageText = "沒有可用的段落"
        if let firstQuestionKey = incorrectQuestions.first,
           let passage = QuestionBank.shared.getPassageForQuestion(firstQuestionKey) {
            passageText = passage
        }

        
        // ✅ Display passage again
        let passageLabel = SKLabelNode(text: passageText)
        passageLabel.fontSize = 22  // ✅ Increased font size
        passageLabel.fontColor = .black
        passageLabel.horizontalAlignmentMode = .center
        passageLabel.verticalAlignmentMode = .top
        passageLabel.numberOfLines = 5
        passageLabel.preferredMaxLayoutWidth = size.width - 80  // ✅ More margin
        passageLabel.lineBreakMode = .byWordWrapping
        passageLabel.position = CGPoint(x: size.width / 2, y: size.height - 100) // ✅ More top spacing
        addChild(passageLabel)

        // ✅ Fetch full questions instead of question keys
        var incorrectQuestionText = "沒有錯誤答案！"
        if !incorrectQuestions.isEmpty {
            let incorrectFullQuestions = incorrectQuestions.compactMap { QuestionBank.shared.getFullQuestion(forKey: $0) }
            incorrectQuestionText = "你回答錯誤的問題:\n" + incorrectFullQuestions.joined(separator: "\n")
        }

        let passageHeight = passageLabel.calculateAccumulatedFrame().height
        let questionStartY = size.height - 120 - passageHeight - 30  // ✅ More space between passage and question
        
        // ✅ Position the questionLabel lower, relative to passageLabel
        let questionLabel = SKLabelNode(text: incorrectQuestionText)
        questionLabel.fontSize = 22
        questionLabel.fontColor = .red
        questionLabel.position = CGPoint(x: size.width / 2, y: questionStartY - 50)  // ✅ Lower placement
        questionLabel.numberOfLines = 5
        questionLabel.preferredMaxLayoutWidth = size.width - 60
        questionLabel.lineBreakMode = .byWordWrapping
        addChild(questionLabel)
        
        // ✅ Create Button Background (Default White)
        continueButtonBackground = SKShapeNode(rectOf: CGSize(width: 200, height: 60), cornerRadius: 15)
        continueButtonBackground.fillColor = .white  // ✅ Default background color
        continueButtonBackground.strokeColor = .black
        continueButtonBackground.position = CGPoint(x: size.width / 2, y: size.height / 5)
        continueButtonBackground.zPosition = 5
        addChild(continueButtonBackground)
        
        // ✅ Create Button Label
        continueButton = SKLabelNode(text: "回到遊戲")
        continueButton.fontSize = 28
        continueButton.fontColor = .black  // ✅ Default text color
        continueButton.position = continueButtonBackground.position
        continueButton.name = "continueButton"
        continueButton.zPosition = 6
        addChild(continueButton)
    }

    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard let touch = touches.first else { return }
        let location = touch.location(in: self)
        let touchedNode = atPoint(location)

        if touchedNode.name == "continueButton" {
            // ✅ Change button color when pressed
            continueButtonBackground.fillColor = .black
            continueButton.fontColor = .white
        }
    }

    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard let touch = touches.first else { return }
        let location = touch.location(in: self)
        let touchedNode = atPoint(location)

        if touchedNode.name == "continueButton" {
            // ✅ Restore button color when released
            continueButtonBackground.fillColor = .white
            continueButton.fontColor = .black

            print("✅ Debug: Returning to GameScene")

            let gameScene = GameScene(size: self.size)
            gameScene.scaleMode = .aspectFill
            let transition = SKTransition.fade(withDuration: 1.0)

            if let view = self.view {
                view.presentScene(gameScene, transition: transition)
            } else {
                print("❌ Debug: view is nil, cannot transition to GameScene")
            }
        }
    }

}
