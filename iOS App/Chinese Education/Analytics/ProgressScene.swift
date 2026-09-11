import SpriteKit

// MARK: - 📊 PROGRESS SCENE - Visual Progress Dashboard
class ProgressScene: SKScene {
    private var backButton: SKLabelNode!
    private var dashboardData: ProgressDashboardData!
    
    override func didMove(to view: SKView) {
        // ✅ Professional gradient background
        setupProfessionalBackground()
        
        // Load dashboard data
        dashboardData = ProgressDashboard.generateDashboardData()
        
        setupUI()
        displayProgressData()
    }
    
    // MARK: - Setup Professional Background
    func setupProfessionalBackground() {
        // ✅ Create gradient background using multiple layers for professional look
        let gradientLayer = SKShapeNode(rectOf: size)
        gradientLayer.fillColor = UIColor(red: 0.96, green: 0.97, blue: 0.98, alpha: 1.0)  // Soft light blue-gray
        gradientLayer.strokeColor = .clear
        gradientLayer.position = CGPoint(x: size.width / 2, y: size.height / 2)
        gradientLayer.zPosition = -100
        addChild(gradientLayer)
        
        // ✅ Add subtle pattern overlay
        let patternOverlay = SKShapeNode(rectOf: size)
        patternOverlay.fillColor = UIColor.white.withAlphaComponent(0.3)
        patternOverlay.strokeColor = .clear
        patternOverlay.position = CGPoint(x: size.width / 2, y: size.height / 2)
        patternOverlay.zPosition = -99
        addChild(patternOverlay)
    }
    
    // MARK: - Setup UI
    func setupUI() {
        // ✅ Standardized back button with background
        let backButtonSize = CGSize(width: 100, height: 44)
        let backButtonBackground = SKShapeNode(rectOf: backButtonSize, cornerRadius: 8)
        backButtonBackground.fillColor = UIColor.white.withAlphaComponent(0.9)
        backButtonBackground.strokeColor = UIColor.systemGray4
        backButtonBackground.lineWidth = 1
        backButtonBackground.position = CGPoint(x: 60, y: size.height - 50)
        backButtonBackground.name = "backButton"
        backButtonBackground.zPosition = 100
        addChild(backButtonBackground)
        
        backButton = SKLabelNode(text: "← 返回")
        backButton.fontSize = 18
        backButton.fontColor = .systemBlue
        backButton.fontName = "AvenirNext-Medium"
        backButton.position = backButtonBackground.position
        backButton.name = "backButton"
        backButton.zPosition = 101
        addChild(backButton)
        
        // Title (centered, accounting for back button on left)
        let titleLabel = SKLabelNode(text: "學習進度")
        titleLabel.fontSize = 28
        titleLabel.fontColor = .black
        titleLabel.fontName = "AvenirNext-Bold"
        titleLabel.position = CGPoint(x: size.width / 2, y: size.height - 50)
        titleLabel.zPosition = 100
        addChild(titleLabel)
    }
    
    // MARK: - Display Progress Data
    func displayProgressData() {
        let startY = size.height - 150
        var currentY = startY
        
        // PIRLS Process Performance
        currentY = displayPIRLSProcesses(startY: currentY)
        currentY -= 100
        
        // Vocabulary Stats
        currentY = displayVocabularyStats(startY: currentY)
        currentY -= 100
        
        // Reading Purpose Balance
        currentY = displayReadingPurposeBalance(startY: currentY)
        currentY -= 100
        
        // Recommendations
        displayRecommendations(startY: currentY)
    }
    
