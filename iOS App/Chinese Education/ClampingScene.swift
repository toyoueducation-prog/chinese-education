import SpriteKit

/**
 * CLAMPING SCENE - Claw Machine Mini-Game
 * 
 * A fun mini-game where players use a claw machine to collect dolls/stars.
 * This scene provides a break from educational content while still rewarding
 * players with crystal coins and score points.
 * 
 * Gameplay:
 * - Players tap left/right to move the claw horizontally
 * - Tap "夾取" (Grab) button to drop the claw
 * - If claw successfully grabs a doll, it lifts it up
 * - When doll reaches the top, player receives rewards
 * - Dolls fade out with animation and star count increases
 * 
 * Costs & Rewards:
 * - Costs 3 crystal coins per game attempt
 * - Rewards random amount of crystal coins (1-5) and score points
 * - Tracks total stars/dolls collected
 * 
 * UI Elements:
 * - Claw and claw arm (2.5D depth effect)
 * - Grab button (white background, positioned left)
 * - Instructions panel (Traditional Chinese, right side)
 * - Star count display (top center)
 * - Reward message display
 * - Back button to return to GameScene
 */
// MARK: - 🎰 CLAW MACHINE SCENE - Mini-Game for Collecting Dolls
class ClampingScene: SKScene {
    
    // MARK: - 🎰 CLAW MACHINE COMPONENTS
    let claw = SKSpriteNode(imageNamed: "clamp")        // Claw sprite
    let clawArm = SKSpriteNode(imageNamed: "claw_arm")  // Arm extending down
    let grabButton = SKLabelNode(text: "夾取")          // Button for grabbing
    var grabButtonBackground: SKShapeNode!              // Button background
    
    // MARK: - 🎭 DOLL COLLECTION SYSTEM
    var dolls: [SKSpriteNode] = []      // Array of collectible dolls
    var selectedDoll: SKSpriteNode?     // The doll currently being clamped
    var rewardLabel: SKLabelNode!       // Reward display
    var backButton: SKLabelNode!        // Back button
    var instructionsLabel: SKLabelNode! // Instructions in Traditional Chinese
    var starCountLabel: SKLabelNode!    // Label showing number of stars collected
    var starCount: Int = 0              // Track number of stars collected
    var hasSuccessfullyClamped: Bool = false  // Track if a doll was successfully clamped
    var isClawLifting: Bool = false  // Track if claw is currently lifting
    
