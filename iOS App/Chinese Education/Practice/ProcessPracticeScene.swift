import SpriteKit

/**
 * PROCESS PRACTICE SCENE - Dedicated Practice for Each PIRLS Process
 * 
 * Features:
 * - Filter questions by PIRLS process type
 * - Process-specific feedback and tips
 * - Progress tracking per process
 * - Mastery indicators
 */
// MARK: - 🎯 PROCESS PRACTICE SCENE
class ProcessPracticeScene: SKScene {
    private var backButton: SKLabelNode!
    private var processSelector: SKNode!
    private var selectedProcess: PIRLSProcess?
    private var questionLabel: SKLabelNode!
    private var answerOptions: [SKLabelNode] = []
    private var currentQuestion: Question?
    private var processQuestions: [Question] = []
    private var currentQuestionIndex: Int = 0
    
    override func didMove(to view: SKView) {
        // ✅ Professional gradient background
        setupProfessionalBackground()
        
        setupUI()
        displayProcessSelector()
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
        
        // Title
        let titleLabel = SKLabelNode(text: "過程專項練習")
        titleLabel.fontSize = 32
        titleLabel.fontColor = .label
        titleLabel.position = CGPoint(x: size.width / 2, y: size.height - 50)
        addChild(titleLabel)
    }
    
    // MARK: - Display Process Selector
    func displayProcessSelector() {
        let selectorY = size.height - 120
        let buttonSpacing: CGFloat = 80
        let startX = size.width / 2 - (CGFloat(PIRLSProcess.allCases.count - 1) * buttonSpacing / 2)
        
        for (index, process) in PIRLSProcess.allCases.enumerated() {
            let button = createProcessButton(process: process)
            button.position = CGPoint(x: startX + CGFloat(index) * buttonSpacing, y: selectorY)
            button.name = "processButton_\(process.rawValue)"
            addChild(button)
        }
    }
    
    // MARK: - Create Process Button
    func createProcessButton(process: PIRLSProcess) -> SKNode {
        let container = SKNode()
        
        // Button background
        let buttonBg = SKShapeNode(rectOf: CGSize(width: 70, height: 60), cornerRadius: 10)
        buttonBg.fillColor = .systemGray5
        buttonBg.strokeColor = .systemGray
        buttonBg.lineWidth = 2
        container.addChild(buttonBg)
        
        // Process name
        let processLabel = SKLabelNode(text: process.displayName)
        processLabel.fontSize = 14
        processLabel.fontColor = .label
        processLabel.numberOfLines = 0
        processLabel.verticalAlignmentMode = .center
        processLabel.position = CGPoint(x: 0, y: 0)
        container.addChild(processLabel)
        
        return container
    }
    
    // MARK: - Load Questions for Process
    func loadQuestionsForProcess(_ process: PIRLSProcess) {
        selectedProcess = process
        processQuestions = []
        
        // Get all questions from QuestionBank (offline catalog)
        let allQuestions = QuestionBank.shared.getAllQuestions()
        
        for question in allQuestions {
            let enriched = QuestionBank.shared.enrichQuestionWithPIRLS(question, passageText: "")
            if enriched.pirlsProcess == process {
                processQuestions.append(enriched)
            }
        }
        
        // Shuffle questions for practice
        processQuestions.shuffle()
        currentQuestionIndex = 0
        
        if !processQuestions.isEmpty {
            displayQuestion(processQuestions[0])
        } else {
            showNoQuestionsMessage()
        }
    }
    
    // MARK: - Display Question
    func displayQuestion(_ question: Question) {
        // Clear previous question
        enumerateChildNodes(withName: "questionElement") { node, _ in
            node.removeFromParent()
        }
        
        currentQuestion = question
        
        // Process indicator (Phase 2.4)
        let processIndicator = SKLabelNode(text: "📌 \(question.pirlsProcess.displayName)")
        processIndicator.fontSize = 18
        processIndicator.fontColor = .systemBlue
        processIndicator.position = CGPoint(x: size.width / 2, y: size.height - 150)
        processIndicator.name = "questionElement"
        addChild(processIndicator)
        
        // Process-specific hint (Phase 2.4)
        let hint = getProcessHint(question.pirlsProcess)
        let hintLabel = SKLabelNode(text: "💡 提示: \(hint)")
        hintLabel.fontSize = 16
        hintLabel.fontColor = .systemOrange
        hintLabel.numberOfLines = 0
        hintLabel.preferredMaxLayoutWidth = size.width - 100
        hintLabel.position = CGPoint(x: size.width / 2, y: size.height - 180)
        hintLabel.name = "questionElement"
        addChild(hintLabel)
        
        // Question text
        questionLabel = SKLabelNode(text: question.question)
        questionLabel.fontSize = 20
        questionLabel.fontColor = .label
        questionLabel.numberOfLines = 0
        questionLabel.preferredMaxLayoutWidth = size.width - 100
        questionLabel.position = CGPoint(x: size.width / 2, y: size.height - 250)
        questionLabel.name = "questionElement"
        addChild(questionLabel)
        
        // Answer options
        if let choices = question.choices {
            var yOffset: CGFloat = 50
            for (index, choice) in choices.enumerated() {
                let optionLabel = SKLabelNode(text: choice)
                optionLabel.fontSize = 18
                optionLabel.fontColor = .label
                optionLabel.horizontalAlignmentMode = .left
                optionLabel.numberOfLines = 0
                optionLabel.preferredMaxLayoutWidth = size.width - 150
                optionLabel.position = CGPoint(x: 100, y: size.height - 300 - yOffset)
                optionLabel.name = "answerOption_\(index)"
                optionLabel.name = "questionElement"
                addChild(optionLabel)
                answerOptions.append(optionLabel)
                yOffset += 50
            }
        }
    }
    