    // MARK: - Display PIRLS Processes
    func displayPIRLSProcesses(startY: CGFloat) -> CGFloat {
        let titleLabel = SKLabelNode(text: "PIRLS 閱讀理解能力")
        titleLabel.fontSize = 24
        titleLabel.fontColor = .label
        titleLabel.position = CGPoint(x: size.width / 2, y: startY)
        addChild(titleLabel)
        
        var yOffset: CGFloat = 40
        for process in PIRLSProcess.allCases {
            if let score = dashboardData.pirlsProcessScores[process] {
                let processLabel = SKLabelNode(text: "\(process.displayName): \(Int(score * 100))%")
                processLabel.fontSize = 18
                processLabel.fontColor = .label
                processLabel.horizontalAlignmentMode = .left
                processLabel.position = CGPoint(x: 50, y: startY - yOffset)
                addChild(processLabel)
                
                // Progress bar
                let barWidth: CGFloat = size.width - 100
                let barHeight: CGFloat = 20
                let progressBar = SKShapeNode(rectOf: CGSize(width: barWidth, height: barHeight))
                progressBar.fillColor = .systemGray5
                progressBar.strokeColor = .systemGray
                progressBar.position = CGPoint(x: size.width / 2, y: startY - yOffset - 15)
                addChild(progressBar)
                
                // ✅ Progress bar fill (matching teacher dashboard style - immediate display, no animation)
                let filledBar = SKShapeNode(rectOf: CGSize(width: barWidth * CGFloat(score), height: barHeight))
                filledBar.fillColor = score >= 0.7 ? .systemGreen : (score >= 0.5 ? .systemYellow : .systemRed)
                filledBar.strokeColor = .clear
                filledBar.position = CGPoint(x: 50 + (barWidth * CGFloat(score)) / 2, y: startY - yOffset - 15)
                filledBar.name = "progressBar_\(process.rawValue)"
                addChild(filledBar)
                
                // Next milestone indicator (Phase 2.2)
                let nextMilestone = min(1.0, score + 0.1)  // Next 10% increment
                if nextMilestone > score {
                    let milestoneX = 50 + (barWidth * CGFloat(nextMilestone))
                    let milestoneIndicator = SKShapeNode(rectOf: CGSize(width: 2, height: barHeight + 5))
                    milestoneIndicator.fillColor = .systemBlue
                    milestoneIndicator.strokeColor = .clear
                    milestoneIndicator.alpha = 0.6
                    milestoneIndicator.position = CGPoint(x: milestoneX, y: startY - yOffset - 15)
                    milestoneIndicator.name = "milestone_\(process.rawValue)"
                    addChild(milestoneIndicator)
                    
                    // Milestone label
                    let milestoneLabel = SKLabelNode(text: "\(Int(nextMilestone * 100))%")
                    milestoneLabel.fontSize = 12
                    milestoneLabel.fontColor = .systemBlue
                    milestoneLabel.position = CGPoint(x: milestoneX, y: startY - yOffset - 30)
                    addChild(milestoneLabel)
                }
                
                yOffset += 50
            }
        }
        
        return startY - yOffset
    }
    
    // MARK: - Display Vocabulary Stats
    func displayVocabularyStats(startY: CGFloat) -> CGFloat {
        let titleLabel = SKLabelNode(text: "詞彙掌握")
        titleLabel.fontSize = 24
        titleLabel.fontColor = .label
        titleLabel.position = CGPoint(x: size.width / 2, y: startY)
        addChild(titleLabel)
        
        let stats = dashboardData.vocabularyStats
        
        // Vocabulary growth visualization (Phase 2.2)
        let vocabBarWidth: CGFloat = size.width - 100
        let vocabBarHeight: CGFloat = 25
        
        // Overall mastery bar
        let masteryBarBackground = SKShapeNode(rectOf: CGSize(width: vocabBarWidth, height: vocabBarHeight))
        masteryBarBackground.fillColor = .systemGray5
        masteryBarBackground.strokeColor = .systemGray
        masteryBarBackground.position = CGPoint(x: size.width / 2, y: startY - 40)
        addChild(masteryBarBackground)
        
        // ✅ Vocabulary mastery bar (matching teacher dashboard style - immediate display, no animation)
        let targetMasteryWidth = vocabBarWidth * CGFloat(stats.masteryRate)
        let masteryBar = SKShapeNode(rectOf: CGSize(width: targetMasteryWidth, height: vocabBarHeight))
        masteryBar.fillColor = .systemBlue
        masteryBar.strokeColor = .clear
        masteryBar.position = CGPoint(x: 50 + targetMasteryWidth / 2, y: startY - 40)
        masteryBar.name = "vocabMasteryBar"
        addChild(masteryBar)
        
        // Mastery percentage label
        let masteryLabel = SKLabelNode(text: "掌握率: \(Int(stats.masteryRate * 100))%")
        masteryLabel.fontSize = 16
        masteryLabel.fontColor = .label
        masteryLabel.position = CGPoint(x: size.width / 2, y: startY - 70)
        addChild(masteryLabel)
        
        // Detailed stats
        let statsText = """
        總詞彙: \(stats.totalWords)
        已掌握: \(stats.masteredWords) | 熟練: \(stats.proficientWords)
        學習中: \(stats.learningWords) | 新詞: \(stats.newWords)
        """
        
        let statsLabel = SKLabelNode(text: statsText)
        statsLabel.fontSize = 16
        statsLabel.fontColor = .label
        statsLabel.numberOfLines = 0
        statsLabel.verticalAlignmentMode = .top
        statsLabel.horizontalAlignmentMode = .left
        statsLabel.position = CGPoint(x: 50, y: startY - 100)
        addChild(statsLabel)
        
        return startY - 180
    }
    
