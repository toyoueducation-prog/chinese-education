import SpriteKit
import AVFoundation
import SwiftUI

// MARK: - 🗣️ SPEECH UTTERANCE QUEUE - Text-to-Speech System for Chinese
class AVSpeechUtteranceQueue: NSObject, AVSpeechSynthesizerDelegate {
    // MARK: - 🎤 SPEECH COMPONENTS
    private var utterances: [(AVSpeechUtterance, String)] = []  // Queue of speech items
    private let synthesizer = AVSpeechSynthesizer()             // Speech synthesizer
    private var onUpdateText: ((String) -> Void)?               // Text update callback

    func enqueue(_ utterance: AVSpeechUtterance, originalText: String) {
        utterances.append((utterance, originalText))
    }

    func setUpdateHandler(_ handler: @escaping (String) -> Void) {
        self.onUpdateText = handler
    }

    func speakAll() {
        guard !utterances.isEmpty else { return }
        synthesizer.delegate = self
        speakNext()
    }

    private func speakNext() {
        if utterances.isEmpty { return }
        let (next, text) = utterances.removeFirst()
        onUpdateText?(text)
        synthesizer.speak(next)
    }

    func speechSynthesizer(_ synthesizer: AVSpeechSynthesizer, didFinish utterance: AVSpeechUtterance) {
        speakNext()
    }
}

class ConversationScene: SKScene {
    private var backgroundMusicPlayer: AVAudioPlayer?
    private var questionLabel: SKLabelNode!
    private var answerBox: SKShapeNode!
    private var answerField: SKLabelNode!
    private var submitButton: SKLabelNode!
    private var options: [SKLabelNode] = []
    private var currentQuestionKey: String = "q1"
    private var questionType: String = ""
    private var correctAnswer: String = ""
    private var explantation: String = ""
    private var gameScore: Int = 0
    private var enteredAnswer: String = ""
    private var conversationIndex = 0
    private var conversationTexts = ["你好!", "歡迎你來臨森林", "希望你能幫我解決一個問題"]
    private var conversationLabel: SKLabelNode!
    private var isQuestionDisplayed = false
    private var choiceOptions: [String] = []  // ✅ Stores answer choices dynamically
    private var answerStartTime: TimeInterval = 0  // ✅ Track when question is shown
    private var passageText: String = ""
    private var currentPassageKey = "passage1"
    private var remainingQuestionKeys: [String] = []
    private var answeredQuestions: Set<String> = []
    private var speechSynthesizer = AVSpeechSynthesizer()
    private var incorrectAnswers: Set<String> = []
    private var isAnsweringDisabled = false  // ✅ Prevent multiple answers
    private var optionBackgrounds: [String: SKShapeNode] = [:] // ✅ Store option backgrounds
    private var synthesizer = AVSpeechSynthesizer()
    private var readingLabel: SKLabelNode!
    private var currentVideoNode: SKVideoNode?  // ✅ Track current video for cleanup
    private var questionNumber: Int = 1  // ✅ Track question number
    
    override func didMove(to view: SKView) {
        setupBackground()
        readingLabel = SKLabelNode(fontNamed: "Helvetica")
        readingLabel.fontSize = 24
        readingLabel.fontColor = .white
        readingLabel.position = CGPoint(x: frame.midX, y: frame.midY)
        readingLabel.numberOfLines = 0
        readingLabel.preferredMaxLayoutWidth = frame.width * 0.8
        readingLabel.horizontalAlignmentMode = .center
        readingLabel.verticalAlignmentMode = .center
        addChild(readingLabel)
        setupConversation()
        showConversation()
        loadPassageQuestions()
        currentQuestionKey = UserDefaults.standard.string(forKey: "currentQuestionKey") ?? "q1"
        
    }
    

    
    func setupBackground() {
        // Convert SwiftUI gradient to an image
        let gradientImage = generateGradientImage()

        // Create an SKTexture from the gradient image
        let backgroundTexture = SKTexture(image: gradientImage)

        // Create a full-screen SKSpriteNode with the gradient texture
        let backgroundNode = SKSpriteNode(texture: backgroundTexture)
        backgroundNode.position = CGPoint(x: size.width / 2, y: size.height / 2)
        backgroundNode.size = size
        backgroundNode.zPosition = -1 // Ensure it's behind other elements

        addChild(backgroundNode)
    }
    
