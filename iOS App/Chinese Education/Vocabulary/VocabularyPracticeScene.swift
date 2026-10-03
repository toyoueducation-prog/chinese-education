import SpriteKit
import AVFoundation

/**
 * VOCABULARY PRACTICE SCENE - Honest flashcard self-check
 *
 * One real offline mode only:
 * - Shows practice-ready words (non-empty meaning)
 * - Flip reveals pinyin + gloss
 * - Learner marks 認識了 / 還不會 — mastery updates accordingly
 * - Matching / fill-blank stubs removed (no 開發中 dead ends)
 */
// MARK: - 📚 VOCABULARY PRACTICE SCENE
class VocabularyPracticeScene: SKScene {
    private var backButton: SKLabelNode!
    private var currentWord: VocabularyWord?
    private var currentIndex: Int = 0
    private var vocabularyList: [VocabularyWord] = []
    private var wordLabel: SKLabelNode!
    private var pinyinLabel: SKLabelNode!
    private var meaningLabel: SKLabelNode!
    private var flipButton: SKLabelNode!
    private var knewButton: SKLabelNode!
    private var missedButton: SKLabelNode!
    private var isFlipped: Bool = false
    private var synthesizer = AVSpeechSynthesizer()
    private var sessionCorrect: Int = 0
    private var sessionTotal: Int = 0

    override func didMove(to view: SKView) {
        setupProfessionalBackground()
        loadVocabulary()
        setupUI()
        setupFlashcardMode()
    }

    // MARK: - Setup Professional Background
    func setupProfessionalBackground() {
        let gradientLayer = SKShapeNode(rectOf: size)
        gradientLayer.fillColor = UIColor(red: 0.96, green: 0.97, blue: 0.98, alpha: 1.0)
        gradientLayer.strokeColor = .clear
        gradientLayer.position = CGPoint(x: size.width / 2, y: size.height / 2)
        gradientLayer.zPosition = -100
        addChild(gradientLayer)

        let patternOverlay = SKShapeNode(rectOf: size)
        patternOverlay.fillColor = UIColor.white.withAlphaComponent(0.3)
        patternOverlay.strokeColor = .clear
        patternOverlay.position = CGPoint(x: size.width / 2, y: size.height / 2)
        patternOverlay.zPosition = -99
        addChild(patternOverlay)
    }

    // MARK: - Load Vocabulary
    func loadVocabulary() {
        vocabularyList = VocabularyManager.shared.getPracticeVocabulary(limit: 20)
        currentIndex = 0
        sessionCorrect = 0
        sessionTotal = 0
    }

    // MARK: - Setup UI
    func setupUI() {
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

        let titleLabel = SKLabelNode(text: "詞彙練習")
        titleLabel.fontSize = 32
        titleLabel.fontColor = .label
        titleLabel.fontName = "AvenirNext-Bold"
        titleLabel.position = CGPoint(x: size.width / 2, y: size.height - 50)
        addChild(titleLabel)

        let subtitle = SKLabelNode(text: "翻轉後誠實回報：認識了或還不會")
        subtitle.fontSize = 16
        subtitle.fontColor = .secondaryLabel
        subtitle.fontName = "AvenirNext-Regular"
        subtitle.position = CGPoint(x: size.width / 2, y: size.height - 90)
        addChild(subtitle)
    }

    // MARK: - Clear Practice Elements
    private func clearPracticeElements() {
        enumerateChildNodes(withName: "practiceElement") { node, _ in
            node.removeFromParent()
        }
        childNode(withName: "flipButton")?.removeFromParent()
        childNode(withName: "pronounceButton")?.removeFromParent()
        childNode(withName: "knewButton")?.removeFromParent()
        childNode(withName: "missedButton")?.removeFromParent()
        childNode(withName: "knewButtonBg")?.removeFromParent()
        childNode(withName: "missedButtonBg")?.removeFromParent()
    }

