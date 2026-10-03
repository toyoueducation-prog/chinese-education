import SpriteKit
import AVFoundation
import CoreText
import CoreGraphics
import Speech
#if os(iOS)
import UIKit
#endif

/**
 * CONVERSATION SCENE - Question & Answer System with Reading Comprehension
 * 
 * This scene handles the core educational gameplay where students:
 * - Read Chinese passages (with pagination support)
 * - Answer comprehension questions (multiple choice or open-ended)
 * - Listen to passage pronunciation with word-by-word highlighting
 * - Receive feedback and explanations
 * - Track progress through passages and questions
 * 
 * Key Features:
 * - Passage Reading: Displays Chinese passages with automatic pagination
 * - Text-to-Speech: Uses AVSpeechSynthesizer with Taiwan Mandarin voice preference
 * - Real-time Highlighting: Highlights words as they're spoken (iOS 13+ delegate method)
 * - Question System: Supports multiple choice and open-ended questions
 * - PIRLS Framework: Questions are classified by reading comprehension processes
 * - Progress Tracking: Tracks completed passages and answered questions
 * - Auto-resume: Automatically resumes reading after question feedback
 * 
 * Scene Flow:
 * 1. Scene loads with passage and first question
 * 2. Player can read passage and listen to pronunciation
 * 3. Player answers question
 * 4. Feedback video/animation plays
 * 5. Explanation is displayed
 * 6. Moves to next question or returns to GameScene
 * 
 * Data Sources:
 * - Questions and passages stored locally in QuestionBank
 * - Can fetch from Alibaba ECS backend (with local fallback)
 * - Vocabulary extracted and tracked via VocabularyManager
 */

class ConversationScene: SKScene, AVSpeechSynthesizerDelegate {
    // MARK: - Properties
    private var passageText: String = ""
    private var currentPassageKey: String = ""
    private var passagePages: [String] = []
    private var currentPassagePage: Int = 0
    private var questions: [Question] = []
    private var currentQuestionIndex: Int = 0
    private var questionLabel: SKLabelNode!
    private var answerButtons: [SKLabelNode] = []
    private var selectedAnswerIndex: Int? = nil
    private var passagePageIndicator: SKLabelNode?
    
    // Speech & Highlighting
    private var synthesizer = AVSpeechSynthesizer()
    private var isPronunciationPlaying = false
    private var playPauseButton: SKLabelNode?
    private var currentUtteranceText: String = ""
    private var passageSentences: [String] = []
    private var passageLines: [String] = []  // ✅ Store passage split by lines
    private var currentLineIndex: Int = 0  // ✅ Track which line is being displayed/pronounced
    private var shouldStopPronunciation = false  // ✅ Flag to prevent moving to next line after answering
    private var incorrectQuestionKeys: Set<String> = []  // ✅ Track incorrect question keys for summary
    private var questionStartTime: Date = Date()  // ✅ Track when question is displayed for response time
    
    // UI Elements
    private var exitButton: SKLabelNode!
    private var exitButtonBackground: SKShapeNode!
    
    // Video playback
    private var doll1VideoNode: ChromaKeyVideoNode?
    private var doll1AVPlayer: AVPlayer?
    private var doll2VideoNode: ChromaKeyVideoNode?
    private var doll2AVPlayer: AVPlayer?
    
    // Feedback video playback
    private var feedbackVideoNode: SKVideoNode?
    private var feedbackAVPlayer: AVPlayer?
    private var isShowingFeedback = false  // ✅ Track if feedback is currently showing
    
    // Open-ended questions & Voice recording
    private var isOpenEndedQuestion = false
    private var audioRecorder: AVAudioRecorder?
    private var audioPlayer: AVAudioPlayer?
    private var recordingURL: URL?
    private var isRecording = false
    private var recordButton: SKLabelNode?
    private var playRecordedButton: SKLabelNode?
    private var submitRecordedButton: SKLabelNode?
    private var recordingIndicator: SKLabelNode?
    
    override func didMove(to view: SKView) {
        backgroundColor = .white
        synthesizer.delegate = self
        
        // ✅ Setup background image
        setupBackground()
        
        // ✅ Load passage and questions
        loadPassageAndQuestions()
        
        // ✅ Setup UI
        setupConversation()
    }
    
    func setupBackground() {
        // ✅ Try to load background image, fallback to gradient color
        let backgroundImage = SKSpriteNode(imageNamed: "Background_Conversation")
        // ✅ Check if image was actually loaded (size will be non-zero if image exists)
        if backgroundImage.texture != nil && backgroundImage.size.width > 0 {
            backgroundImage.position = CGPoint(x: size.width / 2, y: size.height / 2)
            backgroundImage.size = size
            backgroundImage.zPosition = -10
            addChild(backgroundImage)
        } else {
            // ✅ Fallback: use light blue gradient background
            backgroundColor = UIColor(red: 0.9, green: 0.95, blue: 1.0, alpha: 1.0)
        }
    }
    
    // MARK: - Load Data
    func loadPassageAndQuestions() {
        // ✅ Get completed passages to avoid showing the same one
        let completedPassages = UserDefaults.standard.stringArray(forKey: "completedPassages") ?? []
        
        // ✅ Adaptive selection: DifficultyManager + LearningPathManager + InterventionEngine
        //    informed by StudentProfile / AnswerHistoryStore (local QuestionBank only).
        if let encounter = LearningPathManager.shared.selectNextEncounter(
            profile: StudentProfile.shared,
            completedPassageTexts: completedPassages,
            questionCount: 4
        ), !encounter.questions.isEmpty {
            // If the bank was fully completed, recycle by clearing the completion list.
            let allPassageTexts = QuestionBank.shared.getAllPassageSets().map {
                $0.passage.trimmingCharacters(in: .whitespacesAndNewlines)
            }
            let completedSet = Set(completedPassages.map { $0.trimmingCharacters(in: .whitespacesAndNewlines) })
            if !allPassageTexts.isEmpty && allPassageTexts.allSatisfy({ completedSet.contains($0) }) {
                UserDefaults.standard.removeObject(forKey: "completedPassages")
            }
            
            passageText = encounter.passageText
            questions = encounter.questions
            currentPassageKey = encounter.passageKey
            print("🎯 Adaptive encounter: \(encounter.selectionReason)")
        } else {
            // ✅ Fallback: sequential incomplete passage from local bank
            let allQuestions = QuestionBank.shared.getAllQuestions()
            var availablePassages: [String: [Question]] = [:]
            
            for question in allQuestions {
                if let passage = QuestionBank.shared.getPassageForQuestion(question.key) {
                    if availablePassages[passage] == nil {
                        availablePassages[passage] = []
                    }
                    availablePassages[passage]?.append(question)
                }
            }
            
            var selectedPassage: String? = nil
            for (passage, _) in availablePassages {
                if !completedPassages.contains(passage) {
                    selectedPassage = passage
                    break
                }
            }
            
            if selectedPassage == nil && !availablePassages.isEmpty {
                UserDefaults.standard.removeObject(forKey: "completedPassages")
                selectedPassage = availablePassages.keys.first
            }
            
            if let passage = selectedPassage, let passageQuestions = availablePassages[passage] {
                passageText = passage
                questions = passageQuestions
                currentPassageKey = QuestionBank.shared.passageKey(matchingPassageText: passage) ?? "unknown"
            } else {
                passageText = "這是一個測試段落。請仔細閱讀並回答問題。"
                questions = allQuestions.prefix(4).map { $0 }
                currentPassageKey = "fallback"
            }
        }
        
        // ✅ Extract vocabulary from the passage
        _ = VocabularyManager.shared.extractVocabulary(from: passageText, maxWords: 15)
        
        // ✅ Split passage into lines for line-by-line display
        splitPassageIntoLines()
    }
    