    // MARK: - Setup Conversation Characters
    func setupConversation() {
        let photo1 = SKSpriteNode(imageNamed: "Doll2")
        photo1.size = CGSize(width: 100, height: 100)
        photo1.position = CGPoint(x: size.width * 0.1, y: size.height / 2 - 250)  // ✅ Move further left and lower
        addChild(photo1)

        let photo2 = SKSpriteNode(imageNamed: "Doll1")
        photo2.size = CGSize(width: 100, height: 100)
        photo2.position = CGPoint(x: size.width * 0.85, y: size.height / 2 - 250)  // ✅ Move further right and lower
        addChild(photo2)

        // Conversation bubble
        conversationLabel = SKLabelNode(text: "")
        conversationLabel.fontSize = 24
        conversationLabel.fontColor = .black
        conversationLabel.position = CGPoint(x: size.width / 2, y: size.height - 150)
        addChild(conversationLabel)
    }


    func readConversationTextsAndPassageAloud() {
        let utteranceQueue = AVSpeechUtteranceQueue()

        // Show and read conversation lines
        for text in conversationTexts {
            let utterance = AVSpeechUtterance(string: text)
            utterance.voice = AVSpeechSynthesisVoice(language: "zh-HK")
            utterance.rate = 0.5
            utteranceQueue.enqueue(utterance, originalText: text)
        }

        // Read the passage
        let passageUtterance = AVSpeechUtterance(string: passageText)
        passageUtterance.voice = AVSpeechSynthesisVoice(language: "zh-HK")
        passageUtterance.rate = 0.5
        utteranceQueue.enqueue(passageUtterance, originalText: passageText)

        // Update text label during reading
        utteranceQueue.setUpdateHandler { [weak self] currentText in
            DispatchQueue.main.async {
                self?.readingLabel.text = currentText
            }
        }

        utteranceQueue.speakAll()
    }
    
    // MARK: - Show Conversation Text Progressively
    func showConversation() {
        if conversationIndex < conversationTexts.count {
            conversationLabel.text = conversationTexts[conversationIndex]
            conversationIndex += 1
        } else {
            conversationLabel.removeFromParent() // Hide conversation bubble
            fetchQuestion()  // ✅ Fetch question only after conversation finishes
            isQuestionDisplayed = true
        }
    }



    // MARK: - Fetch Question from Local Question Bank
    func fetchLocalQuestion() {
        if let localQuestion = QuestionBank.shared.getQuestion(forKey: currentQuestionKey) {
            self.correctAnswer = localQuestion.answer
            self.questionType = localQuestion.type
            self.choiceOptions = localQuestion.choices ?? []

            if let passageSet = QuestionBank.shared.getPassageSet(for: currentPassageKey) {
                self.passageText = passageSet.passage
            } else {
                self.passageText = ""
            }

            DispatchQueue.main.async {
                self.clearQuestionUI()
                self.displayPassageAndQuestion(localQuestion.question, type: localQuestion.type)
                self.readPassageAloud(self.passageText) {
                    //self.displayPassageAndQuestion(localQuestion.question, type: localQuestion.type)
                }
            }
        } else {
            print("Local question not found for key: \(currentQuestionKey)")
        }
    }

    func readPassageAloud(_ passage: String, completion: @escaping () -> Void) {
        if synthesizer.isSpeaking { return }  // Prevent re-reading
        let utterance = AVSpeechUtterance(string: passage)

        if let mandarinVoice = AVSpeechSynthesisVoice(language: "zh-CN") {
            utterance.voice = mandarinVoice
        } else if let cantoneseVoice = AVSpeechSynthesisVoice(language: "zh-HK") {
            utterance.voice = cantoneseVoice
        } else if let englishVoice = AVSpeechSynthesisVoice(language: "en-US") {
            utterance.voice = englishVoice
            print("⚠️ No Chinese voice found. Falling back to English.")
        } else {
            print("❌ No suitable voice found. Skipping speech synthesis.")
            completion()  // Immediately show the passage and question if no TTS voice
            return
        }

        utterance.rate = 0.5
        speechSynthesizer.speak(utterance)

        let estimatedDuration = Double(passage.count) / 4.0  // Approximate speech duration
        DispatchQueue.main.asyncAfter(deadline: .now() + estimatedDuration) {
            completion()
        }
    }

