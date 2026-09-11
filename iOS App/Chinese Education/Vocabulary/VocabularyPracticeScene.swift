import SpriteKit
import AVFoundation

/**
 * VOCABULARY PRACTICE SCENE - Interactive Vocabulary Learning
 * 
 * Features:
 * - Flashcard mode with spaced repetition
 * - Vocabulary games (matching, fill-in-the-blank)
 * - Context-based learning from passages
 * - Pronunciation practice
 * - Progress tracking with mastery visualization
 */
// MARK: - 📚 VOCABULARY PRACTICE SCENE
class VocabularyPracticeScene: SKScene {
    private var backButton: SKLabelNode!
    private var currentWord: VocabularyWord?
    private var currentIndex: Int = 0
    private var vocabularyList: [VocabularyWord] = []
    private var practiceMode: PracticeMode = .flashcard
    private var wordLabel: SKLabelNode!
    private var pinyinLabel: SKLabelNode!
    private var meaningLabel: SKLabelNode!
    private var flipButton: SKLabelNode!
    private var nextButton: SKLabelNode!
    private var isFlipped: Bool = false
    private var synthesizer = AVSpeechSynthesizer()
    
    enum PracticeMode {
        case flashcard
        case matching
        case fillInBlank
    }
    
    override func didMove(to view: SKView) {
        // ✅ Professional gradient background
        setupProfessionalBackground()
        
        loadVocabulary()
        setupUI()
        setupPracticeMode()
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
        let allVocab = VocabularyManager.shared.getAllVocabulary()
        func accuracy(_ w: VocabularyWord) -> Double {
            guard w.encounters > 0 else { return 0 }
            return Double(w.correctUses) / Double(w.encounters)
        }
        // Prioritize lowest mastery, then lowest accuracy (needs review most)
        let needsReview = allVocab.filter { $0.masteryLevel < 4 }
            .sorted { a, b in
                if a.masteryLevel != b.masteryLevel { return a.masteryLevel < b.masteryLevel }
                if accuracy(a) != accuracy(b) { return accuracy(a) < accuracy(b) }
                return a.encounters > b.encounters
            }
        vocabularyList = needsReview
        if vocabularyList.isEmpty {
            vocabularyList = allVocab.sorted { a, b in
                if a.masteryLevel != b.masteryLevel { return a.masteryLevel < b.masteryLevel }
                return accuracy(a) < accuracy(b)
            }
        }
        if vocabularyList.isEmpty {
            vocabularyList = Array(allVocab.prefix(20))
        }
        currentIndex = 0
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
        
        // Title
        let titleLabel = SKLabelNode(text: "詞彙練習")
        titleLabel.fontSize = 32
        titleLabel.fontColor = .label
        titleLabel.position = CGPoint(x: size.width / 2, y: size.height - 50)
        addChild(titleLabel)
        
        // Mode selector
        setupModeSelector()
    }
    
    // MARK: - Setup Mode Selector
    func setupModeSelector() {
        let modes: [(name: String, mode: PracticeMode)] = [
            ("卡片", .flashcard),
            ("配對", .matching),
            ("填空", .fillInBlank)
        ]
        
        let startX = size.width / 2 - CGFloat(modes.count - 1) * 60
        for (index, modeInfo) in modes.enumerated() {
            let button = createModeButton(text: modeInfo.name, mode: modeInfo.mode)
            button.position = CGPoint(x: startX + CGFloat(index) * 120, y: size.height - 100)
            button.name = "modeButton_\(modeInfo.mode)"
            addChild(button)
        }
    }
    
    // MARK: - Create Mode Button
    func createModeButton(text: String, mode: PracticeMode) -> SKNode {
        let container = SKNode()
        
        let buttonBg = SKShapeNode(rectOf: CGSize(width: 100, height: 40), cornerRadius: 10)
        buttonBg.fillColor = practiceMode == mode ? .systemBlue : .systemGray5
        buttonBg.strokeColor = .systemGray
        container.addChild(buttonBg)
        
        let label = SKLabelNode(text: text)
        label.fontSize = 18
        label.fontColor = practiceMode == mode ? .white : .label
        label.position = CGPoint(x: 0, y: -10)
        container.addChild(label)
        
        return container
    }
    