    // MARK: - Split Passage into Lines
    func splitPassageIntoLines() {
        // ✅ Limit words per line to ensure highlighting works properly
        // ✅ For Chinese, we'll use a more conservative character limit per line
        // ✅ This ensures sentences don't span too many lines and highlighting stays accurate
        let maxCharsPerLine = 25  // ✅ Reduced from calculated value to ensure better highlighting
        
        // ✅ Split by sentence boundaries first, then by word/character groups
        var lines: [String] = []
        
        // ✅ First, split by sentence boundaries (。)
        let sentences = passageText.components(separatedBy: "。").filter { !$0.trimmingCharacters(in: .whitespaces).isEmpty }
        
        for sentence in sentences {
            let sentenceText = sentence.trimmingCharacters(in: .whitespaces) + "。"
            
            // ✅ If sentence fits in one line, keep it together
            if sentenceText.count <= maxCharsPerLine {
                lines.append(sentenceText)
            } else {
                // ✅ Split long sentences at natural break points (punctuation, spaces)
                // ✅ Try to break at punctuation first, then at word boundaries
                var remainingSentence = sentenceText
                while !remainingSentence.isEmpty {
                    if remainingSentence.count <= maxCharsPerLine {
                        lines.append(remainingSentence)
                        break
                    }
                    
                    // ✅ Try to find a good break point (punctuation or space)
                    // ✅ Look for punctuation marks (，、；：) or spaces as break points
                    var breakIndex: String.Index?
                    let breakChars: [Character] = ["，", "、", "；", "：", " ", "\n"]
                    
                    // ✅ Search backwards from maxCharsPerLine to find a break point
                    for i in (0..<min(maxCharsPerLine, remainingSentence.count)).reversed() {
                        let checkIndex = remainingSentence.index(remainingSentence.startIndex, offsetBy: i)
                        if breakChars.contains(remainingSentence[checkIndex]) {
                            breakIndex = remainingSentence.index(after: checkIndex)
                            break
                        }
                    }
                    
                    // ✅ If no break point found, use maxCharsPerLine
                    let endIndex = breakIndex ?? remainingSentence.index(remainingSentence.startIndex, offsetBy: maxCharsPerLine, limitedBy: remainingSentence.endIndex) ?? remainingSentence.endIndex
                    
                    let line = String(remainingSentence[..<endIndex])
                    lines.append(line)
                    remainingSentence = String(remainingSentence[endIndex...])
                }
            }
        }
        
        passageLines = lines.isEmpty ? [passageText] : lines
        currentLineIndex = 0
    }
    
    // MARK: - Helper: Split text into lines
    func splitTextIntoLines(_ text: String, charsPerLine: Int) -> [String] {
        var lines: [String] = []
        var remainingText = text
        
        while !remainingText.isEmpty {
            if remainingText.count <= charsPerLine {
                lines.append(remainingText)
                break
            }
            
            let endIndex = remainingText.index(remainingText.startIndex, offsetBy: charsPerLine, limitedBy: remainingText.endIndex) ?? remainingText.endIndex
            let line = String(remainingText[..<endIndex])
            lines.append(line)
            remainingText = String(remainingText[endIndex...])
        }
        
        return lines
    }
    