    // MARK: - Fetch Question from API or Local Question Bank
    func fetchQuestion() {
        guard let url = URL(string: "https://toyoueducation.com/api/passage-question/\(currentQuestionKey)") else {
            fetchLocalQuestion()
            return
        }

        URLSession.shared.dataTask(with: url) { data, response, error in
            if let data = data, error == nil,
               let responseJSON = try? JSONSerialization.jsonObject(with: data, options: []) as? [String: Any],
               let questionText = responseJSON["question_text"] as? String,
               let type = responseJSON["question_type"] as? String,
               let correct = responseJSON["correct_answer"] as? String,
               let choices = responseJSON["choices"] as? [String] {  // ✅ Fetch choices dynamically

                self.correctAnswer = correct
                self.questionType = type
                self.choiceOptions = choices  // ✅ Store choices for MC

                DispatchQueue.main.async {
                    print("OK from API")
                    self.displayQuestion(questionText, type: type)
                }
            } else {
                print("Failed to fetch from API, switching to local question.")
                self.fetchLocalQuestion()
            }
        }.resume()
    }
    
    func loadPassageQuestions() {
        guard let url = URL(string: "https://toyoueducation.com/api/passage-question/\(currentPassageKey)") else {
            fetchLocalPassage()
            return
        }

        URLSession.shared.dataTask(with: url) { data, response, error in
            if let data = data, error == nil,
               let responseJSON = try? JSONSerialization.jsonObject(with: data, options: []) as? [String: Any],
               let passageText = responseJSON["passage_text"] as? String,
               let questionKeys = responseJSON["question_key"] as? [String] {  // ✅ Fetch choices dynamically
 
                self.passageText = passageText
                self.remainingQuestionKeys = questionKeys  // ✅ Store choices for MC
                if let firstQuestionKey = questionKeys.first {
                    self.currentQuestionKey = firstQuestionKey
                }
                
                DispatchQueue.main.async {
                    print("OK from API")
                    self.displayPassageAndQuestion(passageText, type: self.currentQuestionKey)
                }
            } else {
                print("Failed to fetch from API, switching to local question.")
                self.fetchLocalPassage()
            }
        }.resume()
    }

    func fetchLocalPassage(){
        if let passageSet = QuestionBank.shared.getPassageSet(for: currentPassageKey) {
            passageText = passageSet.passage
            remainingQuestionKeys = Array(passageSet.questionKeys.prefix(4))  // ✅ Only take the first 4 questions
            answeredQuestions.removeAll()
            incorrectAnswers.removeAll()  // ✅ Reset incorrect answers

            if let firstQuestionKey = remainingQuestionKeys.first {
                currentQuestionKey = firstQuestionKey
            }
        } else {
            print("❌ No passage found for key \(currentPassageKey)")
        }
    }
    