    // MARK: - Setup Practice Mode
    func setupPracticeMode() {
        // Clear previous mode
        enumerateChildNodes(withName: "practiceElement") { node, _ in
            node.removeFromParent()
        }
        
        switch practiceMode {
        case .flashcard:
            setupFlashcardMode()
        case .matching:
            setupMatchingMode()
        case .fillInBlank:
            setupFillInBlankMode()
        }
    }
    
    // MARK: - Flashcard Mode
    func setupFlashcardMode() {
        guard currentIndex < vocabularyList.count else {
            showCompleteMessage()
            return
        }
        
        currentWord = vocabularyList[currentIndex]
        isFlipped = false
        
        // Flashcard background
        let cardBg = SKShapeNode(rectOf: CGSize(width: size.width - 100, height: 300), cornerRadius: 20)
        cardBg.fillColor = .systemGray6
        cardBg.strokeColor = .systemGray
        cardBg.lineWidth = 3
        cardBg.position = CGPoint(x: size.width / 2, y: size.height / 2)
        cardBg.name = "practiceElement"
        addChild(cardBg)
        
        // Word (front side)
        wordLabel = SKLabelNode(text: currentWord?.word ?? "")
        wordLabel.fontSize = 48
        wordLabel.fontColor = .label
        wordLabel.position = CGPoint(x: size.width / 2, y: size.height / 2 + 50)
        wordLabel.name = "practiceElement"
        addChild(wordLabel)
        
        // Pinyin (hidden initially)
        pinyinLabel = SKLabelNode(text: currentWord?.pinyin ?? "")
        pinyinLabel.fontSize = 24
        pinyinLabel.fontColor = .secondaryLabel
        pinyinLabel.position = CGPoint(x: size.width / 2, y: size.height / 2)
        pinyinLabel.alpha = 0
        pinyinLabel.name = "practiceElement"
        addChild(pinyinLabel)
        
        // Meaning (hidden initially)
        meaningLabel = SKLabelNode(text: currentWord?.meaning.isEmpty == false ? currentWord!.meaning : "點擊翻轉查看")
        meaningLabel.fontSize = 20
        meaningLabel.fontColor = .label
        meaningLabel.numberOfLines = 0
        meaningLabel.preferredMaxLayoutWidth = size.width - 150
        meaningLabel.position = CGPoint(x: size.width / 2, y: size.height / 2 - 80)
        meaningLabel.alpha = 0
        meaningLabel.name = "practiceElement"
        addChild(meaningLabel)
        
        // Flip button
        flipButton = SKLabelNode(text: "翻轉")
        flipButton.fontSize = 20
        flipButton.fontColor = .systemBlue
        flipButton.position = CGPoint(x: size.width / 2, y: size.height / 2 - 150)
        flipButton.name = "flipButton"
        addChild(flipButton)
        
        // Pronunciation button
        let pronounceButton = SKLabelNode(text: "🔊 發音")
        pronounceButton.fontSize = 20
        pronounceButton.fontColor = .systemGreen
        pronounceButton.position = CGPoint(x: size.width / 2 - 80, y: size.height / 2 - 150)
        pronounceButton.name = "pronounceButton"
        addChild(pronounceButton)
        
        // Next button
        nextButton = SKLabelNode(text: "下一個")
        nextButton.fontSize = 20
        nextButton.fontColor = .systemBlue
        nextButton.position = CGPoint(x: size.width / 2 + 80, y: size.height / 2 - 150)
        nextButton.name = "nextButton"
        nextButton.alpha = 0  // Hidden until flipped
        addChild(nextButton)
        
        // Progress indicator
        let progressLabel = SKLabelNode(text: "\(currentIndex + 1) / \(vocabularyList.count)")
        progressLabel.fontSize = 16
        progressLabel.fontColor = .secondaryLabel
        progressLabel.position = CGPoint(x: size.width / 2, y: 100)
        progressLabel.name = "practiceElement"
        addChild(progressLabel)
    }
    
