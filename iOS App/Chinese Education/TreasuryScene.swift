import SpriteKit
import AVFoundation

class TreasuryScene: SKScene {
    private var continueButton: SKLabelNode!
    private var continueButtonBackground: SKShapeNode!
    private var titleLabel: SKLabelNode!
    private var rewardLabel: SKLabelNode!
    
    override func didMove(to view: SKView) {
        setupProfessionalBackground()
        setupUI()
        
        // ✅ Award random rewards
        awardRewards()
    }
    
    // MARK: - Setup Professional Background
    func setupProfessionalBackground() {
        let gradientLayer = SKShapeNode(rectOf: size)
        gradientLayer.fillColor = UIColor(red: 0.2, green: 0.3, blue: 0.4, alpha: 1.0)  // Dark blue-gray
        gradientLayer.strokeColor = .clear
        gradientLayer.position = CGPoint(x: size.width / 2, y: size.height / 2)
        gradientLayer.zPosition = -100
        addChild(gradientLayer)
        
        let patternOverlay = SKShapeNode(rectOf: size)
        patternOverlay.fillColor = UIColor.white.withAlphaComponent(0.1)
        patternOverlay.strokeColor = .clear
        patternOverlay.position = CGPoint(x: size.width / 2, y: size.height / 2)
        patternOverlay.zPosition = -99
        addChild(patternOverlay)
    }
    
    // MARK: - Setup UI
    func setupUI() {
        // ✅ Title
        titleLabel = SKLabelNode(text: "💰 寶箱")
        titleLabel.fontSize = 48
        titleLabel.fontColor = .systemYellow
        titleLabel.fontName = "AvenirNext-Bold"
        titleLabel.position = CGPoint(x: size.width / 2, y: size.height - 150)
        titleLabel.zPosition = 10
        addChild(titleLabel)
        
        // ✅ Reward label
        rewardLabel = SKLabelNode(text: "")
        rewardLabel.fontSize = 24
        rewardLabel.fontColor = .white
        rewardLabel.fontName = "AvenirNext-Medium"
        rewardLabel.horizontalAlignmentMode = .center
        rewardLabel.numberOfLines = 0
        rewardLabel.position = CGPoint(x: size.width / 2, y: size.height / 2)
        rewardLabel.zPosition = 10
        addChild(rewardLabel)
        
        // ✅ Back button (standardized style)
        let backButtonSize = CGSize(width: 120, height: 44)
        continueButtonBackground = SKShapeNode(rectOf: backButtonSize, cornerRadius: 8)
        continueButtonBackground.fillColor = UIColor.white.withAlphaComponent(0.9)
        continueButtonBackground.strokeColor = UIColor.systemGray4
        continueButtonBackground.lineWidth = 1
        continueButtonBackground.position = CGPoint(x: 60, y: size.height - 50)
        continueButtonBackground.name = "continueButton"
        continueButtonBackground.zPosition = 100
        addChild(continueButtonBackground)
        
        continueButton = SKLabelNode(text: "← 返回遊戲")
        continueButton.fontSize = 18
        continueButton.fontColor = .systemBlue
        continueButton.fontName = "AvenirNext-Medium"
        continueButton.position = continueButtonBackground.position
        continueButton.name = "continueButton"
        continueButton.zPosition = 101
        addChild(continueButton)
    }
    
    // MARK: - Award Rewards
    func awardRewards() {
        // ✅ Random rewards: XP, Crystal Coins, or both
        let rewards: [String] = [
            "獲得 30 經驗值！",
            "獲得 50 經驗值！",
            "獲得 5 水晶！",
            "獲得 10 水晶！",
            "獲得 30 經驗值 + 3 水晶！",
            "獲得 50 經驗值 + 5 水晶！"
        ]
        
        let randomReward = rewards.randomElement() ?? rewards[0]
        rewardLabel.text = randomReward
        
        // ✅ Apply rewards
        if randomReward.contains("經驗值") {
            let xpAmount = randomReward.contains("50") ? 50 : 30
            PlayerProgress.shared.addXP(amount: xpAmount)
            print("💰 Treasury reward: +\(xpAmount) XP")
        }
        
        if randomReward.contains("水晶") {
            let coinAmount = randomReward.contains("10") ? 10 : (randomReward.contains("5") ? 5 : 3)
            GameStats.shared.crystalCoins += coinAmount
            print("💰 Treasury reward: +\(coinAmount) Crystal Coins")
        }
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
        let gameScene = GameScene(size: self.size)
        gameScene.scaleMode = .aspectFill
        let transition = SKTransition.fade(withDuration: 1.0)
        self.view?.presentScene(gameScene, transition: transition)
    }
}