    func displayPassageAndQuestion(_ text: String, type: String) {
        // ✅ Clear any existing videos first
        clearCurrentVideo()
        
        // ✅ Create passage container with background
        let passageContainer = SKShapeNode(rectOf: CGSize(width: size.width - 60, height: 200))
        passageContainer.fillColor = UIColor.systemBlue.withAlphaComponent(0.1)
        passageContainer.strokeColor = UIColor.systemBlue.withAlphaComponent(0.3)
        passageContainer.lineWidth = 2
        passageContainer.position = CGPoint(x: size.width / 2, y: size.height - 120)
        passageContainer.name = "passageContainer"
        addChild(passageContainer)
        
        let passageLabel = SKLabelNode(text: passageText)
        passageLabel.name = "passage"
        passageLabel.fontSize = 20
        passageLabel.fontColor = .darkBlue
        passageLabel.fontName = "AvenirNext-Medium"
        passageLabel.horizontalAlignmentMode = .center
        passageLabel.verticalAlignmentMode = .top
        passageLabel.numberOfLines = 0
        passageLabel.preferredMaxLayoutWidth = size.width - 80
        passageLabel.lineBreakMode = .byWordWrapping
        passageLabel.position = CGPoint(x: 0, y: 80)
        passageContainer.addChild(passageLabel)

        let passageHeight = passageLabel.calculateAccumulatedFrame().height
        let questionStartY = size.height - 320 - passageHeight - 20

        // ✅ Create question container with better styling
        let questionContainer = SKShapeNode(rectOf: CGSize(width: size.width - 40, height: 120))
        questionContainer.fillColor = UIColor.systemYellow.withAlphaComponent(0.15)
        questionContainer.strokeColor = UIColor.systemOrange.withAlphaComponent(0.4)
        questionContainer.lineWidth = 3
        questionContainer.position = CGPoint(x: size.width / 2, y: questionStartY + 60)
        questionContainer.name = "questionContainer"
        addChild(questionContainer)
        
        // ✅ Add question number
        let questionNumberLabel = SKLabelNode(text: "問題 \(questionNumber)")
        questionNumberLabel.fontSize = 18
        questionNumberLabel.fontColor = .systemOrange
        questionNumberLabel.fontName = "AvenirNext-Bold"
        questionNumberLabel.position = CGPoint(x: 0, y: 40)
        questionContainer.addChild(questionNumberLabel)

        questionLabel = SKLabelNode(text: text)
        questionLabel.fontSize = 24
        questionLabel.fontColor = .black
        questionLabel.fontName = "AvenirNext-Medium"
        questionLabel.horizontalAlignmentMode = .center
        questionLabel.verticalAlignmentMode = .top
        questionLabel.numberOfLines = 0
        questionLabel.preferredMaxLayoutWidth = size.width - 60
        questionLabel.lineBreakMode = .byWordWrapping
        questionLabel.name = "questionLabel"
        questionLabel.position = CGPoint(x: 0, y: 10)
        questionContainer.addChild(questionLabel)

        answerStartTime = CACurrentMediaTime()

        if type == "mc" {
            displayMultipleChoice(belowY: questionStartY - 60)
        } else {
            displayOpenAnswer(belowY: questionStartY - 60)
        }
    }


    // MARK: - Display Question UI
    func displayQuestion(_ text: String, type: String) {
        let passageLabel = SKLabelNode(text: passageText)
        passageLabel.fontSize = 18
        passageLabel.fontColor = .black
        passageLabel.horizontalAlignmentMode = .center
        passageLabel.verticalAlignmentMode = .top
        passageLabel.numberOfLines = 0
        passageLabel.preferredMaxLayoutWidth = size.width - 40
        passageLabel.lineBreakMode = .byWordWrapping
        
        // ✅ Measure how much vertical space the passage takes
        let passageHeight = passageLabel.calculateAccumulatedFrame().height

        // ✅ Place the question right below the passage
        let questionStartY = size.height - 50 - passageHeight - 20  // 20 is spacing
        
        
        questionLabel = SKLabelNode(text: text)
        questionLabel.fontSize = 24
        questionLabel.fontColor = .black
        questionLabel.position = CGPoint(x: size.width / 2, y: questionStartY)
        addChild(questionLabel)

        
        // ✅ Start the timer when the question is displayed
        answerStartTime = CACurrentMediaTime()

        if type == "mc" {
            displayMultipleChoice(belowY: questionStartY)
        } else {
            displayOpenAnswer(belowY: questionStartY)
        }
    }