    override func didMove(to view: SKView) {
        backgroundColor = .lightGray
        
        // ✅ Reset success flag when scene loads
        hasSuccessfullyClamped = false
        
        // **1. Add Background (Machine Interior for Depth)**
        let background = SKSpriteNode(imageNamed: "Clampingmachine")
        background.position = CGPoint(x: size.width / 2, y: size.height / 2)
        background.zPosition = -1  // Send it to the back
        background.size = CGSize(width: size.width, height: size.height)
        addChild(background)
        
        // **2. Setup Claw Arm for 2.5D Depth**
        clawArm.position = CGPoint(x: size.width / 2, y: size.height - 150)
        clawArm.size = CGSize(width: 40, height: 150)
        clawArm.zPosition = 2  // Claw arm behind claw
        addChild(clawArm)
        
        // **3. Setup Claw**
        claw.position = CGPoint(x: size.width / 2, y: clawArm.position.y - 75)
        claw.size = CGSize(width: 80, height: 80)
        claw.zPosition = 3  // Claw in front
        addChild(claw)
        
        // **4. Setup Grab Button (Colored background, centered at bottom)**
        let buttonWidth: CGFloat = 120
        let buttonHeight: CGFloat = 60
        let buttonX = size.width / 2  // ✅ Centered horizontally
        let buttonY: CGFloat = 100  // ✅ Positioned at bottom
        
        grabButtonBackground = SKShapeNode(rectOf: CGSize(width: buttonWidth, height: buttonHeight), cornerRadius: 10)
        grabButtonBackground.fillColor = .systemBlue  // ✅ Colored button (blue)
        grabButtonBackground.strokeColor = .white
        grabButtonBackground.lineWidth = 3
        grabButtonBackground.position = CGPoint(x: buttonX, y: buttonY)
        grabButtonBackground.name = "grabButton"
        grabButtonBackground.zPosition = 5
        addChild(grabButtonBackground)
        
        grabButton.fontSize = 28
        grabButton.fontColor = .white  // ✅ White text on colored background
        grabButton.position = CGPoint(x: buttonX, y: buttonY)
        grabButton.name = "grabButton"
        grabButton.zPosition = 6
        addChild(grabButton)
        
        // **5. Setup Instructions (Traditional Chinese on right side)**
        let instructionsText = """
        遊戲說明：
        
        1. 點擊螢幕左右移動
        夾爪位置
        
        2. 點擊「夾取」按鈕
        放下夾爪
        
        3. 成功夾到娃娃後
        會獲得獎勵
        
        4. 每次遊戲消耗
        3個水晶
        """
        
        instructionsLabel = SKLabelNode(text: instructionsText)
        instructionsLabel.fontSize = 18  // ✅ Slightly larger font for better readability
        instructionsLabel.fontColor = .black
        instructionsLabel.fontName = "PingFangTC-Regular"
        instructionsLabel.numberOfLines = 0
        instructionsLabel.preferredMaxLayoutWidth = size.width * 0.32  // ✅ Slightly wider for better text layout
        instructionsLabel.horizontalAlignmentMode = .left
        instructionsLabel.verticalAlignmentMode = .top
        // ✅ Position instructions to fit better on screen
        instructionsLabel.position = CGPoint(x: size.width * 0.68, y: size.height - 90)  // ✅ Adjusted position
        instructionsLabel.zPosition = 101  // ✅ Higher zPosition to be in front of background
        
        // Add background for instructions (adjusted size and position for better fit)
        let instructionsWidth = size.width * 0.32
        let instructionsHeight: CGFloat = 300  // ✅ Slightly taller to accommodate text
        let instructionsBackground = SKShapeNode(rectOf: CGSize(width: instructionsWidth, height: instructionsHeight), cornerRadius: 15)  // ✅ Larger corner radius
        instructionsBackground.fillColor = UIColor.white.withAlphaComponent(0.95)  // ✅ More opaque for better readability
        instructionsBackground.strokeColor = .systemBlue  // ✅ Colored border to match button
        instructionsBackground.lineWidth = 3
        instructionsBackground.position = CGPoint(x: size.width * 0.68, y: size.height - 240)  // ✅ Centered with label
        instructionsBackground.zPosition = 100  // ✅ Higher zPosition to be in front of background
        addChild(instructionsBackground)
        addChild(instructionsLabel)
        
        // **6. Setup Reward Display**
        rewardLabel = SKLabelNode(text: "")
        rewardLabel.fontSize = 24
        rewardLabel.fontColor = .systemGreen
        rewardLabel.fontName = "AvenirNext-Bold"
        rewardLabel.position = CGPoint(x: size.width / 2, y: size.height - 100)
        rewardLabel.zPosition = 100  // ✅ Higher zPosition to be in front of background
        rewardLabel.isHidden = true
        addChild(rewardLabel)
        
        // **6.5. Setup Star Count Label**
        // ✅ Load collected dolls count from GameStats
        starCount = GameStats.shared.collectedDolls
        starCountLabel = SKLabelNode(text: "⭐ 已收集: \(starCount)")
        starCountLabel.fontSize = 22
        starCountLabel.fontColor = .systemYellow
        starCountLabel.fontName = "AvenirNext-Bold"
        starCountLabel.position = CGPoint(x: size.width / 2, y: size.height - 50)
        starCountLabel.zPosition = 100  // ✅ Higher zPosition to be in front of background
        addChild(starCountLabel)
        
        // **7. Setup Back Button**
        backButton = SKLabelNode(text: "返回遊戲")
        backButton.fontSize = 24
        backButton.fontColor = .systemBlue
        backButton.position = CGPoint(x: 100, y: size.height - 50)
        backButton.name = "backButton"
        backButton.zPosition = 100  // ✅ Higher zPosition to be in front of background
        addChild(backButton)
        
        // **8. Add Random Dolls (Larger size)**
        for _ in 0..<2 {
            for i in 0..<4 {
                let doll = SKSpriteNode(imageNamed: "Clampingdoll\(i + 1)")  // Clampingdoll1-5
                let xPos = CGFloat.random(in: 150...(size.width - 150))
                let yPos = CGFloat.random(in: 180...260)  // Slight variation for depth
                
                // ✅ Larger doll size
                let baseSize: CGFloat = 100  // Increased from 60
                let scaleFactor = 1.0 - ((yPos - 180) / 80) * 0.2  // Slight perspective
                
                doll.position = CGPoint(x: xPos, y: yPos)
                doll.size = CGSize(width: baseSize * scaleFactor, height: baseSize * scaleFactor)
                doll.zPosition = 1  // Behind claw
                doll.name = "doll"
                addChild(doll)
                dolls.append(doll)
            }
        }
    }

    // **9. Move Claw with Touch (Left/Right Perspective)**
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard let touch = touches.first else { return }
            let location = touch.location(in: self)
        let touchedNode = atPoint(location)

        // Check for back button
        if touchedNode.name == "backButton" {
            transitionToGameScene()
            return
        }

        // Check for grab button (both label and background)
        if touchedNode.name == "grabButton" || touchedNode == grabButton || touchedNode == grabButtonBackground {
                dropClaw()
            return
        }