    // MARK: - Setup UI
    func setupConversation() {
        setupExitButton()
        setupPassageContainer()
        setupPlayPauseButton()
        
        if !questions.isEmpty {
            questionStartTime = Date()  // ✅ Reset timer when displaying question
            displayQuestion(questions[currentQuestionIndex])
        }
        
        // ✅ Setup doll videos (muted)
        setupDollVideos()
        
        // ✅ Auto-play pronunciation when scene loads (after a short delay to ensure UI is ready)
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            self.readPassageAloud()
        }
    }
    
    func setupExitButton() {
        // ✅ Exit button background
        exitButtonBackground = SKShapeNode(rectOf: CGSize(width: 100, height: 40), cornerRadius: 8)
        exitButtonBackground.fillColor = UIColor.systemRed.withAlphaComponent(0.8)
        exitButtonBackground.strokeColor = .white
        exitButtonBackground.lineWidth = 2
        exitButtonBackground.position = CGPoint(x: 60, y: size.height - 40)
        exitButtonBackground.zPosition = 100
        exitButtonBackground.name = "exitButton"
        addChild(exitButtonBackground)
        
        // ✅ Exit button label
        exitButton = SKLabelNode(text: "✕ 返回")
        exitButton.fontSize = 18
        exitButton.fontColor = .white
        exitButton.fontName = "AvenirNext-Bold"
        exitButton.position = exitButtonBackground.position
        exitButton.zPosition = 101
        exitButton.name = "exitButton"
        addChild(exitButton)
    }
    
    func setupPassageContainer() {
        // ✅ Remove any existing passage container to prevent overlapping
        enumerateChildNodes(withName: "passageContainer") { node, _ in
            node.removeFromParent()
        }
        
        let safeAreaTop: CGFloat = 50
        let maxPassageHeight: CGFloat = size.height * 0.35
        let passageWidth = size.width - 60
        let lineHeight: CGFloat = 28.0
        let maxVisibleLines = Int(maxPassageHeight / lineHeight)
        
        // ✅ Calculate container height based on visible lines
        let estimatedHeight = min(CGFloat(maxVisibleLines) * lineHeight + 60, maxPassageHeight)
        
        let passageContainer = SKShapeNode(rectOf: CGSize(width: passageWidth, height: estimatedHeight))
        passageContainer.fillColor = UIColor.systemBlue.withAlphaComponent(0.1)
        passageContainer.strokeColor = UIColor.systemBlue.withAlphaComponent(0.3)
        passageContainer.lineWidth = 2
        passageContainer.position = CGPoint(x: size.width / 2, y: size.height - 80 - safeAreaTop - estimatedHeight / 2)
        passageContainer.name = "passageContainer"
        addChild(passageContainer)
        
        // ✅ Display lines one by one - show current line and previous lines
        let startY = estimatedHeight / 2 - 30
        let visibleStartIndex = max(0, currentLineIndex - maxVisibleLines + 1)
        let visibleEndIndex = min(passageLines.count, visibleStartIndex + maxVisibleLines)
        
        for (index, line) in passageLines.enumerated() {
            if index >= visibleStartIndex && index < visibleEndIndex {
                let lineLabel = SKLabelNode(text: line)
                lineLabel.name = "passageLine_\(index)"
                lineLabel.fontSize = 20
                // ✅ Highlight current line being pronounced
                if index == currentLineIndex {
                    lineLabel.fontColor = UIColor(red: 0.0, green: 0.2, blue: 0.6, alpha: 1.0)
                    lineLabel.fontName = "AvenirNext-Bold"
                } else {
                    lineLabel.fontColor = UIColor(red: 0.0, green: 0.2, blue: 0.6, alpha: 0.6)
                    lineLabel.fontName = "AvenirNext-Medium"
                }
                lineLabel.horizontalAlignmentMode = .left  // ✅ Left align for accurate highlighting
                lineLabel.verticalAlignmentMode = .top
                lineLabel.numberOfLines = 1
                let linePosition = CGFloat(index - visibleStartIndex)
                // ✅ Position from left edge of container (accounting for padding)
                lineLabel.position = CGPoint(x: -passageWidth / 2 + 20, y: startY - linePosition * lineHeight)
                passageContainer.addChild(lineLabel)
            }
        }
        
    }
    
    func setupPlayPauseButton() {
        playPauseButton = SKLabelNode(text: "▶️")
        playPauseButton?.fontSize = 30
        playPauseButton?.fontColor = .white
        playPauseButton?.name = "playPauseButton"
        playPauseButton?.position = CGPoint(x: size.width - 50, y: size.height - 50)
        playPauseButton?.zPosition = 100
        addChild(playPauseButton!)
    }
    
    func setupDollVideos() {
        // ✅ Setup doll1.mp4 (wave once, muted) with chroma green dropped
        if let videoURL = Bundle.main.url(forResource: "doll1", withExtension: "mp4") {
            let node = ChromaKeyVideoNode(
                url: videoURL,
                size: CGSize(width: 100, height: 100),
                loops: false,
                muted: true
            )
            node.position = CGPoint(x: size.width - 100, y: 100)
            node.zPosition = 50
            doll1VideoNode = node
            doll1AVPlayer = node.player
            addChild(node)
            node.play()
        }
        
        // ✅ Setup doll2.mp4 (nod loop, muted) with chroma green dropped
        if let videoURL = Bundle.main.url(forResource: "doll2", withExtension: "mp4") {
            let node = ChromaKeyVideoNode(
                url: videoURL,
                size: CGSize(width: 100, height: 100),
                loops: true,
                muted: true
            )
            node.position = CGPoint(x: 100, y: 100)
            node.zPosition = 50
            doll2VideoNode = node
            doll2AVPlayer = node.player
            addChild(node)
            node.play()
        }
    }
    
    // MARK: - Display Question
    func displayQuestion(_ question: Question) {
        // ✅ Remove ALL previous question elements first
        enumerateChildNodes(withName: "questionElement") { node, _ in
            node.removeFromParent()
        }
        
        // ✅ Remove all answer button labels from array and scene
        answerButtons.forEach { $0.removeFromParent() }
        answerButtons.removeAll()
        
        // ✅ Remove all answer button labels and backgrounds by name pattern (check up to 20 to be safe)
        for i in 0..<20 {
            enumerateChildNodes(withName: "answerButton_\(i)") { node, _ in
                node.removeFromParent()
            }
            enumerateChildNodes(withName: "answerButtonBg_\(i)") { node, _ in
                node.removeFromParent()
            }
        }
        
        // ✅ Remove question container
        enumerateChildNodes(withName: "questionContainer") { node, _ in
            node.removeFromParent()
        }
        
        // ✅ Remove any feedback videos or labels that might still be showing
        enumerateChildNodes(withName: "feedbackVideo") { node, _ in
            node.removeFromParent()
        }
        enumerateChildNodes(withName: "feedbackLabel") { node, _ in
            node.removeFromParent()
        }
        enumerateChildNodes(withName: "explanationLabel") { node, _ in
            node.removeFromParent()
        }
        
        // ✅ Stop and cleanup any playing feedback video
        feedbackVideoNode?.removeFromParent()
        feedbackAVPlayer?.pause()
        feedbackVideoNode = nil
        feedbackAVPlayer = nil
        
        // ✅ Clear the answer buttons array and reset selection
        answerButtons.removeAll()
        selectedAnswerIndex = nil
        
        let safeAreaTop: CGFloat = 50
        var passageHeight: CGFloat = size.height * 0.35
        enumerateChildNodes(withName: "passageContainer") { node, _ in
            if let container = node as? SKShapeNode {
                passageHeight = container.frame.height
            }
        }
        
        let spacing: CGFloat = 40
        let questionStartY = size.height - 120 - safeAreaTop - passageHeight - spacing
        
        // ✅ Question container - better aligned
        let questionContainerHeight: CGFloat = 120
        let questionContainerWidth = size.width - 80  // ✅ Consistent width with padding
        let questionContainer = SKShapeNode(rectOf: CGSize(width: questionContainerWidth, height: questionContainerHeight))
        questionContainer.fillColor = UIColor.systemYellow.withAlphaComponent(0.15)
        questionContainer.strokeColor = UIColor.systemOrange.withAlphaComponent(0.4)
        questionContainer.lineWidth = 3
        // ✅ Center the container horizontally
        questionContainer.position = CGPoint(x: size.width / 2, y: questionStartY - questionContainerHeight / 2)
        questionContainer.name = "questionContainer"
        addChild(questionContainer)
        
        // ✅ Question number - left aligned within container
        let questionNumberLabel = SKLabelNode(text: "問題 \(currentQuestionIndex + 1)")
        questionNumberLabel.fontSize = 18
        questionNumberLabel.fontColor = .systemOrange
        questionNumberLabel.fontName = "AvenirNext-Bold"
        questionNumberLabel.horizontalAlignmentMode = .left
        questionNumberLabel.verticalAlignmentMode = .top
        questionNumberLabel.position = CGPoint(x: -questionContainerWidth / 2 + 20, y: questionContainerHeight / 2 - 20)
        questionContainer.addChild(questionNumberLabel)
        
        // ✅ Question text - left aligned within container
        questionLabel = SKLabelNode(text: question.question)
        questionLabel.fontSize = 24
        questionLabel.fontColor = .black
        questionLabel.fontName = "AvenirNext-Medium"
        questionLabel.horizontalAlignmentMode = .left  // ✅ Left align for better readability
        questionLabel.verticalAlignmentMode = .top
        questionLabel.numberOfLines = 0
        questionLabel.preferredMaxLayoutWidth = questionContainerWidth - 40
        questionLabel.lineBreakMode = .byWordWrapping
        questionLabel.name = "questionLabel"
        questionLabel.position = CGPoint(x: -questionContainerWidth / 2 + 20, y: questionContainerHeight / 2 - 50)
        questionContainer.addChild(questionLabel)
        
        // ✅ Check question type
        isOpenEndedQuestion = (question.type == "qa")
        
        // ✅ Answer choices or open-ended input
        if let choices = question.choices, !isOpenEndedQuestion {
            displayMultipleChoice(choices, question: question, belowY: questionStartY - questionContainerHeight - 10)
        } else if isOpenEndedQuestion {
            displayOpenEndedQuestion(question: question, belowY: questionStartY - questionContainerHeight - 10)
        }
    }
    
    func displayMultipleChoice(_ choices: [String], question: Question, belowY: CGFloat) {
        // ✅ First, clear any existing answer buttons to prevent duplicates
        answerButtons.forEach { $0.removeFromParent() }
        answerButtons.removeAll()
        
        // ✅ Remove all answer button backgrounds
        for i in 0..<10 {
            enumerateChildNodes(withName: "answerButton_\(i)") { node, _ in
                node.removeFromParent()
            }
        }
        
        var yOffset: CGFloat = 0
        for (index, choice) in choices.enumerated() {
            // ✅ Create button background with unique name
            let buttonBackground = SKShapeNode(rectOf: CGSize(width: size.width - 80, height: 45), cornerRadius: 8)
            buttonBackground.fillColor = UIColor.white.withAlphaComponent(0.8)
            buttonBackground.strokeColor = UIColor.systemBlue.withAlphaComponent(0.5)
            buttonBackground.lineWidth = 2
            // ✅ Position background from left edge to match answer button
            buttonBackground.position = CGPoint(x: 80 + (size.width - 80) / 2, y: belowY - yOffset)
            buttonBackground.name = "answerButtonBg_\(index)"
            buttonBackground.zPosition = 9
            addChild(buttonBackground)
            
            // ✅ Create button label with unique name
            let answerButton = SKLabelNode(text: choice)
            answerButton.fontSize = 20
            answerButton.fontColor = .black
            answerButton.fontName = "AvenirNext-Medium"
            answerButton.horizontalAlignmentMode = .left
            answerButton.verticalAlignmentMode = .center
            answerButton.preferredMaxLayoutWidth = size.width - 120
            // ✅ Position from left edge of screen with padding
            answerButton.position = CGPoint(x: 80, y: belowY - yOffset)
            answerButton.name = "answerButton_\(index)"
            answerButton.zPosition = 10
            addChild(answerButton)
            answerButtons.append(answerButton)
            yOffset += 55
        }
    }
    
    // MARK: - Display Open-Ended Question
    func displayOpenEndedQuestion(question: Question, belowY: CGFloat) {
        // ✅ Clear any existing open-ended UI
        recordButton?.removeFromParent()
        playRecordedButton?.removeFromParent()
        submitRecordedButton?.removeFromParent()
        recordingIndicator?.removeFromParent()
        
        // ✅ Instructions label
        let instructionLabel = SKLabelNode(text: "請錄製您的答案")
        instructionLabel.fontSize = 20
        instructionLabel.fontColor = .systemBlue
        instructionLabel.fontName = "AvenirNext-Bold"
        instructionLabel.horizontalAlignmentMode = .center
        instructionLabel.position = CGPoint(x: size.width / 2, y: belowY)
        instructionLabel.name = "openEndedInstruction"
        instructionLabel.zPosition = 10
        addChild(instructionLabel)
        
        // ✅ Record button
        let recordButtonBg = SKShapeNode(rectOf: CGSize(width: 120, height: 50), cornerRadius: 10)
        recordButtonBg.fillColor = UIColor.systemRed.withAlphaComponent(0.8)
        recordButtonBg.strokeColor = .white
        recordButtonBg.lineWidth = 2
        recordButtonBg.position = CGPoint(x: size.width / 2 - 80, y: belowY - 60)
        recordButtonBg.name = "recordButtonBg"
        recordButtonBg.zPosition = 9
        addChild(recordButtonBg)
        
        recordButton = SKLabelNode(text: "🎤 錄音")
        recordButton?.fontSize = 18
        recordButton?.fontColor = .white
        recordButton?.fontName = "AvenirNext-Bold"
        recordButton?.position = recordButtonBg.position
        recordButton?.name = "recordButton"
        recordButton?.zPosition = 10
        addChild(recordButton!)
        
        // ✅ Play recorded button (initially hidden)
        let playButtonBg = SKShapeNode(rectOf: CGSize(width: 120, height: 50), cornerRadius: 10)
        playButtonBg.fillColor = UIColor.systemBlue.withAlphaComponent(0.8)
        playButtonBg.strokeColor = .white
        playButtonBg.lineWidth = 2
        playButtonBg.position = CGPoint(x: size.width / 2, y: belowY - 60)
        playButtonBg.name = "playRecordedButtonBg"
        playButtonBg.zPosition = 9
        playButtonBg.alpha = 0  // Hidden until recording exists
        addChild(playButtonBg)
        
        playRecordedButton = SKLabelNode(text: "▶️ 播放")
        playRecordedButton?.fontSize = 18
        playRecordedButton?.fontColor = .white
        playRecordedButton?.fontName = "AvenirNext-Bold"
        playRecordedButton?.position = playButtonBg.position
        playRecordedButton?.name = "playRecordedButton"
        playRecordedButton?.zPosition = 10
        playRecordedButton?.alpha = 0  // Hidden until recording exists
        addChild(playRecordedButton!)
        
        // ✅ Submit button (initially hidden)
        let submitButtonBg = SKShapeNode(rectOf: CGSize(width: 120, height: 50), cornerRadius: 10)
        submitButtonBg.fillColor = UIColor.systemGreen.withAlphaComponent(0.8)
        submitButtonBg.strokeColor = .white
        submitButtonBg.lineWidth = 2
        submitButtonBg.position = CGPoint(x: size.width / 2 + 80, y: belowY - 60)
        submitButtonBg.name = "submitRecordedButtonBg"
        submitButtonBg.zPosition = 9
        submitButtonBg.alpha = 0  // Hidden until recording exists
        addChild(submitButtonBg)
        
        submitRecordedButton = SKLabelNode(text: "✓ 提交")
        submitRecordedButton?.fontSize = 18
        submitRecordedButton?.fontColor = .white
        submitRecordedButton?.fontName = "AvenirNext-Bold"
        submitRecordedButton?.position = submitButtonBg.position
        submitRecordedButton?.name = "submitRecordedButton"
        submitRecordedButton?.zPosition = 10
        submitRecordedButton?.alpha = 0  // Hidden until recording exists
        addChild(submitRecordedButton!)
        
        // ✅ Recording indicator (initially hidden)
        recordingIndicator = SKLabelNode(text: "🔴 錄音中...")
        recordingIndicator?.fontSize = 16
        recordingIndicator?.fontColor = .systemRed
        recordingIndicator?.fontName = "AvenirNext-Medium"
        recordingIndicator?.position = CGPoint(x: size.width / 2, y: belowY - 120)
        recordingIndicator?.name = "recordingIndicator"
        recordingIndicator?.zPosition = 10
        recordingIndicator?.alpha = 0
        addChild(recordingIndicator!)
        
        // ✅ Request microphone permission
        requestMicrophonePermission()
    }
    
    // MARK: - Touch Handling
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard let touch = touches.first else { return }
        let location = touch.location(in: self)
        let touchedNode = atPoint(location)
        
        // ✅ Exit button
        if touchedNode.name == "exitButton" {
            exitButtonBackground.fillColor = UIColor.systemRed
            return
        }
        
        // ✅ Play/pause button
        if touchedNode.name == "playPauseButton" {
            if isPronunciationPlaying {
                synthesizer.stopSpeaking(at: .immediate)
                isPronunciationPlaying = false
            } else {
                readPassageAloud()
            }
            updatePlayPauseButton()
            return
        }
        
        // ✅ Answer buttons
        if let buttonName = touchedNode.name, buttonName.hasPrefix("answerButton_") {
            if let indexStr = buttonName.components(separatedBy: "_").last,
               let index = Int(indexStr) {
                selectedAnswerIndex = index
                highlightSelectedAnswer(index)
            }
        }
        
        // ✅ Record button
        if touchedNode.name == "recordButton" || touchedNode.name == "recordButtonBg" {
            if isRecording {
                stopRecording()
            } else {
                startRecording()
            }
        }
        
        // ✅ Play recorded button
        if touchedNode.name == "playRecordedButton" || touchedNode.name == "playRecordedButtonBg" {
            playRecordedAudio()
        }
        
        // ✅ Submit recorded button
        if touchedNode.name == "submitRecordedButton" || touchedNode.name == "submitRecordedButtonBg" {
            submitRecordedAnswer()
        }
    }
    
    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard let touch = touches.first else { return }
        let location = touch.location(in: self)
        let touchedNode = atPoint(location)
        
        // ✅ Exit button — leave mid-quiz without defeating the guardian
        if touchedNode.name == "exitButton" {
            exitButtonBackground.fillColor = UIColor.systemRed.withAlphaComponent(0.8)
            abandonQuizAndReturnToGame()
            return
        }
        
        // ✅ If feedback is showing, click to advance to next question
        if isShowingFeedback {
            advanceToNextQuestion()
            return
        }
        
        // ✅ Answer submission
        if !isOpenEndedQuestion {
            if let index = selectedAnswerIndex, index < questions[currentQuestionIndex].choices?.count ?? 0 {
                checkAnswer(index)
            }
        }
        // ✅ Open-ended questions are submitted via submitRecordedButton
    }
    
    func highlightSelectedAnswer(_ index: Int) {
        for (i, button) in answerButtons.enumerated() {
            if i == index {
                button.fontColor = .systemBlue
                button.fontName = "AvenirNext-Bold"
            } else {
                button.fontColor = .black
                button.fontName = "AvenirNext-Medium"
            }
        }
    }
    
    func checkAnswer(_ selectedIndex: Int? = nil, recordedAnswer: String? = nil) {
        let question = questions[currentQuestionIndex]
        var isCorrect = false
        
        if let selectedIndex = selectedIndex {
            // Multiple choice answer
            isCorrect = question.choices?[selectedIndex] == question.answer
        } else if let recordedAnswer = recordedAnswer {
            // ✅ Open-ended answer - compare recognized text with correct answer
            isCorrect = compareAnswer(recognizedText: recordedAnswer, correctAnswer: question.answer)
            print("✅ Recorded answer submitted: '\(recordedAnswer)'")
            print("   Correct answer: '\(question.answer)'")
            print("   Match result: \(isCorrect ? "✅ Correct" : "❌ Incorrect")")
        }
        
        // ✅ Track incorrect answers for summary scene
        if !isCorrect {
            incorrectQuestionKeys.insert(question.key)
            print("❌ Incorrect answer recorded. Question key: \(question.key)")
        }
        
        // ✅ Update StudentProfile with performance data
        let responseTime = Date().timeIntervalSince(questionStartTime)
        StudentProfile.shared.updatePerformance(
            question: question,
            isCorrect: isCorrect,
            responseTime: responseTime,
            passageText: passageText
        )
        StudentProfile.shared.updateVocabularyStats()  // ✅ Update vocabulary stats
        
        let loggedAnswer: String
        if let selectedIndex = selectedIndex, let choices = question.choices, selectedIndex < choices.count {
            loggedAnswer = choices[selectedIndex]
        } else if let recordedAnswer = recordedAnswer {
            loggedAnswer = recordedAnswer
        } else {
            loggedAnswer = ""
        }
        let profile = StudentProfile.shared
        AnswerHistoryStore.shared.append(
            studentID: profile.studentID,
            studentName: profile.studentName,
            passageKey: currentPassageKey,
            question: question,
            studentAnswer: loggedAnswer,
            isCorrect: isCorrect,
            responseTime: responseTime
        )
        
        // ✅ Prevent moving to next line after answering, but keep pronunciation/highlighting going
        shouldStopPronunciation = true
        // ✅ Don't stop the synthesizer - let it continue so highlight keeps working
        // ✅ Only prevent it from moving to the next line when current line finishes
        
        // ✅ Highlight correct/incorrect answer buttons (only for multiple choice)
        if let selectedIndex = selectedIndex {
            for (index, button) in answerButtons.enumerated() {
                if index == selectedIndex {
                    // Selected answer
                    button.fontColor = isCorrect ? .green : .red
                    button.fontName = "AvenirNext-Bold"
                } else if question.choices?[index] == question.answer {
                    // Correct answer (if different from selected)
                    button.fontColor = .green
                    button.fontName = "AvenirNext-Bold"
                } else {
                    // Other answers - dim them
                    button.fontColor = .gray
                    button.alpha = 0.5
                }
            }
        }
        
        // ✅ Mark that feedback is showing
        isShowingFeedback = true
        
        // ✅ Show feedback video
        showFeedbackVideo(isCorrect: isCorrect)
        
        // ✅ Show explanation after video (wait for video to start playing)
        // ✅ For incorrect answers, show explanation immediately so user can see it
        let delay = isCorrect ? 2.0 : 1.5  // ✅ Shorter delay for incorrect to show explanation sooner
        DispatchQueue.main.asyncAfter(deadline: .now() + delay) { [weak self] in
            guard let self = self else { return }
            self.showExplanation(question: question, isCorrect: isCorrect)
            print("✅ Showing explanation. Correct: \(isCorrect), Text: \(question.explantation?.joined(separator: "\n") ?? "Default")")
        }
        
        // ✅ Don't auto-advance - wait for user click (handled in touchesEnded)
    }
    
    // MARK: - Show Feedback Video
    func showFeedbackVideo(isCorrect: Bool) {
        // ✅ Remove any existing feedback video
        feedbackVideoNode?.removeFromParent()
        feedbackAVPlayer?.pause()
        feedbackVideoNode = nil
        feedbackAVPlayer = nil
        
        // ✅ Determine video file name
        let videoFileName = isCorrect ? "correct" : "incorrect"
        
        // ✅ Load and play feedback video
        guard let videoURL = Bundle.main.url(forResource: videoFileName, withExtension: "mp4") else {
            print("⚠️ \(videoFileName).mp4 not found, showing text feedback instead")
            // Fallback to text feedback
            showTextFeedback(isCorrect: isCorrect)
            return
        }
        
        feedbackAVPlayer = AVPlayer(url: videoURL)
        feedbackAVPlayer?.volume = 1.0  // ✅ Play with sound for feedback
        
        feedbackVideoNode = SKVideoNode(avPlayer: feedbackAVPlayer!)
        feedbackVideoNode?.size = CGSize(width: size.width * 0.4, height: size.height * 0.2)
        // ✅ Position video at the bottom of the screen (around 20% from bottom)
        feedbackVideoNode?.position = CGPoint(x: size.width / 2, y: size.height * 0.2)
        feedbackVideoNode?.zPosition = 150
        feedbackVideoNode?.name = "feedbackVideo"
        addChild(feedbackVideoNode!)
        
        // ✅ Play video
        feedbackAVPlayer?.play()
        
        // ✅ Remove video when it finishes (but keep explanation visible)
        NotificationCenter.default.addObserver(
            forName: .AVPlayerItemDidPlayToEndTime,
            object: feedbackAVPlayer?.currentItem,
            queue: .main
        ) { [weak self] _ in
            // ✅ Only remove video, keep explanation visible
            self?.feedbackVideoNode?.removeFromParent()
            self?.feedbackAVPlayer?.pause()
            self?.feedbackVideoNode = nil
            self?.feedbackAVPlayer = nil
            // ✅ Explanation stays visible until user clicks to advance
            print("✅ Video finished, explanation should remain visible")
        }
    }
    
    // MARK: - Show Text Feedback (Fallback)
    func showTextFeedback(isCorrect: Bool) {
        let feedbackLabel = SKLabelNode(text: isCorrect ? "✅ 正確！" : "❌ 錯誤")
        feedbackLabel.fontSize = 48
        feedbackLabel.fontColor = isCorrect ? .systemGreen : .systemRed
        feedbackLabel.fontName = "AvenirNext-Bold"
        feedbackLabel.position = CGPoint(x: size.width / 2, y: size.height / 2)
        feedbackLabel.zPosition = 200
        feedbackLabel.alpha = 0
        feedbackLabel.setScale(0.1)
        feedbackLabel.name = "feedbackLabel"
        addChild(feedbackLabel)
        
        // ✅ Animate feedback: scale up and fade in, then scale down and fade out
        let scaleUp = SKAction.scale(to: 1.2, duration: 0.3)
        let fadeIn = SKAction.fadeIn(withDuration: 0.3)
        let scaleDown = SKAction.scale(to: 1.0, duration: 0.2)
        let wait = SKAction.wait(forDuration: 1.5)
        let scaleOut = SKAction.scale(to: 0.8, duration: 0.3)
        let fadeOut = SKAction.fadeOut(withDuration: 0.3)
        let remove = SKAction.removeFromParent()
        
        let animation = SKAction.sequence([
            SKAction.group([scaleUp, fadeIn]),
            scaleDown,
            wait,
            SKAction.group([scaleOut, fadeOut]),
            remove
        ])
        
        feedbackLabel.run(animation)
    }
    
    // MARK: - Show Explanation
    func showExplanation(question: Question, isCorrect: Bool) {
        // ✅ Remove any existing explanation
        enumerateChildNodes(withName: "explanationLabel") { node, _ in
            node.removeFromParent()
        }
        
        // ✅ Get explanation text
        var explanationText = ""
        if let explanations = question.explantation, !explanations.isEmpty {
            explanationText = explanations.joined(separator: "\n")
        } else {
            explanationText = isCorrect ? "很好！你答對了。" : "正確答案是：\(question.answer)"
        }
        
        // ✅ Create explanation label - positioned at the very bottom of the screen
        let explanationLabel = SKLabelNode(text: explanationText)
        explanationLabel.fontSize = 18
        explanationLabel.fontColor = .black
        explanationLabel.fontName = "AvenirNext-Medium"
        explanationLabel.horizontalAlignmentMode = .center
        explanationLabel.verticalAlignmentMode = .top
        explanationLabel.numberOfLines = 0
        explanationLabel.preferredMaxLayoutWidth = size.width - 60
        explanationLabel.lineBreakMode = .byWordWrapping
        // ✅ Position at the very bottom (around 5% from bottom, below the video)
        explanationLabel.position = CGPoint(x: size.width / 2, y: size.height * 0.05)
        explanationLabel.zPosition = 200  // ✅ Higher zPosition than video to ensure it's visible
        explanationLabel.name = "explanationLabel"
        explanationLabel.alpha = 1.0  // ✅ Start visible (don't fade in, just show it)
        addChild(explanationLabel)
        
        print("✅ Explanation label added. Position: \(explanationLabel.position), Text: \(explanationText.prefix(50))...")
    }
    
    // MARK: - Advance to Next Question
    func advanceToNextQuestion() {
        // ✅ Reset feedback flag
        isShowingFeedback = false
        shouldStopPronunciation = false  // ✅ Reset pronunciation flag
        
        // ✅ Remove feedback video and explanation
        feedbackVideoNode?.removeFromParent()
        feedbackAVPlayer?.pause()
        feedbackVideoNode = nil
        feedbackAVPlayer = nil
        enumerateChildNodes(withName: "explanationLabel") { node, _ in
            node.removeFromParent()
        }
        
        // ✅ Move to next question
        currentQuestionIndex += 1
        selectedAnswerIndex = nil
        
        if currentQuestionIndex < questions.count {
            // ✅ Display next question
            questionStartTime = Date()  // ✅ Reset timer for new question
            displayQuestion(questions[currentQuestionIndex])
        } else {
            // ✅ All questions completed - check if there are incorrect answers
            if !incorrectQuestionKeys.isEmpty {
                // ✅ Show summary of incorrect answers
                transitionToHintScene()
            } else {
                // ✅ All correct, return to game scene
                transitionToGameScene()
            }
        }
    }
    
    // MARK: - Transition to Hint Scene (Summary of Incorrect Answers)
    func transitionToHintScene() {
        synthesizer.stopSpeaking(at: .immediate)
        doll1AVPlayer?.pause()
        doll2AVPlayer?.pause()
        
        print("✅ Transitioning to HintScene with \(incorrectQuestionKeys.count) incorrect questions")
        
        // ✅ Mark this passage as completed
        var completedPassages = UserDefaults.standard.stringArray(forKey: "completedPassages") ?? []
        let isNewPassage = !completedPassages.contains(passageText)
        if isNewPassage {
            completedPassages.append(passageText)
            UserDefaults.standard.set(completedPassages, forKey: "completedPassages")
        }
        
        // ✅ Add XP for completing the passage (even with incorrect answers, still get some XP)
        if isNewPassage {
            let totalQuestions = questions.count
            let correctAnswers = totalQuestions - incorrectQuestionKeys.count
            let accuracy = Double(correctAnswers) / Double(totalQuestions)
            
            // ✅ Base XP: 30 XP for completing passage (less than perfect)
            // ✅ Bonus XP: Based on accuracy (100% = +50, 50% = +0)
            let baseXP = 30
            let bonusXP = Int(50 * accuracy)
            let totalXP = baseXP + bonusXP
            
            let oldLevel = PlayerProgress.shared.level
            PlayerProgress.shared.addXP(amount: totalXP)
            let newLevel = PlayerProgress.shared.level
            let currentXP = PlayerProgress.shared.xp
            
            print("✅ Passage completed (with incorrect answers)! XP: +\(totalXP) (Base: \(baseXP), Bonus: \(bonusXP), Accuracy: \(Int(accuracy * 100))%)")
            print("   Total XP: \(currentXP), Level: \(newLevel)")
            
            // ✅ Check for level up
            if newLevel > oldLevel {
                print("🎉 Level Up! From Level \(oldLevel) to Level \(newLevel)!")
            }
        }
        
        ClassManager.shared.addOrUpdateStudentFromCurrentProfile(displayName: nil)
        
        // ✅ Quiz finished (with some incorrect) — mark guardian defeated before HintScene
        NPC.shared.completePendingEncounter()
        NotificationCenter.default.post(name: NSNotification.Name("EnemyCompleted"), object: nil)
        
        let hintScene = HintScene(size: self.size)
        hintScene.incorrectQuestions = incorrectQuestionKeys
        hintScene.scaleMode = .aspectFill
        let transition = SKTransition.fade(withDuration: 1.0)
        self.view?.presentScene(hintScene, transition: transition)
    }
    
    /// Mid-quiz exit: do not award XP or remove the guardian.
    func abandonQuizAndReturnToGame() {
        synthesizer.stopSpeaking(at: .immediate)
        doll1AVPlayer?.pause()
        doll2AVPlayer?.pause()
        
        NPC.shared.abandonPendingEncounter()
        NotificationCenter.default.post(name: NSNotification.Name("UpdateGameUI"), object: nil)
        
        let gameScene = GameScene(size: self.size)
        gameScene.scaleMode = .aspectFill
        let transition = SKTransition.fade(withDuration: 1.0)
        self.view?.presentScene(gameScene, transition: transition)
    }
    
    func transitionToGameScene() {
        synthesizer.stopSpeaking(at: .immediate)
        doll1AVPlayer?.pause()
        doll2AVPlayer?.pause()
        
        // ✅ Mark this passage as completed
        var completedPassages = UserDefaults.standard.stringArray(forKey: "completedPassages") ?? []
        let isNewPassage = !completedPassages.contains(passageText)
        if isNewPassage {
            completedPassages.append(passageText)
            UserDefaults.standard.set(completedPassages, forKey: "completedPassages")
        }
        
        // ✅ Add XP for completing the passage (only if it's a new passage)
        if isNewPassage {
            let totalQuestions = questions.count
            let correctAnswers = totalQuestions - incorrectQuestionKeys.count
            let accuracy = Double(correctAnswers) / Double(totalQuestions)
            
            // ✅ Base XP: 50 XP for completing passage
            // ✅ Bonus XP: Up to 50 more based on accuracy (100% = +50, 50% = +0)
            let baseXP = 50
            let bonusXP = Int(50 * accuracy)
            let totalXP = baseXP + bonusXP
            
            let oldLevel = PlayerProgress.shared.level
            PlayerProgress.shared.addXP(amount: totalXP)
            let newLevel = PlayerProgress.shared.level
            let currentXP = PlayerProgress.shared.xp
            
            print("✅ Passage completed! XP: +\(totalXP) (Base: \(baseXP), Bonus: \(bonusXP), Accuracy: \(Int(accuracy * 100))%)")
            print("   Total XP: \(currentXP), Level: \(newLevel)")
            
            // ✅ Check for level up
            if newLevel > oldLevel {
                print("🎉 Level Up! From Level \(oldLevel) to Level \(newLevel)!")
            }
        }
        
        // ✅ Defeat guardian only after successful quiz completion (before presenting GameScene)
        NPC.shared.completePendingEncounter()
        NotificationCenter.default.post(name: NSNotification.Name("EnemyCompleted"), object: nil)
        
        // ✅ Post notification to update UI when returning to GameScene
        NotificationCenter.default.post(name: NSNotification.Name("UpdateGameUI"), object: nil)
        
        ClassManager.shared.addOrUpdateStudentFromCurrentProfile(displayName: nil)
        
        let gameScene = GameScene(size: self.size)
        gameScene.scaleMode = .aspectFill
        let transition = SKTransition.fade(withDuration: 1.0)
        self.view?.presentScene(gameScene, transition: transition)
    }
    
    // MARK: - Speech Synthesis
    func readPassageAloud() {
        // ✅ Stop any current speech first
        if synthesizer.isSpeaking {
            synthesizer.stopSpeaking(at: .immediate)
        }
        
        // ✅ Read current line
        readCurrentLine()
    }
    
    func readCurrentLine() {
        guard currentLineIndex < passageLines.count else {
            // ✅ All lines read, stop
            isPronunciationPlaying = false
            updatePlayPauseButton()
            return
        }
        
        isPronunciationPlaying = true
        updatePlayPauseButton()
        
        let currentLine = passageLines[currentLineIndex]
        currentUtteranceText = currentLine
        
        // ✅ Update display to highlight current line
        updatePassageDisplay()
        
        // ✅ Make sure we have text to read
        guard !currentLine.isEmpty else {
            print("⚠️ No text to read")
            moveToNextLine()
            return
        }
        
        let utterance = AVSpeechUtterance(string: currentLine)
        
        // ✅ Try to get Taiwan Mandarin voice first, then other Chinese voices
        if let taiwanVoice = AVSpeechSynthesisVoice(language: "zh-TW") {
            utterance.voice = taiwanVoice
        } else if let mandarinVoice = AVSpeechSynthesisVoice(language: "zh-CN") {
            utterance.voice = mandarinVoice
        } else if let cantoneseVoice = AVSpeechSynthesisVoice(language: "zh-HK") {
            utterance.voice = cantoneseVoice
        }
        
        utterance.rate = 0.5
        utterance.pitchMultiplier = 1.0
        utterance.volume = 1.0
        
        print("🔊 Starting pronunciation of line \(currentLineIndex + 1): \(currentLine.prefix(50))...")
        synthesizer.speak(utterance)
    }
    
    func moveToNextLine() {
        currentLineIndex += 1
        if currentLineIndex < passageLines.count {
            // ✅ Auto-play next line
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                self.readCurrentLine()
            }
        } else {
            // ✅ All lines read
            isPronunciationPlaying = false
            updatePlayPauseButton()
        }
    }
    
    func updatePassageDisplay() {
        // ✅ Remove old passage container completely (including all lines and indicators)
        enumerateChildNodes(withName: "passageContainer") { node, _ in
            node.removeFromParent()
        }
        
        // ✅ Remove any orphaned passage lines (in case they exist)
        enumerateChildNodes(withName: "passageLine_") { node, _ in
            node.removeFromParent()
        }
        
        // ✅ Remove any line indicators
        enumerateChildNodes(withName: "lineIndicator") { node, _ in
            node.removeFromParent()
        }
        
        // ✅ Re-setup passage container with updated current line
        setupPassageContainer()
    }
    
    func updatePlayPauseButton() {
        if isPronunciationPlaying {
            playPauseButton?.text = "⏸️"
        } else {
            playPauseButton?.text = "▶️"
        }
    }
    
    // MARK: - AVSpeechSynthesizerDelegate
    @available(iOS 13.0, *)
    func speechSynthesizer(_ synthesizer: AVSpeechSynthesizer, willSpeakRangeOfSpeechString characterRange: NSRange, utterance: AVSpeechUtterance) {
        // ✅ Highlight text as it's spoken - limit to single word for better tracking
        let textToUse = currentUtteranceText.isEmpty ? utterance.speechString : currentUtteranceText
        
        // ✅ Limit range to a reasonable length (single word/phrase) to avoid long highlights
        let limitedRange: NSRange
        if characterRange.length > 10 {
            // ✅ If range is too long, limit it to the first part (likely a single word)
            limitedRange = NSRange(location: characterRange.location, length: min(characterRange.length, 10))
        } else {
            limitedRange = characterRange
        }
        
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            self.highlightTextRange(limitedRange, in: textToUse)
        }
    }
    
    func speechSynthesizer(_ synthesizer: AVSpeechSynthesizer, didFinish utterance: AVSpeechUtterance) {
        // ✅ Only move to next line if pronunciation wasn't stopped by answering
        if !shouldStopPronunciation {
            moveToNextLine()
        } else {
            // ✅ Reset flag for next question
            shouldStopPronunciation = false
        }
    }
    
    func speechSynthesizer(_ synthesizer: AVSpeechSynthesizer, didStart utterance: AVSpeechUtterance) {
        isPronunciationPlaying = true
        updatePlayPauseButton()
    }
    
    // MARK: - Text Highlighting
    func highlightTextRange(_ range: NSRange, in text: String) {
        // ✅ The range from speech synthesizer is relative to the current line being spoken
        guard currentLineIndex < passageLines.count else { return }
        let currentLine = passageLines[currentLineIndex]
        
        // ✅ Validate range is within bounds of current line
        guard range.location < currentLine.count else { return }
        let lineRange = NSRange(
            location: range.location,
            length: min(range.length, currentLine.count - range.location)
        )
        
        enumerateChildNodes(withName: "passageContainer") { [weak self] containerNode, _ in
            guard let self = self else { return }
            if let container = containerNode as? SKShapeNode {
                // ✅ Find the current line label
                if let label = container.childNode(withName: "passageLine_\(self.currentLineIndex)") as? SKLabelNode {
                    // ✅ Remove old highlights
                    container.enumerateChildNodes(withName: "speechHighlight") { node, _ in
                        node.run(SKAction.sequence([
                            SKAction.fadeOut(withDuration: 0.1),
                            SKAction.removeFromParent()
                        ]))
                    }
                    
                    // ✅ Create highlight for current range on current line
                    self.createSpeechHighlight(for: lineRange, in: label, container: container, pageText: currentLine)
                }
            }
        }
    }
    
    func createSpeechHighlight(for range: NSRange, in label: SKLabelNode, container: SKShapeNode, pageText: String) {
        // ✅ Use Core Text to calculate exact positions matching the rendered text layout
        let font = UIFont(name: label.fontName ?? "AvenirNext-Medium", size: label.fontSize) ?? UIFont.systemFont(ofSize: label.fontSize)
        let passageWidth = size.width - 60
        let maxWidth = label.preferredMaxLayoutWidth > 0 ? label.preferredMaxLayoutWidth : (passageWidth - 40)
        
        // ✅ Create attributed string with same properties as label (matching word wrapping)
        let paragraphStyle = NSMutableParagraphStyle()
        paragraphStyle.lineBreakMode = .byWordWrapping  // ✅ Match label's word wrapping mode
        paragraphStyle.alignment = label.horizontalAlignmentMode == .center ? .center : .left
        
        let textAttributes: [NSAttributedString.Key: Any] = [
            .font: font,
            .paragraphStyle: paragraphStyle
        ]
        
        let attributedString = NSAttributedString(string: pageText, attributes: textAttributes)
        let framesetter = CTFramesetterCreateWithAttributedString(attributedString)
        let path = CGPath(rect: CGRect(x: 0, y: 0, width: maxWidth, height: .greatestFiniteMagnitude), transform: nil)
        let frame = CTFramesetterCreateFrame(framesetter, CFRange(location: 0, length: pageText.count), path, nil)
        
        let lines = CTFrameGetLines(frame) as! [CTLine]
        var lineOrigins = [CGPoint](repeating: .zero, count: lines.count)
        CTFrameGetLineOrigins(frame, CFRange(location: 0, length: lines.count), &lineOrigins)
        
        let lineHeight = font.lineHeight
        let maxLineOriginY = lineOrigins.map { $0.y }.max() ?? 0
        
        // ✅ Remove all old highlights first
        container.enumerateChildNodes(withName: "speechHighlight") { node, _ in
            node.removeFromParent()
        }
        
        // ✅ Find which lines contain the highlight range
        for (lineIndex, line) in lines.enumerated() {
            let lineRange = CTLineGetStringRange(line)
            let lineStart = Int(lineRange.location)
            let lineEnd = Int(lineRange.location + lineRange.length)
            
            // ✅ Check if this line intersects with the highlight range
            if range.location < lineEnd && range.location + range.length > lineStart {
                let lineOrigin = lineOrigins[lineIndex]
                let highlightStart = max(range.location, lineStart)
                let highlightEnd = min(range.location + range.length, lineEnd)
                
                if highlightStart < highlightEnd {
                    // ✅ Calculate horizontal position within the line
                    let startOffset = CTLineGetOffsetForStringIndex(line, highlightStart, nil)
                    var endOffset: CGFloat = 0
                    if highlightEnd < lineEnd {
                        endOffset = CTLineGetOffsetForStringIndex(line, highlightEnd, nil)
                    } else {
                        endOffset = CTLineGetTypographicBounds(line, nil, nil, nil)
                    }
                    
                    let highlightWidth = max(endOffset - startOffset, 10)
                    
                    // ✅ Calculate X position - now always left-aligned
                    // ✅ For left alignment, startOffset is from the left edge
                    let highlightX = startOffset + (highlightWidth / 2)
                    
                    // ✅ Calculate Y position (convert from Core Text coordinates to SpriteKit)
                    // ✅ Core Text uses bottom-left origin, SpriteKit uses top-left
                    // ✅ Calculate the distance from the top line to this line
                    let lineOffsetFromTop = maxLineOriginY - lineOrigin.y
                    
                    // ✅ Get the actual line metrics for this line
                    var lineAscent: CGFloat = 0
                    var lineDescent: CGFloat = 0
                    var lineLeading: CGFloat = 0
                    CTLineGetTypographicBounds(line, &lineAscent, &lineDescent, &lineLeading)
                    
                    // ✅ Label position is top-aligned (verticalAlignmentMode = .top)
                    // ✅ The label's position.y represents the top of the text area
                    // ✅ In Core Text, lineOrigin.y is the baseline of the line
                    // ✅ We need to move DOWN from the top by: (distance from top line) + (ascent of top line)
                    // ✅ But since we're measuring from the top line's baseline, we need to add the top line's ascent
                    var topLineAscent: CGFloat = 0
                    if let topLine = lines.first {
                        CTLineGetTypographicBounds(topLine, &topLineAscent, nil, nil)
                    }
                    
                    // ✅ Calculate Y: start at label top, move down by the offset from top line, then adjust for baseline
                    // ✅ The first line's baseline is at (topLineAscent) below the label top
                    // ✅ Each subsequent line is (lineOffsetFromTop) below the first line's baseline
                    let spriteKitY = label.position.y - topLineAscent - lineOffsetFromTop + (lineAscent * 0.5)
                    
                    // ✅ Create highlight node
                    let highlightNode = SKShapeNode(rectOf: CGSize(width: highlightWidth, height: lineHeight * 0.8))
                    highlightNode.fillColor = UIColor.systemYellow.withAlphaComponent(0.15)  // ✅ More transparent so text is visible
                    highlightNode.strokeColor = UIColor.systemOrange.withAlphaComponent(0.3)  // ✅ Lighter stroke
                    highlightNode.lineWidth = 1.5
                    highlightNode.name = "speechHighlight"
                    highlightNode.zPosition = label.zPosition + 1
                    highlightNode.position = CGPoint(
                        x: label.position.x + highlightX,
                        y: spriteKitY
                    )
                    
                    // ✅ Store range in userData for tracking
                    highlightNode.userData = ["range": range]
                    
                    container.addChild(highlightNode)
                    highlightNode.alpha = 0
                    highlightNode.run(SKAction.fadeIn(withDuration: 0.1))
                }
            }
        }
    }
    
    // MARK: - Voice Recording
    func requestMicrophonePermission() {
        AVAudioSession.sharedInstance().requestRecordPermission { granted in
            DispatchQueue.main.async {
                if !granted {
                    print("⚠️ Microphone permission denied")
                    // Show alert to user
                }
            }
        }
    }
    
    func startRecording() {
        // ✅ Stop any current recording
        if isRecording {
            stopRecording()
            return
        }
        
        // ✅ Setup audio session
        let audioSession = AVAudioSession.sharedInstance()
        do {
            try audioSession.setCategory(.playAndRecord, mode: .default)
            try audioSession.setActive(true)
        } catch {
            print("❌ Failed to setup audio session: \(error)")
            return
        }
        
        // ✅ Create recording URL
        let documentsPath = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        recordingURL = documentsPath.appendingPathComponent("recording_\(Date().timeIntervalSince1970).m4a")
        
        // ✅ Setup recorder
        let settings: [String: Any] = [
            AVFormatIDKey: Int(kAudioFormatMPEG4AAC),
            AVSampleRateKey: 44100.0,
            AVNumberOfChannelsKey: 1,
            AVEncoderAudioQualityKey: AVAudioQuality.high.rawValue
        ]
        
        guard let url = recordingURL else { return }
        
        do {
            audioRecorder = try AVAudioRecorder(url: url, settings: settings)
            audioRecorder?.record()
            isRecording = true
            
            // ✅ Update UI
            recordButton?.text = "⏹️ 停止"
            recordingIndicator?.alpha = 1.0
            recordingIndicator?.run(SKAction.repeatForever(
                SKAction.sequence([
                    SKAction.fadeAlpha(to: 0.3, duration: 0.5),
                    SKAction.fadeAlpha(to: 1.0, duration: 0.5)
                ])
            ))
            
            print("✅ Started recording")
        } catch {
            print("❌ Failed to start recording: \(error)")
        }
    }
    
    func stopRecording() {
        guard isRecording else { return }
        
        audioRecorder?.stop()
        isRecording = false
        
        // ✅ Update UI
        recordButton?.text = "🎤 錄音"
        recordingIndicator?.removeAllActions()
        recordingIndicator?.alpha = 0
        
        // ✅ Show play and submit buttons
        playRecordedButton?.run(SKAction.fadeIn(withDuration: 0.3))
        submitRecordedButton?.run(SKAction.fadeIn(withDuration: 0.3))
        enumerateChildNodes(withName: "playRecordedButtonBg") { node, _ in
            node.run(SKAction.fadeIn(withDuration: 0.3))
        }
        enumerateChildNodes(withName: "submitRecordedButtonBg") { node, _ in
            node.run(SKAction.fadeIn(withDuration: 0.3))
        }
        
        print("✅ Stopped recording")
    }
    
    func playRecordedAudio() {
        guard let url = recordingURL, FileManager.default.fileExists(atPath: url.path) else {
            print("⚠️ No recording to play")
            return
        }
        
        do {
            audioPlayer = try AVAudioPlayer(contentsOf: url)
            audioPlayer?.play()
            print("✅ Playing recorded audio")
        } catch {
            print("❌ Failed to play recording: \(error)")
        }
    }
    
    func submitRecordedAnswer() {
        guard let url = recordingURL, FileManager.default.fileExists(atPath: url.path) else {
            print("⚠️ No recording to submit")
            showRecognitionError("沒有錄音可提交")
            return
        }
        
        // ✅ Show loading indicator while recognizing
        showRecognitionLoading()
        
        // ✅ Convert audio to text using speech recognition
        recognizeSpeech(from: url) { [weak self] recognizedText in
            DispatchQueue.main.async {
                guard let self = self else { return }
                
                // ✅ Hide loading indicator
                self.hideRecognitionLoading()
                
                if let text = recognizedText, !text.isEmpty {
                    print("✅ Recognized text: '\(text)'")
                    // ✅ Show recognized text to user
                    self.showRecognizedText(text)
                    // ✅ Check answer with recognized text
                    self.checkAnswer(recordedAnswer: text)
                } else {
                    // ✅ If recognition fails, show error
                    print("⚠️ Speech recognition failed")
                    self.showRecognitionError("語音辨識失敗，請重試")
                }
            }
        }
    }
    
    func recognizeSpeech(from url: URL, completion: @escaping (String?) -> Void) {
        // ✅ Request speech recognition permission
        SFSpeechRecognizer.requestAuthorization { authStatus in
            guard authStatus == .authorized else {
                print("⚠️ Speech recognition not authorized")
                completion(nil)
                return
            }
            
            // ✅ Create recognizer with Chinese language
            guard let recognizer = SFSpeechRecognizer(locale: Locale(identifier: "zh-TW")) else {
                print("⚠️ Chinese speech recognizer not available")
                completion(nil)
                return
            }
            
            guard recognizer.isAvailable else {
                print("⚠️ Speech recognizer not available")
                completion(nil)
                return
            }
            
            // ✅ Create recognition request
            let request = SFSpeechURLRecognitionRequest(url: url)
            request.shouldReportPartialResults = false
            
            // ✅ Start recognition
            recognizer.recognitionTask(with: request) { result, error in
                if let error = error {
                    print("❌ Speech recognition error: \(error)")
                    completion(nil)
                    return
                }
                
                if let result = result, result.isFinal {
                    completion(result.bestTranscription.formattedString)
                } else if let result = result {
                    // ✅ Handle partial results if needed
                    completion(result.bestTranscription.formattedString)
                }
            }
        }
    }
    
    // MARK: - Answer Comparison (Fuzzy Matching for Chinese)
    func compareAnswer(recognizedText: String, correctAnswer: String) -> Bool {
        // ✅ Normalize both strings (remove whitespace, punctuation)
        let normalizedRecognized = normalizeChineseText(recognizedText)
        let normalizedCorrect = normalizeChineseText(correctAnswer)
        
        // ✅ Exact match
        if normalizedRecognized == normalizedCorrect {
            return true
        }
        
        // ✅ Check if recognized text contains the correct answer (for longer answers)
        if normalizedRecognized.contains(normalizedCorrect) {
            return true
        }
        
        // ✅ Check if correct answer contains recognized text (for partial matches)
        if normalizedCorrect.contains(normalizedRecognized) && normalizedRecognized.count >= Int(Double(normalizedCorrect.count) * 0.7) {
            return true
        }
        
        // ✅ Calculate similarity using character matching
        let similarity = calculateSimilarity(normalizedRecognized, normalizedCorrect)
        print("   Similarity: \(Int(similarity * 100))%")
        
        // ✅ Accept if similarity is above 70% (adjustable threshold)
        return similarity >= 0.7
    }
    
    // MARK: - Text Normalization
    func normalizeChineseText(_ text: String) -> String {
        // ✅ Remove whitespace, punctuation, and convert to lowercase
        let normalized = text
            .replacingOccurrences(of: " ", with: "")
            .replacingOccurrences(of: "，", with: "")
            .replacingOccurrences(of: "。", with: "")
            .replacingOccurrences(of: "、", with: "")
            .replacingOccurrences(of: "？", with: "")
            .replacingOccurrences(of: "！", with: "")
            .replacingOccurrences(of: "：", with: "")
            .replacingOccurrences(of: "；", with: "")
            .replacingOccurrences(of: "「", with: "")
            .replacingOccurrences(of: "」", with: "")
            .replacingOccurrences(of: "『", with: "")
            .replacingOccurrences(of: "』", with: "")
            .trimmingCharacters(in: .whitespacesAndNewlines)
        return normalized
    }
    
    // MARK: - Similarity Calculation
    func calculateSimilarity(_ text1: String, _ text2: String) -> Double {
        if text1.isEmpty || text2.isEmpty {
            return 0.0
        }
        
        // ✅ Use Levenshtein distance for similarity
        let distance = levenshteinDistance(text1, text2)
        let maxLength = max(text1.count, text2.count)
        
        if maxLength == 0 {
            return 1.0
        }
        
        return 1.0 - (Double(distance) / Double(maxLength))
    }
    
    // MARK: - Levenshtein Distance
    func levenshteinDistance(_ s1: String, _ s2: String) -> Int {
        let s1Array = Array(s1)
        let s2Array = Array(s2)
        let m = s1Array.count
        let n = s2Array.count
        
        var matrix = Array(repeating: Array(repeating: 0, count: n + 1), count: m + 1)
        
        for i in 0...m {
            matrix[i][0] = i
        }
        
        for j in 0...n {
            matrix[0][j] = j
        }
        
        for i in 1...m {
            for j in 1...n {
                let cost = s1Array[i - 1] == s2Array[j - 1] ? 0 : 1
                matrix[i][j] = min(
                    matrix[i - 1][j] + 1,      // deletion
                    matrix[i][j - 1] + 1,      // insertion
                    matrix[i - 1][j - 1] + cost // substitution
                )
            }
        }
        
        return matrix[m][n]
    }
    
    // MARK: - Show Recognized Text
    func showRecognizedText(_ text: String) {
        // ✅ Remove existing recognized text label
        enumerateChildNodes(withName: "recognizedTextLabel") { node, _ in
            node.removeFromParent()
        }
        
        let recognizedLabel = SKLabelNode(text: "辨識結果: \(text)")
        recognizedLabel.fontSize = 18
        recognizedLabel.fontColor = .systemBlue
        recognizedLabel.fontName = "AvenirNext-Medium"
        recognizedLabel.horizontalAlignmentMode = .center
        recognizedLabel.position = CGPoint(x: size.width / 2, y: size.height * 0.15)
        recognizedLabel.zPosition = 100
        recognizedLabel.name = "recognizedTextLabel"
        addChild(recognizedLabel)
        
        // ✅ Fade out after 5 seconds
        recognizedLabel.run(SKAction.sequence([
            SKAction.wait(forDuration: 5.0),
            SKAction.fadeOut(withDuration: 0.5),
            SKAction.removeFromParent()
        ]))
    }
    
    // MARK: - Show Recognition Loading
    func showRecognitionLoading() {
        // ✅ Remove existing loading indicator
        enumerateChildNodes(withName: "recognitionLoading") { node, _ in
            node.removeFromParent()
        }
        
        let loadingLabel = SKLabelNode(text: "正在辨識語音...")
        loadingLabel.fontSize = 18
        loadingLabel.fontColor = .systemOrange
        loadingLabel.fontName = "AvenirNext-Medium"
        loadingLabel.horizontalAlignmentMode = .center
        loadingLabel.position = CGPoint(x: size.width / 2, y: size.height * 0.15)
        loadingLabel.zPosition = 100
        loadingLabel.name = "recognitionLoading"
        addChild(loadingLabel)
        
        // ✅ Animate loading dots
        loadingLabel.run(SKAction.repeatForever(
            SKAction.sequence([
                SKAction.run { loadingLabel.text = "正在辨識語音." },
                SKAction.wait(forDuration: 0.3),
                SKAction.run { loadingLabel.text = "正在辨識語音.." },
                SKAction.wait(forDuration: 0.3),
                SKAction.run { loadingLabel.text = "正在辨識語音..." },
                SKAction.wait(forDuration: 0.3)
            ])
        ))
    }
    
    // MARK: - Hide Recognition Loading
    func hideRecognitionLoading() {
        enumerateChildNodes(withName: "recognitionLoading") { node, _ in
            node.removeFromParent()
        }
    }
    
    // MARK: - Show Recognition Error
    func showRecognitionError(_ message: String) {
        // ✅ Remove existing error label
        enumerateChildNodes(withName: "recognitionError") { node, _ in
            node.removeFromParent()
        }
        
        let errorLabel = SKLabelNode(text: "⚠️ \(message)")
        errorLabel.fontSize = 18
        errorLabel.fontColor = .systemRed
        errorLabel.fontName = "AvenirNext-Medium"
        errorLabel.horizontalAlignmentMode = .center
        errorLabel.position = CGPoint(x: size.width / 2, y: size.height * 0.15)
        errorLabel.zPosition = 100
        errorLabel.name = "recognitionError"
        addChild(errorLabel)
        
        // ✅ Fade out after 3 seconds
        errorLabel.run(SKAction.sequence([
            SKAction.wait(forDuration: 3.0),
            SKAction.fadeOut(withDuration: 0.5),
            SKAction.removeFromParent()
        ]))
    }
    
    // MARK: - Cleanup
    override func willMove(from view: SKView) {
        super.willMove(from: view)
        synthesizer.stopSpeaking(at: .immediate)
        doll1VideoNode?.stop()
        doll2VideoNode?.stop()
        doll1AVPlayer?.pause()
        doll2AVPlayer?.pause()
        
        // ✅ Stop recording if active
        if isRecording {
            stopRecording()
        }
        
        // ✅ Cleanup audio
        audioRecorder?.stop()
        audioPlayer?.stop()
    }
}

// MARK: - Helper Extension
extension String {
    func substring(with range: NSRange) -> String {
        let start = self.index(self.startIndex, offsetBy: range.location)
        let end = self.index(start, offsetBy: range.length)
        return String(self[start..<end])
    }
}
