import SpriteKit
import AVFoundation

class HintScene: SKScene, AVSpeechSynthesizerDelegate {
    var incorrectQuestions: Set<String> = []  // ✅ Stores incorrect question keys
    private var continueButtonBackground: SKShapeNode!
    private var continueButton: SKLabelNode!
    private var synthesizer = AVSpeechSynthesizer()  // ✅ Speech synthesizer
    private var playPauseButton: SKLabelNode?  // ✅ Play/pause button
    private var isPronunciationPlaying = false  // ✅ Track pronunciation state
    private var currentQuestionIndex = 0  // ✅ Track which question is being read
    private var questionObjects: [Question] = []  // ✅ Store full question objects
    
    override func didMove(to view: SKView) {
        // ✅ Professional gradient background (matching other views)
        setupProfessionalBackground()
        synthesizer.delegate = self

        // ✅ Load full question objects (not just keys)
        questionObjects = incorrectQuestions.compactMap { key in
            QuestionBank.shared.getQuestion(forKey: key)
        }

        // ✅ Setup UI - no passage, just questions
        setupQuestionContainer()
        setupPlayPauseButton()
        setupContinueButton()
        
        // ✅ Auto-play pronunciation of first question
        if !questionObjects.isEmpty {
            readCurrentQuestion()
        }
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
    
    // MARK: - Setup Question Container
    func setupQuestionContainer() {
        let safeAreaTop: CGFloat = 50
        let questionStartY = size.height - safeAreaTop - 50
        
        // ✅ Display all incorrect questions with answers and explanations
        if questionObjects.isEmpty {
            let noQuestionsLabel = SKLabelNode(text: "沒有錯誤答案！")
            noQuestionsLabel.fontSize = 24
            noQuestionsLabel.fontColor = .systemGreen
            noQuestionsLabel.position = CGPoint(x: size.width / 2, y: size.height / 2)
            addChild(noQuestionsLabel)
            return
        }
        
        // ✅ Title
        let titleLabel = SKLabelNode(text: "錯誤問題詳解")
        titleLabel.fontSize = 28
        titleLabel.fontColor = .systemRed
        titleLabel.fontName = "AvenirNext-Bold"
        titleLabel.position = CGPoint(x: size.width / 2, y: questionStartY)
        addChild(titleLabel)
        
        // ✅ Display each question with answer and explanation
        var currentY = questionStartY - 60
        let containerWidth = size.width - 40
        let spacing: CGFloat = 20
        
        for (index, question) in questionObjects.enumerated() {
            if currentY < 200 { break }  // Stop if below screen
            
            // ✅ Calculate content height first with better spacing
            var contentHeight: CGFloat = 60  // Base height for question (increased)
            if let choices = question.choices {
                contentHeight += CGFloat(choices.count * 45)  // More space for choices (increased from 35)
            }
            contentHeight += 40  // Space for answer (increased from 30)
            if let explanations = question.explantation, !explanations.isEmpty {
                // Calculate explanation height based on text length
                let explanationText = explanations.joined(separator: " ")
                let estimatedLines = max(1, Int(explanationText.count / 30))  // Rough estimate: 30 chars per line
                contentHeight += CGFloat(estimatedLines * 25) + 20  // Space for explanation with line breaks
            }
            
            // ✅ Create container with calculated height (better spacing)
            let questionContainer = SKShapeNode(rectOf: CGSize(width: containerWidth, height: contentHeight), cornerRadius: 10)
            questionContainer.fillColor = UIColor.white.withAlphaComponent(0.95)  // White background for better readability
            questionContainer.strokeColor = UIColor.systemBlue.withAlphaComponent(0.5)
            questionContainer.lineWidth = 2
            questionContainer.name = "questionContainer_\(index)"
            questionContainer.position = CGPoint(x: size.width / 2, y: currentY - contentHeight / 2)
            questionContainer.zPosition = 10
            
            var labelY = contentHeight / 2 - 25  // Start position (increased spacing)
            
            // Question text
            let questionLabel = SKLabelNode(text: "問題 \(index + 1): \(question.question)")
            questionLabel.fontSize = 20
            questionLabel.fontColor = .black
            questionLabel.fontName = "AvenirNext-Medium"
            questionLabel.horizontalAlignmentMode = .left
            questionLabel.verticalAlignmentMode = .top
            questionLabel.numberOfLines = 0
            questionLabel.preferredMaxLayoutWidth = containerWidth - 40
            questionLabel.position = CGPoint(x: -containerWidth / 2 + 20, y: labelY)
            questionContainer.addChild(questionLabel)
            labelY -= 50  // Increased spacing (from 40)
            
            // Answer choices
            if let choices = question.choices {
                for choice in choices {
                    let choiceLabel = SKLabelNode(text: choice)
                    choiceLabel.fontSize = 18
                    choiceLabel.fontColor = choice == question.answer ? .systemGreen : .darkGray
                    choiceLabel.horizontalAlignmentMode = .left
                    choiceLabel.numberOfLines = 0
                    choiceLabel.preferredMaxLayoutWidth = containerWidth - 60
                    choiceLabel.position = CGPoint(x: -containerWidth / 2 + 40, y: labelY)
                    questionContainer.addChild(choiceLabel)
                    labelY -= 45  // Increased spacing (from 35)
                }
            }
            
            // Correct answer
            let answerLabel = SKLabelNode(text: "正確答案: \(question.answer)")
            answerLabel.fontSize = 18
            answerLabel.fontColor = .systemGreen
            answerLabel.fontName = "AvenirNext-Bold"
            answerLabel.horizontalAlignmentMode = .left
            answerLabel.position = CGPoint(x: -containerWidth / 2 + 20, y: labelY)
            questionContainer.addChild(answerLabel)
            labelY -= 40  // Increased spacing (from 30)
            
            // Explanation
            if let explanations = question.explantation, !explanations.isEmpty {
                let explanationText = "解釋: " + explanations.joined(separator: " ")
                let explanationLabel = SKLabelNode(text: explanationText)
                explanationLabel.fontSize = 16
                explanationLabel.fontColor = .systemBlue
                explanationLabel.horizontalAlignmentMode = .left
                explanationLabel.verticalAlignmentMode = .top
                explanationLabel.numberOfLines = 0
                explanationLabel.preferredMaxLayoutWidth = containerWidth - 60
                explanationLabel.position = CGPoint(x: -containerWidth / 2 + 20, y: labelY - 10)  // Extra spacing
                questionContainer.addChild(explanationLabel)
            }
            
            addChild(questionContainer)
            currentY -= (contentHeight + spacing)
        }
    }
    
    // MARK: - Setup Play/Pause Button
    func setupPlayPauseButton() {
        playPauseButton = SKLabelNode(text: "▶️")
        playPauseButton?.fontSize = 30
        playPauseButton?.fontColor = .white
        playPauseButton?.name = "playPauseButton"
        playPauseButton?.position = CGPoint(x: size.width - 50, y: size.height - 50)
        playPauseButton?.zPosition = 100
        addChild(playPauseButton!)
    }
    
    // MARK: - Update Play/Pause Button
    func updatePlayPauseButton() {
        if isPronunciationPlaying {
            playPauseButton?.text = "⏸️"
        } else {
            playPauseButton?.text = "▶️"
        }
    }
    
    // MARK: - Read Current Question Aloud
    func readCurrentQuestion() {
        guard currentQuestionIndex < questionObjects.count else {
            // All questions read, stop
            isPronunciationPlaying = false
            updatePlayPauseButton()
            return
        }
        
        if synthesizer.isSpeaking { return }
        isPronunciationPlaying = true
        updatePlayPauseButton()
        
        let question = questionObjects[currentQuestionIndex]
        
        // ✅ Build text to read: question + choices + answer + explanation
        var textToRead = "問題 \(currentQuestionIndex + 1)。\(question.question)"
        
        if let choices = question.choices {
            textToRead += "。選項："
            for choice in choices {
                textToRead += "\(choice)。"
            }
        }
        
        textToRead += "正確答案是：\(question.answer)"
        
        if let explanations = question.explantation, !explanations.isEmpty {
            textToRead += "。解釋：\(explanations.joined(separator: "。"))"
        }
        
        let utterance = AVSpeechUtterance(string: textToRead)
        if let mandarinVoice = AVSpeechSynthesisVoice(language: "zh-CN") {
            utterance.voice = mandarinVoice
        } else if let cantoneseVoice = AVSpeechSynthesisVoice(language: "zh-HK") {
            utterance.voice = cantoneseVoice
        }
        utterance.rate = 0.5
        synthesizer.speak(utterance)
    }
    
    // MARK: - AVSpeechSynthesizerDelegate
    func speechSynthesizer(_ synthesizer: AVSpeechSynthesizer, didFinish utterance: AVSpeechUtterance) {
        // ✅ Move to next question after current one finishes
        currentQuestionIndex += 1
        
        if currentQuestionIndex < questionObjects.count {
            // ✅ Read next question after a short delay
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) { [weak self] in
                self?.readCurrentQuestion()
            }
        } else {
            // ✅ All questions read
            isPronunciationPlaying = false
            updatePlayPauseButton()
        }
    }
    