    // MARK: - Flashcard Mode
    func setupFlashcardMode() {
        clearPracticeElements()

        guard !vocabularyList.isEmpty else {
            showEmptyPracticeMessage()
            return
        }

        guard currentIndex < vocabularyList.count else {
            showCompleteMessage()
            return
        }

        currentWord = vocabularyList[currentIndex]
        isFlipped = false

        let cardBg = SKShapeNode(rectOf: CGSize(width: size.width - 100, height: 300), cornerRadius: 20)
        cardBg.fillColor = .systemGray6
        cardBg.strokeColor = .systemGray
        cardBg.lineWidth = 3
        cardBg.position = CGPoint(x: size.width / 2, y: size.height / 2 + 20)
        cardBg.name = "practiceElement"
        addChild(cardBg)

        wordLabel = SKLabelNode(text: currentWord?.word ?? "")
        wordLabel.fontSize = 48
        wordLabel.fontColor = .label
        wordLabel.fontName = "AvenirNext-Bold"
        wordLabel.position = CGPoint(x: size.width / 2, y: size.height / 2 + 60)
        wordLabel.name = "practiceElement"
        addChild(wordLabel)

        let pinyinText = currentWord?.pinyin.isEmpty == false ? currentWord!.pinyin : "（暫無注音）"
        pinyinLabel = SKLabelNode(text: pinyinText)
        pinyinLabel.fontSize = 24
        pinyinLabel.fontColor = .secondaryLabel
        pinyinLabel.fontName = "AvenirNext-Regular"
        pinyinLabel.position = CGPoint(x: size.width / 2, y: size.height / 2 + 10)
        pinyinLabel.alpha = 0
        pinyinLabel.name = "practiceElement"
        addChild(pinyinLabel)

        let meaningText = currentWord?.meaning ?? ""
        meaningLabel = SKLabelNode(text: meaningText)
        meaningLabel.fontSize = 20
        meaningLabel.fontColor = .label
        meaningLabel.fontName = "AvenirNext-Medium"
        meaningLabel.numberOfLines = 0
        meaningLabel.preferredMaxLayoutWidth = size.width - 150
        meaningLabel.position = CGPoint(x: size.width / 2, y: size.height / 2 - 50)
        meaningLabel.alpha = 0
        meaningLabel.name = "practiceElement"
        addChild(meaningLabel)

        flipButton = SKLabelNode(text: "翻轉")
        flipButton.fontSize = 20
        flipButton.fontColor = .systemBlue
        flipButton.fontName = "AvenirNext-Medium"
        flipButton.position = CGPoint(x: size.width / 2 + 70, y: size.height / 2 - 160)
        flipButton.name = "flipButton"
        addChild(flipButton)

        let pronounceButton = SKLabelNode(text: "發音")
        pronounceButton.fontSize = 20
        pronounceButton.fontColor = .systemGreen
        pronounceButton.fontName = "AvenirNext-Medium"
        pronounceButton.position = CGPoint(x: size.width / 2 - 70, y: size.height / 2 - 160)
        pronounceButton.name = "pronounceButton"
        addChild(pronounceButton)

        // Self-check buttons (hidden until flipped)
        let knewBg = SKShapeNode(rectOf: CGSize(width: 130, height: 44), cornerRadius: 10)
        knewBg.fillColor = UIColor.systemGreen.withAlphaComponent(0.85)
        knewBg.strokeColor = .clear
        knewBg.position = CGPoint(x: size.width / 2 - 80, y: size.height / 2 - 220)
        knewBg.name = "knewButtonBg"
        knewBg.alpha = 0
        addChild(knewBg)

        knewButton = SKLabelNode(text: "認識了")
        knewButton.fontSize = 18
        knewButton.fontColor = .white
        knewButton.fontName = "AvenirNext-DemiBold"
        knewButton.position = knewBg.position
        knewButton.verticalAlignmentMode = .center
        knewButton.name = "knewButton"
        knewButton.alpha = 0
        addChild(knewButton)

        let missedBg = SKShapeNode(rectOf: CGSize(width: 130, height: 44), cornerRadius: 10)
        missedBg.fillColor = UIColor.systemOrange.withAlphaComponent(0.9)
        missedBg.strokeColor = .clear
        missedBg.position = CGPoint(x: size.width / 2 + 80, y: size.height / 2 - 220)
        missedBg.name = "missedButtonBg"
        missedBg.alpha = 0
        addChild(missedBg)

        missedButton = SKLabelNode(text: "還不會")
        missedButton.fontSize = 18
        missedButton.fontColor = .white
        missedButton.fontName = "AvenirNext-DemiBold"
        missedButton.position = missedBg.position
        missedButton.verticalAlignmentMode = .center
        missedButton.name = "missedButton"
        missedButton.alpha = 0
        addChild(missedButton)

        let progressLabel = SKLabelNode(text: "\(currentIndex + 1) / \(vocabularyList.count)")
        progressLabel.fontSize = 16
        progressLabel.fontColor = .secondaryLabel
        progressLabel.position = CGPoint(x: size.width / 2, y: 80)
        progressLabel.name = "practiceElement"
        addChild(progressLabel)
    }

