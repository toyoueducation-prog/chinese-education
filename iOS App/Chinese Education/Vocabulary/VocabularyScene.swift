import SpriteKit

// MARK: - 📖 VOCABULARY SCENE - Vocabulary Review and Practice
class VocabularyScene: SKScene {
    private var backButton: SKLabelNode!
    private var vocabularyList: [VocabularyWord] = []
    private var currentIndex: Int = 0
    private var masteryFilter: Int? = nil  // nil = all, 0-5 = specific level
    private var scrollView: SKNode!
    private var scrollOffset: CGFloat = 0
    
    override func didMove(to view: SKView) {
        // ✅ Professional gradient background
        setupProfessionalBackground()
        
        loadVocabulary()
        setupUI()
        displayVocabulary()
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
    
    // MARK: - Load Vocabulary
    func loadVocabulary() {
        if let filter = masteryFilter {
            vocabularyList = VocabularyManager.shared.getVocabularyByMastery(filter)
        } else {
            vocabularyList = VocabularyManager.shared.getAllVocabulary()
        }
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
        let titleLabel = SKLabelNode(text: "我的詞彙")
        titleLabel.fontSize = 28
        titleLabel.fontColor = .black
        titleLabel.fontName = "AvenirNext-Bold"
        titleLabel.position = CGPoint(x: size.width / 2, y: size.height - 50)
        titleLabel.zPosition = 100
        addChild(titleLabel)
        
        // Filter buttons
        setupFilterButtons()
        
        // Statistics
        displayStatistics()
    }
    
    // MARK: - Setup Filter Buttons
    func setupFilterButtons() {
        let filterY = size.height - 100
        let buttonWidth: CGFloat = 80
        let spacing: CGFloat = 10
        let startX = (size.width - (buttonWidth * 6 + spacing * 5)) / 2
        
        // All button
        let allButton = createFilterButton(text: "全部", x: startX, y: filterY, level: nil)
        addChild(allButton)
        
        // Level buttons (0-5)
        for level in 0...5 {
            let x = startX + CGFloat(level + 1) * (buttonWidth + spacing)
            let button = createFilterButton(text: "\(level)", x: x, y: filterY, level: level)
            addChild(button)
        }
    }
    
    func createFilterButton(text: String, x: CGFloat, y: CGFloat, level: Int?) -> SKNode {
        let button = SKShapeNode(rectOf: CGSize(width: 80, height: 30), cornerRadius: 5)
        button.fillColor = masteryFilter == level ? .systemBlue : .systemGray5
        button.strokeColor = .systemGray
        button.position = CGPoint(x: x, y: y)
        button.name = "filter_\(level?.description ?? "all")"
        
        let label = SKLabelNode(text: text)
        label.fontSize = 16
        label.fontColor = masteryFilter == level ? .white : .label
        label.position = CGPoint(x: 0, y: -8)
        button.addChild(label)
        
        return button
    }
    
    // MARK: - Display Statistics
    func displayStatistics() {
        let stats = VocabularyManager.shared.getStatistics()
        let statsText = "總詞彙: \(stats.totalWords) | 已掌握: \(stats.masteredWords) | 掌握率: \(Int(stats.masteryRate * 100))%"
        
        let statsLabel = SKLabelNode(text: statsText)
        statsLabel.fontSize = 16
        statsLabel.fontColor = .label
        statsLabel.position = CGPoint(x: size.width / 2, y: size.height - 140)
        addChild(statsLabel)
    }
    
    // MARK: - Display Vocabulary
    func displayVocabulary() {
        // Remove existing vocabulary display
        enumerateChildNodes(withName: "vocabItem") { node, _ in
            node.removeFromParent()
        }
        enumerateChildNodes(withName: "emptyVocabMessage") { node, _ in
            node.removeFromParent()
        }
        
        // ✅ Show message if vocabulary list is empty
        if vocabularyList.isEmpty {
            let emptyMessage = SKLabelNode(text: "還沒有詞彙。請先閱讀文章來學習新詞彙！")
            emptyMessage.fontSize = 20
            emptyMessage.fontColor = .systemGray
            emptyMessage.position = CGPoint(x: size.width / 2, y: size.height / 2)
            emptyMessage.name = "emptyVocabMessage"
            addChild(emptyMessage)
            return
        }
        
        let startY = size.height - 180
        var currentY = startY
        
        for (index, word) in vocabularyList.enumerated() {
            if currentY < 100 { break }  // Stop if below screen
            
            let vocabNode = createVocabularyNode(word: word, index: index)
            vocabNode.position = CGPoint(x: size.width / 2, y: currentY)
            vocabNode.name = "vocabItem"
            addChild(vocabNode)
            
            currentY -= 80
        }
    }
    
    func createVocabularyNode(word: VocabularyWord, index: Int) -> SKNode {
        let container = SKNode()
        
        // Background
        let background = SKShapeNode(rectOf: CGSize(width: size.width - 40, height: 70), cornerRadius: 10)
        background.fillColor = getMasteryColor(word.masteryLevel)
        background.strokeColor = .systemGray
        background.alpha = 0.3
        container.addChild(background)
        
        // Word
        let wordLabel = SKLabelNode(text: word.word)
        wordLabel.fontSize = 24
        wordLabel.fontColor = .label
        wordLabel.horizontalAlignmentMode = .left
        wordLabel.position = CGPoint(x: -size.width / 2 + 30, y: 10)
        container.addChild(wordLabel)
        
        // Pinyin (if available)
        if !word.pinyin.isEmpty {
            let pinyinLabel = SKLabelNode(text: word.pinyin)
            pinyinLabel.fontSize = 16
            pinyinLabel.fontColor = .secondaryLabel
            pinyinLabel.horizontalAlignmentMode = .left
            pinyinLabel.position = CGPoint(x: -size.width / 2 + 30, y: -10)
            container.addChild(pinyinLabel)
        }
        
        // Mastery level
        let masteryLabel = SKLabelNode(text: word.masteryDescription)
        masteryLabel.fontSize = 16
        masteryLabel.fontColor = .label
        masteryLabel.horizontalAlignmentMode = .right
        masteryLabel.position = CGPoint(x: size.width / 2 - 30, y: 0)
        container.addChild(masteryLabel)
        
        // Encounters
        let encountersLabel = SKLabelNode(text: "遇到: \(word.encounters)次")
        encountersLabel.fontSize = 14
        encountersLabel.fontColor = .secondaryLabel
        encountersLabel.horizontalAlignmentMode = .right
        encountersLabel.position = CGPoint(x: size.width / 2 - 30, y: -20)
        container.addChild(encountersLabel)
        
        return container
    }
    
    func getMasteryColor(_ level: Int) -> UIColor {
        switch level {
        case 0: return .systemGray
        case 1, 2: return .systemRed
        case 3: return .systemYellow
        case 4: return .systemGreen
        case 5: return .systemBlue
        default: return .systemGray
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
        } else if let nodeName = touchedNode.name, nodeName.hasPrefix("filter_") {
            // Handle filter selection
            let filterStr = String(nodeName.dropFirst(7))
            if filterStr == "all" {
                masteryFilter = nil
            } else if let level = Int(filterStr) {
                masteryFilter = level
            }
            loadVocabulary()
            displayVocabulary()
            setupFilterButtons()  // Update button colors
        }
    }
}

