import SpriteKit

// MARK: - 🎰 CLAW MACHINE SCENE - Mini-Game for Collecting Dolls
class ClampingScene: SKScene {
    
    // MARK: - 🎰 CLAW MACHINE COMPONENTS
    let claw = SKSpriteNode(imageNamed: "clamp")        // Claw sprite
    let clawArm = SKSpriteNode(imageNamed: "claw_arm")  // Arm extending down
    let grabButton = SKLabelNode(text: "GRAB")          // Button for grabbing
    var grabButtonBackground: SKShapeNode!              // Button background
    
    // MARK: - 🎭 DOLL COLLECTION SYSTEM
    var dolls: [SKSpriteNode] = []      // Array of collectible dolls
    var selectedDoll: SKSpriteNode?     // The doll currently being clamped
    
    override func didMove(to view: SKView) {
        backgroundColor = .lightGray
        
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
        
        // **4. Setup Grab Button**
        grabButton.fontSize = 30
        grabButton.fontColor = .red
        grabButton.position = CGPoint(x: size.width - 500, y: 150)
        grabButton.name = "夾取"
        grabButton.zPosition = 5
        addChild(grabButton)
        
        // **5. Add Random Dolls (Perspective Adjusted)**
        for _ in 0..<2 {
            for i in 0..<4 {
                let doll = SKSpriteNode(imageNamed: "Clampingdoll\(i)")  // Replace with real doll images
                let xPos = CGFloat(arc4random_uniform(UInt32(size.width - 200))) + 100
                let yPos = CGFloat(arc4random_uniform(80)) + 180  // Slight variation for depth
                let scaleFactor = 1.0 - ((yPos - 100) / 200)  // Adjust scale for perspective
                
                doll.position = CGPoint(x: xPos, y: yPos)
                doll.size = CGSize(width: 60 * scaleFactor, height: 60 * scaleFactor)  // Scale dolls
                doll.zPosition = 1  // Behind claw
                doll.name = "doll"
                addChild(doll)
                dolls.append(doll)
            }
        }
    }

    // **6. Move Claw with Touch (Left/Right Perspective)**
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        if let touch = touches.first {
            let location = touch.location(in: self)

            if grabButton.contains(location) {
                dropClaw()
            } else {
                moveClaw(to: location.x)
            }
        }
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
        let dropArmAction = SKAction.scaleY(to: 1.2, duration: 0.5)  // Extend arm
        let dropClawAction = SKAction.moveTo(y: 100, duration: 0.5)
        let grabAction = SKAction.run { self.checkForDoll() }
        let liftClawAction = SKAction.moveTo(y: clawArm.position.y - 75, duration: 0.5)
        let liftArmAction = SKAction.scaleY(to: 1.0, duration: 0.5)  // Retract arm

        let sequence = SKAction.sequence([dropArmAction, dropClawAction, grabAction, liftClawAction, liftArmAction])
        clawArm.run(dropArmAction)
        claw.run(sequence)
    }

    // **9. Check for Doll Grab**
    func checkForDoll() {
        for doll in dolls {
            if abs(doll.position.x - claw.position.x) < 40 {
                selectedDoll = doll
                let grabEffect = SKAction.scale(to: 0.8, duration: 0.2)  // Slight scale effect
                doll.run(grabEffect)
                return
            }
        }
        selectedDoll = nil
    }


    // **10. Transition Doll to Collection (If Grabbed)**
    override func update(_ currentTime: TimeInterval) {
        if let doll = selectedDoll {
            let liftDollAction = SKAction.moveTo(y: claw.position.y - 30, duration: 0.2)
            doll.run(liftDollAction)
            GameStats.shared.crystalCoins -= 3
        }
    }
}