    // MARK: - Display Multiple Choice Answers Dynamically
    func displayMultipleChoice(belowY: CGFloat) {
        let answerSpacing: CGFloat = 60
        let startY = belowY
        
        for (index, option) in choiceOptions.enumerated() {
            let answerY = startY - (CGFloat(index) * answerSpacing)
            
            // ✅ Create answer container with better styling
            let answerContainer = SKShapeNode(rectOf: CGSize(width: size.width - 60, height: 50))
            answerContainer.fillColor = UIColor.white.withAlphaComponent(0.9)
            answerContainer.strokeColor = UIColor.systemBlue.withAlphaComponent(0.6)
            answerContainer.lineWidth = 2
            answerContainer.position = CGPoint(x: size.width / 2, y: answerY)
            answerContainer.name = "answerContainer_\(index)"
            addChild(answerContainer)
            
            // ✅ Add option letter (A, B, C, D)
            let optionLetter = SKLabelNode(text: String(Character(UnicodeScalar(65 + index)!)))
            optionLetter.fontSize = 20
            optionLetter.fontColor = .systemBlue
            optionLetter.fontName = "AvenirNext-Bold"
            optionLetter.position = CGPoint(x: -size.width/2 + 50, y: 0)
            answerContainer.addChild(optionLetter)
            
            let answerLabel = SKLabelNode(text: option)
            answerLabel.name = "answerOption_\(index)"
            answerLabel.fontSize = 20
            answerLabel.fontColor = .black
            answerLabel.fontName = "AvenirNext-Medium"
            answerLabel.horizontalAlignmentMode = .left
            answerLabel.verticalAlignmentMode = .center
            answerLabel.position = CGPoint(x: -size.width/2 + 80, y: 0)
            answerLabel.preferredMaxLayoutWidth = size.width - 140
            answerLabel.lineBreakMode = .byWordWrapping
            answerContainer.addChild(answerLabel)
            
            // ✅ Store container reference for styling
            optionBackgrounds["answerOption_\(index)"] = answerContainer
        }
    }
    
    // MARK: - Video Management
    func clearCurrentVideo() {
        if let videoNode = currentVideoNode {
            videoNode.removeFromParent()
            currentVideoNode = nil
        }
        
        // ✅ Also remove any existing video nodes by name
        enumerateChildNodes(withName: "//videoNode") { node, _ in
            node.removeFromParent()
        }
    }
    
    // MARK: - Enhanced Answer Selection
    func highlightSelectedAnswer(_ answerIndex: Int) {
        // ✅ Highlight the selected answer
        for (index, _) in choiceOptions.enumerated() {
            if let container = optionBackgrounds["answerOption_\(index)"] {
                if index == answerIndex {
                    container.fillColor = UIColor.systemBlue.withAlphaComponent(0.3)
                    container.strokeColor = UIColor.systemBlue
                    container.lineWidth = 3
                } else {
                    container.fillColor = UIColor.white.withAlphaComponent(0.9)
                    container.strokeColor = UIColor.systemBlue.withAlphaComponent(0.6)
                    container.lineWidth = 2
                }
            }
        }
    }


    // MARK: - Open Answer Question UI
    func displayOpenAnswer(belowY: CGFloat) {
        let boxSize = CGSize(width: 300, height: 50)

        if answerBox == nil {  // ✅ Ensure `answerBox` is initialized only once
            answerBox = SKShapeNode(rectOf: boxSize, cornerRadius: 10)
            answerBox.fillColor = .white
            answerBox.strokeColor = .gray
            answerBox.position = CGPoint(x: size.width / 2, y: belowY - 60)
            addChild(answerBox)
        }

        answerField = SKLabelNode(text: "Enter Answer")
        answerField.fontSize = 24
        answerField.fontColor = .gray
        answerField.position = answerBox.position
        answerField.name = "answerField"
        addChild(answerField)

        // ✅ Ensure Submit Button is added
        let submitButton = SKLabelNode(text: "提交")
        submitButton.fontSize = 28
        submitButton.fontColor = .blue
        submitButton.position = CGPoint(x: size.width / 2, y: belowY - 120)
        submitButton.name = "submitButton"
        addChild(submitButton)
    }




    // MARK: - Handle User Interaction
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard let touch = touches.first else { return }
        let location = touch.location(in: self)
        let touchedNode = atPoint(location)
        if isAnsweringDisabled { return }  // ✅ Ignore all touches if already answered
        