    // MARK: - Flip Flashcard
    func flipFlashcard() {
        isFlipped.toggle()
        
        let fadeOut = SKAction.fadeOut(withDuration: 0.3)
        let fadeIn = SKAction.fadeIn(withDuration: 0.3)
        
        if isFlipped {
            // Show pinyin and meaning
            wordLabel.run(fadeOut)
            pinyinLabel.run(fadeIn)
            meaningLabel.run(fadeIn)
            flipButton.text = "返回"
            nextButton.run(fadeIn)
        } else {
            // Show word only
            wordLabel.run(fadeIn)
            pinyinLabel.run(fadeOut)
            meaningLabel.run(fadeOut)
            flipButton.text = "翻轉"
            nextButton.run(fadeOut)
        }
    }
    
    // MARK: - Pronounce Word
    func pronounceWord() {
        guard let word = currentWord else { return }
        
        let utterance = AVSpeechUtterance(string: word.word)
        utterance.voice = AVSpeechSynthesisVoice(language: "zh-TW") ?? AVSpeechSynthesisVoice(language: "zh-CN")
        utterance.rate = 0.5
        synthesizer.speak(utterance)
    }
    
    // MARK: - Next Word
    func nextWord() {
        if isFlipped {
            // Track mastery based on user interaction
            if let word = currentWord {
                VocabularyManager.shared.trackWordEncounter(word.word, isCorrect: true)
            }
        }
        
        currentIndex += 1
        if currentIndex < vocabularyList.count {
            setupFlashcardMode()
        } else {
            showCompleteMessage()
        }
    }
    
    // MARK: - Matching Mode (Placeholder)
    func setupMatchingMode() {
        let messageLabel = SKLabelNode(text: "配對模式開發中")
        messageLabel.fontSize = 24
        messageLabel.fontColor = .systemGray
        messageLabel.position = CGPoint(x: size.width / 2, y: size.height / 2)
        messageLabel.name = "practiceElement"
        addChild(messageLabel)
    }
    
    // MARK: - Fill in Blank Mode (Placeholder)
    func setupFillInBlankMode() {
        let messageLabel = SKLabelNode(text: "填空模式開發中")
        messageLabel.fontSize = 24
        messageLabel.fontColor = .systemGray
        messageLabel.position = CGPoint(x: size.width / 2, y: size.height / 2)
        messageLabel.name = "practiceElement"
        addChild(messageLabel)
    }
    
    // MARK: - Show Complete Message
    func showCompleteMessage() {
        enumerateChildNodes(withName: "practiceElement") { node, _ in
            node.removeFromParent()
        }
        
        let completeLabel = SKLabelNode(text: "練習完成！")
        completeLabel.fontSize = 28
        completeLabel.fontColor = .systemGreen
        completeLabel.position = CGPoint(x: size.width / 2, y: size.height / 2)
        addChild(completeLabel)
    }
    
    // MARK: - Handle Touches
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard let touch = touches.first else { return }
        let location = touch.location(in: self)
        let touchedNode = atPoint(location)
        
        if touchedNode.name == "backButton" {
            let gameScene = GameScene(size: self.size)
            gameScene.scaleMode = .aspectFill
            let transition = SKTransition.fade(withDuration: 0.5)
            self.view?.presentScene(gameScene, transition: transition)
        } else if touchedNode.name == "flipButton" {
            flipFlashcard()
        } else if touchedNode.name == "pronounceButton" {
            pronounceWord()
        } else if touchedNode.name == "nextButton" {
            nextWord()
        } else if let nodeName = touchedNode.name, nodeName.hasPrefix("modeButton_") {
            let modeStr = String(nodeName.dropFirst(11))
            switch modeStr {
            case "flashcard":
                practiceMode = .flashcard
            case "matching":
                practiceMode = .matching
            case "fillInBlank":
                practiceMode = .fillInBlank
            default:
                break
            }
            setupModeSelector()
            setupPracticeMode()
        }
    }
}