    // MARK: - Flip Flashcard
    func flipFlashcard() {
        guard !isFlipped else { return }
        isFlipped = true

        let fadeOut = SKAction.fadeOut(withDuration: 0.25)
        let fadeIn = SKAction.fadeIn(withDuration: 0.25)

        wordLabel.run(fadeOut)
        pinyinLabel.run(fadeIn)
        meaningLabel.run(fadeIn)
        flipButton.run(fadeOut)
        knewButton.run(fadeIn)
        missedButton.run(fadeIn)
        childNode(withName: "knewButtonBg")?.run(fadeIn)
        childNode(withName: "missedButtonBg")?.run(fadeIn)
    }

    // MARK: - Pronounce Word
    func pronounceWord() {
        guard let word = currentWord else { return }
        let utterance = AVSpeechUtterance(string: word.word)
        utterance.voice = AVSpeechSynthesisVoice(language: "zh-TW") ?? AVSpeechSynthesisVoice(language: "zh-CN")
        utterance.rate = 0.5
        synthesizer.speak(utterance)
    }

    // MARK: - Grade Self-Check
    func gradeCurrentWord(knewIt: Bool) {
        guard let word = currentWord else { return }
        VocabularyManager.shared.trackWordEncounter(word.word, isCorrect: knewIt)
        sessionTotal += 1
        if knewIt { sessionCorrect += 1 }

        currentIndex += 1
        if currentIndex < vocabularyList.count {
            setupFlashcardMode()
        } else {
            showCompleteMessage()
        }
    }

    // MARK: - Empty / Complete
    func showEmptyPracticeMessage() {
        clearPracticeElements()
        let message = SKLabelNode(text: "目前沒有可練習的詞彙")
        message.fontSize = 22
        message.fontColor = .systemGray
        message.fontName = "AvenirNext-Medium"
        message.position = CGPoint(x: size.width / 2, y: size.height / 2 + 20)
        message.name = "practiceElement"
        addChild(message)

        let hint = SKLabelNode(text: "請先閱讀文章，或稍後再試")
        hint.fontSize = 16
        hint.fontColor = .secondaryLabel
        hint.position = CGPoint(x: size.width / 2, y: size.height / 2 - 20)
        hint.name = "practiceElement"
        addChild(hint)
    }

    func showCompleteMessage() {
        clearPracticeElements()

        let completeLabel = SKLabelNode(text: "練習完成！")
        completeLabel.fontSize = 28
        completeLabel.fontColor = .systemGreen
        completeLabel.fontName = "AvenirNext-Bold"
        completeLabel.position = CGPoint(x: size.width / 2, y: size.height / 2 + 30)
        completeLabel.name = "practiceElement"
        addChild(completeLabel)

        let summary = SKLabelNode(text: "本次認識 \(sessionCorrect) / \(sessionTotal)")
        summary.fontSize = 18
        summary.fontColor = .label
        summary.fontName = "AvenirNext-Medium"
        summary.position = CGPoint(x: size.width / 2, y: size.height / 2 - 20)
        summary.name = "practiceElement"
        addChild(summary)
    }

    // MARK: - Handle Touches
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard let touch = touches.first else { return }
        let location = touch.location(in: self)
        let touchedNode = atPoint(location)
        let name = touchedNode.name ?? touchedNode.parent?.name

        switch name {
        case "backButton":
            let vocabularyScene = VocabularyScene(size: self.size)
            vocabularyScene.scaleMode = .aspectFill
            view?.presentScene(vocabularyScene, transition: SKTransition.fade(withDuration: 0.5))
        case "flipButton":
            flipFlashcard()
        case "pronounceButton":
            pronounceWord()
        case "knewButton", "knewButtonBg":
            guard isFlipped else { return }
            gradeCurrentWord(knewIt: true)
        case "missedButton", "missedButtonBg":
            guard isFlipped else { return }
            gradeCurrentWord(knewIt: false)
        default:
            break
        }
    }
}