    func speechSynthesizer(_ synthesizer: AVSpeechSynthesizer, didStart utterance: AVSpeechUtterance) {
        isPronunciationPlaying = true
        updatePlayPauseButton()
    }
    
    // MARK: - Setup Continue Button (Standardized with other back buttons)
    func setupContinueButton() {
        // ✅ Standardized back button with background (matching other views)
        let backButtonSize = CGSize(width: 120, height: 44)
        continueButtonBackground = SKShapeNode(rectOf: backButtonSize, cornerRadius: 8)
        continueButtonBackground.fillColor = UIColor.white.withAlphaComponent(0.9)
        continueButtonBackground.strokeColor = UIColor.systemGray4
        continueButtonBackground.lineWidth = 1
        continueButtonBackground.position = CGPoint(x: 60, y: size.height - 50)
        continueButtonBackground.name = "continueButton"
        continueButtonBackground.zPosition = 100
        addChild(continueButtonBackground)
        
        // ✅ Create Button Label
        continueButton = SKLabelNode(text: "← 返回遊戲")
        continueButton.fontSize = 18
        continueButton.fontColor = .systemBlue
        continueButton.fontName = "AvenirNext-Medium"
        continueButton.position = continueButtonBackground.position
        continueButton.name = "continueButton"
        continueButton.zPosition = 101
        addChild(continueButton)
    }

    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard let touch = touches.first else { return }
        let location = touch.location(in: self)
        let touchedNode = atPoint(location)
        