        // Move claw to touch position
        moveClaw(to: location.x)
    }

    // **7. Move Claw Left & Right**
    func moveClaw(to xPosition: CGFloat) {
        let moveAction = SKAction.moveTo(x: xPosition, duration: 0.3)
        let moveArmAction = SKAction.moveTo(x: xPosition, duration: 0.3)
        claw.run(moveAction)
        clawArm.run(moveArmAction)
    }

    // **8. Drop Claw to Grab Doll (2.5D Effect)**
    func dropClaw() {
        isClawLifting = false  // Reset lifting flag
        let dropArmAction = SKAction.scaleY(to: 1.2, duration: 0.5)  // Extend arm
        let dropClawAction = SKAction.moveTo(y: 100, duration: 0.5)
        let grabAction = SKAction.run { self.checkForDoll() }
        let liftClawAction = SKAction.moveTo(y: clawArm.position.y - 75, duration: 0.5)
        let liftArmAction = SKAction.scaleY(to: 1.0, duration: 0.5)  // Retract arm
        let markLifting = SKAction.run { self.isClawLifting = true }  // Mark that claw is lifting
        let checkSuccess = SKAction.run { self.checkIfDollReachedTop() }  // Check if doll reached top after lift

        let sequence = SKAction.sequence([dropArmAction, dropClawAction, grabAction, markLifting, liftClawAction, liftArmAction, checkSuccess])
        clawArm.run(dropArmAction)
        claw.run(sequence)
    }

    // **10. Check for Doll Grab**
    func checkForDoll() {
        for doll in dolls {
            // ✅ Increased grab range for larger dolls
            if abs(doll.position.x - claw.position.x) < 60 {
                selectedDoll = doll
                let grabEffect = SKAction.scale(to: 0.8, duration: 0.2)  // Slight scale effect
                doll.run(grabEffect)
                return
            }
        }
        selectedDoll = nil
    }

    // **11. Transition Doll to Collection (If Grabbed)**
    override func update(_ currentTime: TimeInterval) {
        if let doll = selectedDoll {
            // ✅ Make doll follow the claw position
            let targetY = claw.position.y - 30
            let liftDollAction = SKAction.moveTo(y: targetY, duration: 0.2)
            doll.run(liftDollAction)
            
            // ✅ Check if doll has reached the top (only if claw is lifting)
            if isClawLifting {
                let clawFinalY = clawArm.position.y - 75
                let dollTargetY = clawFinalY - 30
                let threshold: CGFloat = 80  // Allow tolerance
                
                // ✅ Check if doll is close enough to the target position
                if doll.position.y >= dollTargetY - threshold && !hasSuccessfullyClamped {
                    print("✅ Doll successfully reached top! Position: \(doll.position.y), Target: \(dollTargetY)")
                    hasSuccessfullyClamped = true
                    
                    // ✅ Deduct 3 crystal coins when successfully clamping
                    GameStats.shared.crystalCoins -= 3
                    print("💰 Deducted 3 crystal coins. Remaining: \(GameStats.shared.crystalCoins)")
                    
                    showReward()
                    removeDollWithFade(doll)  // ✅ Use fade-out animation
                    selectedDoll = nil
                    
                    // ✅ Auto-transition back to GameScene after a few seconds
                    DispatchQueue.main.asyncAfter(deadline: .now() + 3.0) {
                        self.transitionToGameScene()
                    }
                }
            }
        }
    }
    
    // **11.5. Check if Doll Reached Top (Called after claw finishes lifting)**
    func checkIfDollReachedTop() {
        // ✅ Additional check after claw finishes lifting (backup check)
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
            if let doll = self.selectedDoll, !self.hasSuccessfullyClamped {
                let clawFinalY = self.clawArm.position.y - 75
                let dollTargetY = clawFinalY - 30
                let threshold: CGFloat = 100  // Allow more tolerance
                
                print("🔍 Backup check - Doll position: \(doll.position.y), target: \(dollTargetY)")
                
                // ✅ Check if doll is close enough to the target position
                if doll.position.y >= dollTargetY - threshold {
                    print("✅ Doll successfully reached top (backup check)! Updating stats...")
                    self.hasSuccessfullyClamped = true
                    
                    // ✅ Deduct 3 crystal coins when successfully clamping
                    GameStats.shared.crystalCoins -= 3
                    print("💰 Deducted 3 crystal coins (backup). Remaining: \(GameStats.shared.crystalCoins)")
                    
                    self.showReward()
                    self.removeDollWithFade(doll)  // ✅ Use fade-out animation
                    self.selectedDoll = nil
                    
                    // ✅ Auto-transition back to GameScene after a few seconds
                    DispatchQueue.main.asyncAfter(deadline: .now() + 3.0) {
                        self.transitionToGameScene()
                    }
                }
            }
        }
    }
    
    // **12. Show Reward**
    func showReward() {
        // ✅ Add reward (crystal coins or score) - deduction already happened when doll was clamped
        let rewardAmount = Int.random(in: 1...5)
        GameStats.shared.crystalCoins += rewardAmount
        GameStats.shared.addScore(points: rewardAmount * 10)
        
        // ✅ Display reward message (showing net change: -3 + reward)
        let netChange = rewardAmount - 3
        if netChange >= 0 {
            rewardLabel.text = "🎉 獲得 \(rewardAmount) 個水晶！\n(扣除3個，淨得\(netChange)個)\n+\(rewardAmount * 10) 積分"
        } else {
            rewardLabel.text = "🎉 獲得 \(rewardAmount) 個水晶！\n(扣除3個，淨得\(netChange)個)\n+\(rewardAmount * 10) 積分"
        }
        rewardLabel.isHidden = false
        
        // ✅ Animate reward
        let fadeIn = SKAction.fadeIn(withDuration: 0.3)
        let wait = SKAction.wait(forDuration: 2.0)
        let fadeOut = SKAction.fadeOut(withDuration: 0.3)
        let hide = SKAction.run { self.rewardLabel.isHidden = true }
        rewardLabel.run(SKAction.sequence([fadeIn, wait, fadeOut, hide]))
    }
    
    // **13. Remove Doll After Collection with Fade Animation**
    func removeDollWithFade(_ doll: SKSpriteNode) {
        // ✅ Increment star count
        starCount += 1
        
        // ✅ Save to GameStats for persistence
        GameStats.shared.collectedDolls = starCount
        
        // ✅ Add 50 experience points when doll is collected
        let oldLevel = PlayerProgress.shared.level
        PlayerProgress.shared.addXP(amount: 50)
        let newLevel = PlayerProgress.shared.level
        let currentXP = PlayerProgress.shared.xp
        
        // ✅ Check if level increased
        if newLevel > oldLevel {
            print("🎉 Level Up! Reached Level \(newLevel)!")
            // ✅ Show level up message
            showLevelUpMessage(level: newLevel)
        }
        
        // ✅ Update star count label immediately
        starCountLabel.text = "⭐ 已收集: \(starCount)"
        
        print("✅ Doll collected! Star count: \(starCount), XP: +50 (Total: \(currentXP)), Level: \(newLevel)")
        
        // ✅ Fade out animation
        let fadeOut = SKAction.fadeOut(withDuration: 0.5)
        let scaleDown = SKAction.scale(to: 0.3, duration: 0.5)
        let remove = SKAction.run {
            doll.removeFromParent()
            if let index = self.dolls.firstIndex(of: doll) {
                self.dolls.remove(at: index)
            }
        }
        
        // ✅ Run fade and scale animations simultaneously, then remove
        let fadeAndScale = SKAction.group([fadeOut, scaleDown])
        doll.run(SKAction.sequence([fadeAndScale, remove]))
    }
    
    // ✅ Show level up message
    func showLevelUpMessage(level: Int) {
        // ✅ Remove any existing level up message
        enumerateChildNodes(withName: "levelUpMessage") { node, _ in
            node.removeFromParent()
        }
        
        let levelUpLabel = SKLabelNode(text: "🎉 升級到等級 \(level)！")
        levelUpLabel.fontSize = 36
        levelUpLabel.fontColor = .systemYellow
        levelUpLabel.fontName = "AvenirNext-Bold"
        levelUpLabel.horizontalAlignmentMode = .center
        levelUpLabel.position = CGPoint(x: size.width / 2, y: size.height / 2)
        levelUpLabel.zPosition = 100
        levelUpLabel.name = "levelUpMessage"
        levelUpLabel.alpha = 0
        levelUpLabel.setScale(0.5)
        addChild(levelUpLabel)
        
        // ✅ Animate: scale up and fade in, then fade out
        let scaleUp = SKAction.scale(to: 1.2, duration: 0.5)
        let fadeIn = SKAction.fadeIn(withDuration: 0.5)
        let wait = SKAction.wait(forDuration: 2.0)
        let fadeOut = SKAction.fadeOut(withDuration: 0.5)
        let remove = SKAction.removeFromParent()
        
        let animation = SKAction.sequence([
            SKAction.group([scaleUp, fadeIn]),
            wait,
            fadeOut,
            remove
        ])
        
        levelUpLabel.run(animation)
    }
    
    // **13.5. Remove Doll After Collection (legacy method, kept for compatibility)**
    func removeDoll(_ doll: SKSpriteNode) {
        removeDollWithFade(doll)
    }
    
    // **14. Transition Back to Game Scene**
    func transitionToGameScene() {
        let gameScene = GameScene(size: self.size)
        gameScene.scaleMode = .aspectFill
        let transition = SKTransition.fade(withDuration: 0.5)
        self.view?.presentScene(gameScene, transition: transition)
    }
}