    // MARK: - Get Process-Specific Hint
    func getProcessHint(_ process: PIRLSProcess) -> String {
        switch process {
        case .retrieving:
            return "仔細閱讀文本，找出明確說明的資訊"
        case .inferring:
            return "根據文本內容進行合理的推論"
        case .interpreting:
            return "解釋和整合文本中的想法"
        case .evaluating:
            return "檢視和評價文本的內容與形式"
        }
    }
    
    // MARK: - Show No Questions Message
    func showNoQuestionsMessage() {
        let messageLabel = SKLabelNode(text: "此過程暫無可用問題")
        messageLabel.fontSize = 20
        messageLabel.fontColor = .systemGray
        messageLabel.position = CGPoint(x: size.width / 2, y: size.height / 2)
        messageLabel.name = "questionElement"
        addChild(messageLabel)
    }
    
    // MARK: - Handle Answer
    func handleAnswer(_ answer: String) {
        guard let question = currentQuestion else { return }
        
        let isCorrect = answer == question.answer
        
        // Show feedback
        let feedbackLabel = SKLabelNode(text: isCorrect ? "✅ 正確！" : "❌ 錯誤")
        feedbackLabel.fontSize = 24
        feedbackLabel.fontColor = isCorrect ? .systemGreen : .systemRed
        feedbackLabel.position = CGPoint(x: size.width / 2, y: size.height / 2)
        addChild(feedbackLabel)
        
        // Process-specific feedback (Phase 2.4)
        let processFeedback = getProcessFeedback(question.pirlsProcess, isCorrect: isCorrect)
        let feedbackText = SKLabelNode(text: processFeedback)
        feedbackText.fontSize = 18
        feedbackText.fontColor = .label
        feedbackText.numberOfLines = 0
        feedbackText.preferredMaxLayoutWidth = size.width - 100
        feedbackText.position = CGPoint(x: size.width / 2, y: size.height / 2 - 50)
        addChild(feedbackText)
        
        // Remove feedback after delay
        let removeAction = SKAction.sequence([
            SKAction.wait(forDuration: 3.0),
            SKAction.run {
                feedbackLabel.removeFromParent()
                feedbackText.removeFromParent()
            }
        ])
        run(removeAction)
        
        // Move to next question
        DispatchQueue.main.asyncAfter(deadline: .now() + 3.0) {
            self.nextQuestion()
        }
    }
    
    // MARK: - Get Process-Specific Feedback
    func getProcessFeedback(_ process: PIRLSProcess, isCorrect: Bool) -> String {
        if isCorrect {
            switch process {
            case .retrieving:
                return "很好！你成功找到了文本中的明確資訊。"
            case .inferring:
                return "優秀！你的推論很合理。"
            case .interpreting:
                return "很棒！你很好地理解了文本的含義。"
            case .evaluating:
                return "出色！你的評價很到位。"
            }
        } else {
            switch process {
            case .retrieving:
                return "再仔細閱讀文本，找出明確說明的資訊。"
            case .inferring:
                return "根據文本內容進行推論，注意文本中的線索。"
            case .interpreting:
                return "嘗試整合文本中的不同資訊來理解整體含義。"
            case .evaluating:
                return "仔細檢視文本的內容和形式，做出評價。"
            }
        }
    }
    
    // MARK: - Next Question
    func nextQuestion() {
        currentQuestionIndex += 1
        if currentQuestionIndex < processQuestions.count {
            displayQuestion(processQuestions[currentQuestionIndex])
        } else {
            // Practice complete
            showPracticeComplete()
        }
    }
    
    // MARK: - Show Practice Complete
    func showPracticeComplete() {
        enumerateChildNodes(withName: "questionElement") { node, _ in
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
        } else if let nodeName = touchedNode.name, nodeName.hasPrefix("processButton_") {
            let processStr = String(nodeName.dropFirst(14))
            if let process = PIRLSProcess.allCases.first(where: { $0.rawValue == processStr }) {
                loadQuestionsForProcess(process)
            }
        } else if let nodeName = touchedNode.name, nodeName.hasPrefix("answerOption_") {
            let indexStr = String(nodeName.dropFirst(13))
            if let index = Int(indexStr),
               index < answerOptions.count,
               let choice = currentQuestion?.choices?[index] {
                handleAnswer(choice)
            }
        }
    }
}