        // ✅ Handle play/pause button
        if touchedNode.name == "playPauseButton" {
            if isPronunciationPlaying {
                synthesizer.stopSpeaking(at: .immediate)
                isPronunciationPlaying = false
            } else {
                // ✅ Restart from current question or first question
                if currentQuestionIndex >= questionObjects.count {
                    currentQuestionIndex = 0  // Reset to first question
                }
                readCurrentQuestion()
            }
            updatePlayPauseButton()
            return
        }

        if touchedNode.name == "continueButton" {
            // ✅ Highlight back button (matching other views)
            if let background = touchedNode as? SKShapeNode {
                background.fillColor = UIColor.white.withAlphaComponent(0.7)
            } else if let label = touchedNode as? SKLabelNode {
                label.fontColor = .systemBlue.withAlphaComponent(0.7)
            }
        }
    }

    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard let touch = touches.first else { return }
        let location = touch.location(in: self)
        let touchedNode = atPoint(location)

        if touchedNode.name == "continueButton" {
            // ✅ Restore button color (matching other views)
            enumerateChildNodes(withName: "continueButton") { node, _ in
                if let background = node as? SKShapeNode {
                    background.fillColor = UIColor.white.withAlphaComponent(0.9)
                } else if let label = node as? SKLabelNode {
                    label.fontColor = .systemBlue
                }
            }

            print("✅ Debug: Returning to GameScene")

            // ✅ Post notification to update UI when returning to GameScene
            NotificationCenter.default.post(name: NSNotification.Name("UpdateGameUI"), object: nil)

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