    // MARK: - Display Reading Purpose Balance
    func displayReadingPurposeBalance(startY: CGFloat) -> CGFloat {
        let titleLabel = SKLabelNode(text: "閱讀類型表現")
        titleLabel.fontSize = 24
        titleLabel.fontColor = .label
        titleLabel.position = CGPoint(x: size.width / 2, y: startY)
        addChild(titleLabel)
        
        let literaryLabel = SKLabelNode(text: "文學類: \(Int(dashboardData.readingPurposeBalance.literary * 100))%")
        literaryLabel.fontSize = 18
        literaryLabel.fontColor = .label
        literaryLabel.horizontalAlignmentMode = .left
        literaryLabel.position = CGPoint(x: 50, y: startY - 30)
        addChild(literaryLabel)
        
        let informationalLabel = SKLabelNode(text: "資訊類: \(Int(dashboardData.readingPurposeBalance.informational * 100))%")
        informationalLabel.fontSize = 18
        informationalLabel.fontColor = .label
        informationalLabel.horizontalAlignmentMode = .left
        informationalLabel.position = CGPoint(x: 50, y: startY - 60)
        addChild(informationalLabel)
        
        return startY - 100
    }
    
    // MARK: - Display Recommendations
    func displayRecommendations(startY: CGFloat) {
        let titleLabel = SKLabelNode(text: "學習建議")
        titleLabel.fontSize = 24
        titleLabel.fontColor = .label
        titleLabel.position = CGPoint(x: size.width / 2, y: startY)
        addChild(titleLabel)
        
        var yOffset: CGFloat = 40
        for recommendation in dashboardData.recommendations.prefix(3) {  // Show top 3
            let recLabel = SKLabelNode(text: "• \(recommendation.title)")
            recLabel.fontSize = 16
            recLabel.fontColor = .label
            recLabel.horizontalAlignmentMode = .left
            recLabel.numberOfLines = 0
            recLabel.preferredMaxLayoutWidth = size.width - 100
            recLabel.position = CGPoint(x: 50, y: startY - yOffset)
            addChild(recLabel)
            yOffset += 40
        }
        
        // Motivational message based on progress (Phase 2.2)
        let profile = StudentProfile.shared
        let overallScore = profile.pirlsAssessment.overallScore
        let motivationalMessage = getMotivationalMessage(score: overallScore)
        
        let messageLabel = SKLabelNode(text: motivationalMessage)
        messageLabel.fontSize = 18
        messageLabel.fontColor = overallScore >= 0.7 ? .systemGreen : (overallScore >= 0.5 ? .systemYellow : .systemOrange)
        messageLabel.fontName = "AvenirNext-Bold"
        messageLabel.horizontalAlignmentMode = .center
        messageLabel.numberOfLines = 0
        messageLabel.preferredMaxLayoutWidth = size.width - 100
        messageLabel.position = CGPoint(x: size.width / 2, y: startY - yOffset - 20)
        addChild(messageLabel)
    }
    
    // MARK: - Get Motivational Message (Phase 2.2)
    func getMotivationalMessage(score: Double) -> String {
        if score >= 0.9 {
            return "🌟 表現優秀！繼續保持！"
        } else if score >= 0.7 {
            return "👍 表現良好！繼續努力！"
        } else if score >= 0.5 {
            return "💪 持續進步中！加油！"
        } else {
            return "📚 多練習會更好！不要放棄！"
        }
    }
    
    // MARK: - Handle Touches
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard let touch = touches.first else { return }
        let location = touch.location(in: self)
        let touchedNode = atPoint(location)
        
        if touchedNode.name == "backButton" {
            // Return to game scene
            let gameScene = GameScene(size: self.size)
            gameScene.scaleMode = .aspectFill
            let transition = SKTransition.fade(withDuration: 0.5)
            self.view?.presentScene(gameScene, transition: transition)
        }
    }
}