        if !isQuestionDisplayed {
            showConversation()
            
        } else {
            if questionType == "mc" {
                // ✅ Check if touching answer containers
                for (index, _) in choiceOptions.enumerated() {
                    if touchedNode.name == "answerContainer_\(index)" || 
                       touchedNode.name == "answerOption_\(index)" {
                        // ✅ Highlight the selected answer
                        highlightSelectedAnswer(index)
                        
                        // ✅ Check answer and continue
                        synthesizer.stopSpeaking(at: .word)
                        checkAnswer(selectedAnswer: choiceOptions[index])
                        return
                    }
                }
                
                // ✅ Fallback to old system for compatibility
                for option in options {
                    if touchedNode.name == option.name {
                        // ✅ Change the background color of the selected answer
                        if let backgroundNode = optionBackgrounds[option.name ?? ""] {
                            backgroundNode.fillColor = .black  // Change background to black
                        }
                        
                        // ✅ Change the text color to white for contrast
                        option.fontColor = .green
                        
                        // ✅ Check answer and continue
                        synthesizer.stopSpeaking(at: .word)
                        checkAnswer(selectedAnswer: option.text ?? "")
                        return
                    }
                }
            } else if touchedNode.name == "submitButton" {
                checkAnswer(selectedAnswer: enteredAnswer)
            } else if touchedNode.name == "answerField" {
                requestUserInput()
            }
        }

    }

    // MARK: - Simulated User Input
    func requestUserInput() {
        enteredAnswer = "test answer"
        answerField.text = enteredAnswer
        answerField.fontColor = .black
    }

    
    func showTemporaryResult(isCorrect: Bool, completion: @escaping () -> Void) {
        let resultText = isCorrect ? "答對了!" : "答錯了!"
        let resultLabel = SKLabelNode(text: resultText)
        resultLabel.name = "resultLabel"
        resultLabel.fontSize = 28
        resultLabel.fontColor = isCorrect ? .green : .red

        // ✅ Find the lowest displayed answer option dynamically
        var lowestAnswerY: CGFloat = size.height / 3  // Default fallback position

        for node in children {
            if let answerNode = node as? SKLabelNode, answerNode.name?.contains("answerOption") == true {
                if answerNode.position.y < lowestAnswerY {
                    lowestAnswerY = answerNode.position.y
                }
            }
        }

        resultLabel.position = CGPoint(x: size.width / 2, y: lowestAnswerY - 200)
        addChild(resultLabel)

        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
            resultLabel.removeFromParent()
            completion()  // ✅ Call the completion handler after clearing the result
        }
    }


    
    func displayResultAndAnalysis(isCorrect: Bool, analysis: String) {
        let analysisLabel = SKLabelNode(text: "分析: \(analysis)")
        analysisLabel.name = "analysisLabel"
        analysisLabel.fontSize = 22
        analysisLabel.fontColor = .darkGray
        analysisLabel.position = CGPoint(x: size.width / 2, y: size.height / 4 - 120)  // ✅ Lower position
        analysisLabel.numberOfLines = 3
        analysisLabel.preferredMaxLayoutWidth = size.width - 40
        analysisLabel.lineBreakMode = .byWordWrapping
        addChild(analysisLabel)

        DispatchQueue.main.asyncAfter(deadline: .now() + 3) { [self] in
            clearResultAndAnalysisUI()

            print("❌ Debug: Incorrect Answers Stored: \(incorrectAnswers)")

            if let nextQuestionKey = remainingQuestionKeys.first(where: { !answeredQuestions.contains($0) }) {
                print("✅ Debug: Moving to Next Question: \(nextQuestionKey)")
                currentQuestionKey = nextQuestionKey
                questionNumber += 1  // ✅ Increment question number
                clearCurrentVideo()  // ✅ Clear any playing videos
                fetchLocalQuestion()
            } else if !incorrectAnswers.isEmpty {
                print("🚨 Debug: Transitioning to HintScene")  // ✅ Confirm if this line prints
                transitionToHintScene()
            } else {
                print("✅ Debug: Transitioning to GameScene")
                transitionToGameScene()
            }
        }
    }
    
    // MARK: - Check Answer
    func checkAnswer(selectedAnswer: String) {
        let isCorrect = selectedAnswer.lowercased() == correctAnswer.lowercased()
        if isAnsweringDisabled { return }  // ✅ Ignore multiple presses
        isAnsweringDisabled = true  // ✅ Disable further answers
        
        // Play feedback video
        let videoName = isCorrect ? "correct" : "incorrect"
        playFeedbackVideo(named: videoName)


        // ✅ Highlight correct answer and dim others
        for (index, option) in choiceOptions.enumerated() {
            if let container = optionBackgrounds["answerOption_\(index)"] {
                if option.lowercased() == correctAnswer.lowercased() {
                    // ✅ Highlight correct answer in green
                    container.fillColor = UIColor.systemGreen.withAlphaComponent(0.3)
                    container.strokeColor = UIColor.systemGreen
                    container.lineWidth = 3
                } else {
                    // ✅ Dim incorrect answers
                    container.fillColor = UIColor.gray.withAlphaComponent(0.2)
                    container.strokeColor = UIColor.gray.withAlphaComponent(0.4)
                    container.lineWidth = 1
                }
            }
        }
        
        // ✅ Also handle old system for compatibility
        for node in children {
            if let answerNode = node as? SKLabelNode, answerNode.name?.contains("answerOption") == true {
                answerNode.fontColor = .gray  // ✅ Dim the answers
                answerNode.name = nil  // ✅ Remove the ability to be clicked
            }
        }
        if isCorrect {
            GameStats.shared.addScore(points: 5)
            self.isAnsweringDisabled = false  // ✅ Enable answer selection for the next question
        } else {
            incorrectAnswers.insert(currentQuestionKey)  // ✅ Track incorrect answers
            self.isAnsweringDisabled = false  // ✅ Enable answer selection for the next question
            print("🚨 Debug: Incorrect Answer Recorded for \(currentQuestionKey)")
        }

        answeredQuestions.insert(currentQuestionKey)



        let answerTimeTaken = CACurrentMediaTime() - answerStartTime

        if isCorrect && answerTimeTaken < 10.0 {
            PlayerProgress.shared.unlockBadge("神速大師!", in: self)
        }

        sendResultToFlask(isCorrect: isCorrect) { analysis in
            DispatchQueue.main.async {
                self.showTemporaryResult(isCorrect: isCorrect) {
                    self.displayResultAndAnalysis(isCorrect: isCorrect, analysis: analysis)
                    
                }
            }
        }
    }

    func playFeedbackVideo(named videoName: String) {
        // ✅ Clear any existing video first
        clearCurrentVideo()
        
        guard let url = Bundle.main.url(forResource: videoName, withExtension: "mp4") else { return }
        let player = AVPlayer(url: url)
        let videoNode = SKVideoNode(avPlayer: player)

        let videoSize = CGSize(width: 300, height: 180)
        videoNode.size = videoSize
        videoNode.position = CGPoint(x: size.width / 2, y: 120)
        videoNode.zPosition = 50
        videoNode.name = "videoNode"  // ✅ Add name for easy cleanup
        addChild(videoNode)
        
        // ✅ Store reference for cleanup
        currentVideoNode = videoNode

        player.play()

        // ✅ Shorter duration and auto-cleanup
        DispatchQueue.main.asyncAfter(deadline: .now() + 8.0) {
            self.clearCurrentVideo()
        }
    }
    func moveToNextQuestionOrScene() {
        clearResultAndAnalysisUI()
        clearQuestionUI()

        if let nextQuestionKey = remainingQuestionKeys.first(where: { !answeredQuestions.contains($0) }) {
            print("✅ Debug: Moving to Next Question: \(nextQuestionKey)")
            currentQuestionKey = nextQuestionKey
            fetchLocalQuestion()
        } else {
            // ✅ Ensure transition to HintScene occurs when necessary
            if !incorrectAnswers.isEmpty {
                print("🚨 Debug: Transitioning to HintScene due to incorrect answers.")
                transitionToHintScene()
            } else {
                print("✅ Debug: All questions correct. Returning to GameScene.")
                transitionToGameScene()
            }
        }
    }


    
    func transitionToHintScene() {
        print("🚨 Debug: Entering HintScene with incorrect questions: \(incorrectAnswers)")

        let hintScene = HintScene(size: self.size)
        hintScene.scaleMode = .aspectFill
        hintScene.incorrectQuestions = incorrectAnswers  // ✅ Pass incorrect questions
        let transition = SKTransition.fade(withDuration: 1.0)

        if let view = self.view {
            view.presentScene(hintScene, transition: transition)
        } else {
            print("❌ Debug: view is nil, cannot transition to HintScene")
        }
    }



    

    // MARK: - Transition to Game Scene
    func transitionToGameScene() {
        let gameScene = GameScene(size: self.size)
        gameScene.scaleMode = .aspectFill
        let transition = SKTransition.fade(withDuration: 1.0)
        self.view?.presentScene(gameScene, transition: transition)
    }
    
    func sendResultToFlask(isCorrect: Bool, completion: @escaping (String) -> Void) {
        guard let url = URL(string: "https://toyoueducation.com/result") else {
            completion("無法連接到伺服器")
            return
        }

        let body: [String: Any] = [
            "user": "guest",  // You can replace this with the actual username if you have login support
            "key": currentQuestionKey,
            "isCorrect": isCorrect ? 1 : 0,
            "score": GameStats.shared.gameScore
        ]

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = try? JSONSerialization.data(withJSONObject: body)

        URLSession.shared.dataTask(with: request) { data, response, error in
            if error != nil {
                completion("上傳答案失敗")
                return
            }

            // After sending result, fetch analysis
            self.fetchAnalysis { analysis in
                completion(analysis)
            }
        }.resume()
    }

    
    func fetchAnalysis(completion: @escaping (String) -> Void) {
        if let localQuestion = QuestionBank.shared.getQuestion(forKey: currentQuestionKey) {
            let localAnalysis = localQuestion.explantation?.first ?? "沒有本地分析"
            completion(localAnalysis)
            return
        }

        guard let url = URL(string: "https://toyoueducation.com/analysis_app") else {
            completion("無法獲取分析")
            return
        }

        URLSession.shared.dataTask(with: url) { data, response, error in
            guard let data = data, error == nil,
                  let analysisText = String(data: data, encoding: .utf8) else {
                completion("獲取分析失敗")
                return
            }
            completion(analysisText)
        }.resume()
    }

    func clearQuestionUI() {
        // ✅ Clear videos first
        clearCurrentVideo()
        
        for node in children {
            if node.name == "passage" ||
               node.name == "questionLabel" ||
               node.name?.hasPrefix("choice") == true ||
               node.name?.hasPrefix("answerOption") == true ||
               node.name?.hasPrefix("answerContainer") == true ||
               node.name == "answerBox" ||
               node.name == "answerField" ||
               node.name == "submitButton" ||
               node.name == "passageContainer" ||
               node.name == "questionContainer" ||
               node.name == "videoNode" {

                node.removeFromParent()
            }
        }
        
        // ✅ Remove all option backgrounds
        for (_, backgroundNode) in optionBackgrounds {
            backgroundNode.removeFromParent()
        }
        optionBackgrounds.removeAll()  // ✅ Clear dictionary

        options.removeAll()
    }
    
    func clearResultAndAnalysisUI() {
        for node in children {
            if node.name == "resultLabel" || node.name == "analysisLabel" {
                node.removeFromParent()
            }
        }
    }
    
    func generateGradientImage() -> UIImage {
        // Create a SwiftUI view as a gradient
        let gradientView = GradientBackgroundView()

        // Render SwiftUI view into UIImage
        let controller = UIHostingController(rootView: gradientView)
        let view = controller.view

        let targetSize = CGSize(width: size.width, height: size.height)
        view?.bounds = CGRect(origin: .zero, size: targetSize)
        view?.backgroundColor = .clear

        let renderer = UIGraphicsImageRenderer(size: targetSize)
        return renderer.image { context in
            view?.drawHierarchy(in: view!.bounds, afterScreenUpdates: true)
        }
    }

}

