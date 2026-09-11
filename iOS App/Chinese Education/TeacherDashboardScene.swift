import SpriteKit
#if os(iOS)
import UIKit
#endif

/**
 * TEACHER DASHBOARD SCENE - Class Overview and Student Management
 *
 * **Demo / local mode:** There is no separate teacher password. 「教師登入」only switches to this scene on the same device.
 * The roster is built from `ClassManager` snapshots taken when students sign in and when they finish passages.
 * Per-student word counts are only accurate for the student whose profile is currently loaded on this device (`StudentProfile` is a singleton).
 *
 * Provides teachers with:
 * - Class overview with student list
 * - PIRLS performance metrics (snapshot)
 * - CSV export of roster snapshots
 */
// MARK: - 👨‍🏫 TEACHER DASHBOARD SCENE
class TeacherDashboardScene: SKScene {
    private var backButton: SKLabelNode!
    private var studentCards: [StudentCardNode] = []
    private var classStatsLabel: SKLabelNode!
    private var scrollView: SKNode!
    private var scrollOffset: CGFloat = 0
    
    private var students: [StudentSummary] = []
    private var selectedStudentIndex: Int? = nil  // ✅ Track selected student for detail view
    private var viewMode: ViewMode = .overview  // ✅ Toggle between overview and individual
    private var isInitialized = false  // ✅ Flag to prevent immediate touch handling
    private var isTransitioning = false  // ✅ Flag to prevent multiple transitions
    
    enum ViewMode {
        case overview  // Show all students and class statistics
        case individual(Int)  // Show detailed view for specific student
    }
    
    override func didMove(to view: SKView) {
        // ✅ Professional gradient background
        setupProfessionalBackground()
        
        print("✅ TeacherDashboardScene didMove called")
        print("✅ Scene size: \(size)")
        print("✅ View: \(view)")
        print("✅ Current scene in view: \(view.scene != nil ? String(describing: type(of: view.scene!)) : "nil")")
        print("✅ View scene is self: \(view.scene === self)")
        
        // ✅ CRITICAL: Verify we're actually the active scene
        guard view.scene === self else {
            print("❌ CRITICAL: View's scene is not self! View scene: \(String(describing: view.scene)), Self: \(self)")
            return
        }
        
        // ✅ CRITICAL: Reset initialization flag IMMEDIATELY
        isInitialized = false
        isTransitioning = false  // Reset transition flag
        print("✅ isInitialized set to FALSE - blocking all touches")
        
        // ✅ Remove any existing touches that might be queued
        view.isUserInteractionEnabled = false
        
        // ✅ Wrap setup in do-catch to prevent crashes from causing immediate return
        do {
            loadStudentData()
            setupUI()
            refreshDisplay()  // ✅ Use unified display method
            
            print("✅ TeacherDashboardScene setup complete. Students: \(students.count)")
        } catch {
            print("❌ ERROR in TeacherDashboardScene setup: \(error)")
            // Even if there's an error, still try to show something
            // Don't return immediately - let the scene stay visible
        }
        
        // ✅ Set flag after a delay to prevent immediate touch handling
        // ✅ Longer delay to ensure transition animation completes (0.5s fade + buffer)
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) { [weak self, weak view] in
            guard let self = self, let view = view else {
                print("⚠️ TeacherDashboardScene initialization delayed - self or view deallocated")
                return
            }
            
            // ✅ Double-check that we're still the active scene
            guard view.scene === self else {
                print("⚠️ TeacherDashboardScene initialization delayed - scene changed to: \(String(describing: view.scene))")
                return
            }
            
            self.isInitialized = true
            view.isUserInteractionEnabled = true
            print("✅ TeacherDashboardScene initialized - ready for touches (isInitialized = true)")
        }
    }
    
    // ✅ CRITICAL: Prevent scene from being removed unexpectedly
    override func willMove(from view: SKView) {
        print("⚠️ TeacherDashboardScene willMove called - scene is being removed")
        print("⚠️ This should only happen when back button is tapped")
        super.willMove(from: view)
    }
    
    // MARK: - Load Student Data
    func loadStudentData() {
        let currentProfile = StudentProfile.shared
        currentProfile.updateVocabularyStats()
        let roster = ClassManager.shared.getAllStudents()
        let currentId = currentProfile.studentID
        let liveStats = VocabularyManager.shared.getStatistics()
        
        if roster.isEmpty {
            let vocabMasteryRate: Double
            if liveStats.totalWords > 0 {
                vocabMasteryRate = Double(liveStats.masteredWords) / Double(liveStats.totalWords)
            } else {
                vocabMasteryRate = 0.0
            }
            students = [
                StudentSummary(
                    studentID: currentProfile.studentID,
                    studentName: currentProfile.studentName ?? "當前學生",
                    currentLevel: currentProfile.currentLevel,
                    overallScore: currentProfile.pirlsAssessment.overallScore,
                    vocabularyMastery: vocabMasteryRate,
                    totalVocabularyWords: liveStats.totalWords,
                    masteredVocabularyWords: liveStats.masteredWords
                )
            ]
            return
        }
        
        students = roster.map { row in
            let isCurrent = row.studentID == currentId
            let totalWords = isCurrent ? liveStats.totalWords : -1
            let masteredWords = isCurrent ? liveStats.masteredWords : -1
            return StudentSummary(
                studentID: row.studentID,
                studentName: row.studentName,
                currentLevel: row.currentLevel,
                overallScore: row.overallScore,
                vocabularyMastery: row.vocabularyMastery,
                totalVocabularyWords: totalWords,
                masteredVocabularyWords: masteredWords
            )
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
        let titleLabel = SKLabelNode(text: "教師儀表板")
        titleLabel.fontSize = 28
        titleLabel.fontColor = .black
        titleLabel.fontName = "AvenirNext-Bold"
        titleLabel.position = CGPoint(x: size.width / 2, y: size.height - 50)
        titleLabel.zPosition = 100
        addChild(titleLabel)
        
        #if os(iOS)
        let exportSize = CGSize(width: 118, height: 40)
        let exportBg = SKShapeNode(rectOf: exportSize, cornerRadius: 8)
        exportBg.fillColor = UIColor.systemGreen.withAlphaComponent(0.9)
        exportBg.strokeColor = UIColor.systemGreen
        exportBg.lineWidth = 1
        exportBg.position = CGPoint(x: size.width - 200, y: size.height - 50)
        exportBg.name = "exportCSV"
        exportBg.zPosition = 100
        addChild(exportBg)
        let exportLabel = SKLabelNode(text: "匯出名單")
        exportLabel.fontSize = 15
        exportLabel.fontColor = .white
        exportLabel.fontName = "AvenirNext-Bold"
        exportLabel.position = exportBg.position
        exportLabel.name = "exportCSV"
        exportLabel.zPosition = 101
        addChild(exportLabel)
        
        let ansBg = SKShapeNode(rectOf: exportSize, cornerRadius: 8)
        ansBg.fillColor = UIColor.systemTeal.withAlphaComponent(0.95)
        ansBg.strokeColor = UIColor.systemTeal
        ansBg.lineWidth = 1
        ansBg.position = CGPoint(x: size.width - 70, y: size.height - 50)
        ansBg.name = "exportAnswerLog"
        ansBg.zPosition = 100
        addChild(ansBg)
        let ansLabel = SKLabelNode(text: "匯出作答")
        ansLabel.fontSize = 15
        ansLabel.fontColor = .white
        ansLabel.fontName = "AvenirNext-Bold"
        ansLabel.position = ansBg.position
        ansLabel.name = "exportAnswerLog"
        ansLabel.zPosition = 101
        addChild(ansLabel)
        #endif
    }
    
    // MARK: - Refresh Display (Unified)
    func refreshDisplay() {
        // ✅ Clear existing display elements
        enumerateChildNodes(withName: "classOverview") { node, _ in
            node.removeFromParent()
        }
        enumerateChildNodes(withName: "studentDetail") { node, _ in
            node.removeFromParent()
        }
        
        switch viewMode {
        case .overview:
            displayClassOverview()
            displayStudentList()
        case .individual(let index):
            if index < students.count {
                displayIndividualStudent(students[index])
            }
        }
    }
    
    // MARK: - Display Class Overview
    func displayClassOverview() {
        let analytics = PIRLSAnalytics.shared
        
        // Calculate class averages (for multiple students)
        var totalScore: Double = 0
        var totalVocab: Double = 0
        for student in students {
            totalScore += student.overallScore
            totalVocab += student.vocabularyMastery
        }
        let avgScore = students.isEmpty ? 0.0 : totalScore / Double(students.count)
        let avgVocab = students.isEmpty ? 0.0 : totalVocab / Double(students.count)
        
        // ✅ Calculate comprehensive class statistics
        let vocabStats = VocabularyManager.shared.getStatistics()
        var totalVocabWords = 0
        var totalMasteredWords = 0
        var processScores: [PIRLSProcess: [Double]] = [:]
        
        for student in students {
            totalVocabWords += student.totalVocabularyWords
            totalMasteredWords += student.masteredVocabularyWords
            
            // Get process scores from StudentProfile (if available)
            let profile = StudentProfile.shared
            for process in PIRLSProcess.allCases {
                if processScores[process] == nil {
                    processScores[process] = []
                }
                if let perf = profile.pirlsAssessment.processPerformance[process] {
                    processScores[process]?.append(perf.masteryLevel)
                }
            }
        }
        
        let avgVocabWords = students.isEmpty ? 0 : totalVocabWords / students.count
        let avgMasteredWords = students.isEmpty ? 0 : totalMasteredWords / students.count
        
        // Class statistics with more details
        let statsText = """
        學生總數: \(students.count)
        平均PIRLS分數: \(Int(avgScore * 100))%
        平均詞彙掌握率: \(Int(avgVocab * 100))%
        平均詞彙數: \(avgVocabWords)
        平均已掌握詞彙: \(avgMasteredWords)
        """
        
        // ✅ Remove existing stats label if present
        classStatsLabel?.removeFromParent()
        
        classStatsLabel = SKLabelNode(text: statsText)
        classStatsLabel.fontSize = 16
        classStatsLabel.fontColor = .black
        classStatsLabel.numberOfLines = 0
        classStatsLabel.verticalAlignmentMode = .top
        classStatsLabel.horizontalAlignmentMode = .left
        classStatsLabel.position = CGPoint(x: 50, y: size.height - 120)
        classStatsLabel.zPosition = 10
        classStatsLabel.name = "classOverview"
        addChild(classStatsLabel)
        
        // PIRLS Process Averages
        let processTitle = SKLabelNode(text: "PIRLS 過程平均分數")
        processTitle.fontSize = 20
        processTitle.fontColor = .black  // Use explicit color
        processTitle.position = CGPoint(x: size.width / 2, y: size.height - 200)
        processTitle.zPosition = 10
        addChild(processTitle)
        
        var yOffset: CGFloat = 30
        for process in PIRLSProcess.allCases {
            // ✅ Calculate average for this process using actual process scores
            var processTotal: Double = 0
            var processCount = 0
            
            // Try to get actual process scores from StudentProfile
            let profile = StudentProfile.shared
            if let perf = profile.pirlsAssessment.processPerformance[process] {
                processTotal += perf.masteryLevel
                processCount += 1
            }
            
            // If we have process scores from multiple students, use them
            if let scores = processScores[process], !scores.isEmpty {
                processTotal = scores.reduce(0, +)
                processCount = scores.count
            }
            
            // Fallback to overall score if no process data
            if processCount == 0 {
                for student in students {
                    processTotal += student.overallScore
                    processCount += 1
                }
            }
            
            let processAvg = processCount > 0 ? processTotal / Double(processCount) : 0.0
            
            let processLabel = SKLabelNode(text: "\(process.displayName): \(Int(processAvg * 100))%")
            processLabel.fontSize = 16
            processLabel.fontColor = .black
            processLabel.horizontalAlignmentMode = .left
            processLabel.position = CGPoint(x: 50, y: size.height - 200 - yOffset)
            processLabel.zPosition = 10
            processLabel.name = "classOverview"
            addChild(processLabel)
            
            // Progress bar
            let barWidth: CGFloat = size.width - 100
            let barHeight: CGFloat = 15
            let progressBar = SKShapeNode(rectOf: CGSize(width: barWidth, height: barHeight))
            progressBar.fillColor = .systemGray5
            progressBar.strokeColor = .systemGray
            progressBar.position = CGPoint(x: size.width / 2, y: size.height - 200 - yOffset - 12)
            progressBar.name = "classOverview"
            addChild(progressBar)
            
            let filledBar = SKShapeNode(rectOf: CGSize(width: barWidth * CGFloat(processAvg), height: barHeight))
            filledBar.fillColor = processAvg >= 0.7 ? .systemGreen : (processAvg >= 0.5 ? .systemYellow : .systemRed)
            filledBar.strokeColor = .clear
            filledBar.position = CGPoint(x: 50 + (barWidth * CGFloat(processAvg)) / 2, y: size.height - 200 - yOffset - 12)
            filledBar.name = "classOverview"
            addChild(filledBar)
            
            yOffset += 35
        }
    }
    
    // MARK: - Display Student List
    func displayStudentList() {
        // ✅ Remove existing student cards
        for card in studentCards {
            card.removeFromParent()
        }
        studentCards.removeAll()
        
        let listStartY = size.height - 450
        var currentY = listStartY
        
        let listTitle = SKLabelNode(text: "學生列表 (點擊查看詳情)")
        listTitle.fontSize = 22
        listTitle.fontColor = .black
        listTitle.fontName = "AvenirNext-Bold"
        listTitle.position = CGPoint(x: size.width / 2, y: currentY)
        listTitle.zPosition = 10
        listTitle.name = "classOverview"
        addChild(listTitle)
        
        currentY -= 40
        
        for (index, student) in students.enumerated() {
            if currentY < 100 { break }  // Stop if below screen
            
            let card = createStudentCard(student: student, index: index)
            card.position = CGPoint(x: size.width / 2, y: currentY)
            card.name = "studentCard_\(index)"
            card.zPosition = 10
            addChild(card)
            studentCards.append(card)
            
            currentY -= 100
        }
    }
    
    // MARK: - Create Student Card
    func createStudentCard(student: StudentSummary, index: Int) -> StudentCardNode {
        let card = StudentCardNode(size: CGSize(width: size.width - 40, height: 90))
        card.setupCard(student: student)
        return card
    }
    
    // MARK: - Handle Touches
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        // ✅ CRITICAL: Ignore ALL touches until scene is fully initialized
        // ✅ This prevents any accidental touches during transition animation
        guard isInitialized else {
            print("⚠️ Touch ignored - scene not yet initialized (isInitialized = \(isInitialized))")
            return
        }
        
        guard let touch = touches.first else { return }
        let location = touch.location(in: self)
        let touchedNode = atPoint(location)
        
        print("🔍 TeacherDashboardScene touch detected at: \(location), node: \(touchedNode.name ?? "nil")")
        
        // ✅ Only handle visual feedback on touch begin, not transitions
        if touchedNode.name == "backButton" {
            // Highlight back button
            if let background = touchedNode as? SKShapeNode {
                background.fillColor = UIColor.white.withAlphaComponent(0.7)
            } else if let label = touchedNode as? SKLabelNode {
                label.fontColor = .systemBlue.withAlphaComponent(0.7)
            }
        }
    }
    
    // ✅ CRITICAL: Override to prevent any touches during transition
    override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) {
        // Ignore touches during initialization
        guard isInitialized else { return }
        super.touchesMoved(touches, with: event)
    }
    
    // ✅ CRITICAL: Override to prevent any touches during transition
    override func touchesCancelled(_ touches: Set<UITouch>, with event: UIEvent?) {
        // Ignore touches during initialization
        guard isInitialized else { return }
        super.touchesCancelled(touches, with: event)
    }
    
    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        // ✅ Ignore touches until scene is fully initialized
        guard isInitialized else {
            print("⚠️ Touch ignored - scene not yet initialized")
            return
        }
        
        guard let touch = touches.first else { return }
        let location = touch.location(in: self)
        let touchedNode = atPoint(location)
        
        // ✅ Restore button color
        enumerateChildNodes(withName: "backButton") { node, _ in
            if let background = node as? SKShapeNode {
                background.fillColor = UIColor.white.withAlphaComponent(0.9)
            } else if let label = node as? SKLabelNode {
                label.fontColor = .systemBlue
            }
        }
        
        // ✅ Handle actions on touch end
        if touchedNode.name == "backButton" {
            // ✅ Prevent multiple transitions
            guard !isTransitioning else {
                print("⚠️ Transition already in progress, ignoring")
                return
            }
            
            print("✅ Back button tapped, returning to login")
            isTransitioning = true
            
            // ✅ Ensure view exists before transitioning
            guard let view = self.view else {
                print("❌ Cannot transition back - view is nil")
                isTransitioning = false
                return
            }
            
            // ✅ Use NotificationCenter to notify SwiftUI to hide teacher dashboard
            // This avoids conflicts with SwiftUI's view lifecycle
            NotificationCenter.default.post(name: NSNotification.Name("HideTeacherDashboard"), object: nil)
            
            print("✅ Transition to SignInScene initiated via notification")
        } else if let nodeName = touchedNode.name, nodeName.hasPrefix("studentCard_") {
            // ✅ Switch to individual student view
            let indexStr = String(nodeName.dropFirst(12))
            if let index = Int(indexStr), index < students.count {
                selectedStudentIndex = index
                viewMode = .individual(index)
                refreshDisplay()
            }
        } else if touchedNode.name == "backToOverview" {
            // ✅ Return to overview
            viewMode = .overview
            selectedStudentIndex = nil
            refreshDisplay()
        } else if touchedNode.name == "exportCSV" || touchedNode.parent?.name == "exportCSV" {
            presentClassCSVExport()
        } else if touchedNode.name == "exportAnswerLog" || touchedNode.parent?.name == "exportAnswerLog" {
            presentAnswerHistoryCSVExport()
        } else {
            // Ignore other touches - don't transition
            print("ℹ️ Touch ignored (not back button or student card)")
        }
    }
    
    #if os(iOS)
    private func presentClassCSVExport() {
        var lines = ["studentID,studentName,primaryLevel,overallScore,vocabularyMastery"]
        for s in students {
            let safeName = s.studentName.replacingOccurrences(of: ",", with: " ").replacingOccurrences(of: "\n", with: " ")
            lines.append("\(s.studentID),\(safeName),\(s.currentLevel),\(s.overallScore),\(s.vocabularyMastery)")
        }
        let csv = lines.joined(separator: "\n")
        let fileName = "class_roster_\(Int(Date().timeIntervalSince1970)).csv"
        let tmp = FileManager.default.temporaryDirectory.appendingPathComponent(fileName)
        guard let data = csv.data(using: .utf8) else { return }
        do {
            try data.write(to: tmp)
        } catch {
            print("❌ CSV write failed: \(error)")
            return
        }
        guard let rootVC = view?.window?.rootViewController else {
            print("❌ No root view controller for export")
            return
        }
        let activity = UIActivityViewController(activityItems: [tmp], applicationActivities: nil)
        if let pop = activity.popoverPresentationController, let skView = view {
            pop.sourceView = skView
            pop.sourceRect = CGRect(x: skView.bounds.maxX - 8, y: 72, width: 1, height: 1)
        }
        rootVC.present(activity, animated: true)
    }
    
    private func presentAnswerHistoryCSVExport() {
        let csv = AnswerHistoryStore.shared.buildCSV()
        let fileName = "answer_history_\(Int(Date().timeIntervalSince1970)).csv"
        let tmp = FileManager.default.temporaryDirectory.appendingPathComponent(fileName)
        guard let data = csv.data(using: .utf8) else { return }
        do {
            try data.write(to: tmp)
        } catch {
            print("❌ Answer CSV write failed: \(error)")
            return
        }
        guard let rootVC = view?.window?.rootViewController else { return }
        let activity = UIActivityViewController(activityItems: [tmp], applicationActivities: nil)
        if let pop = activity.popoverPresentationController, let skView = view {
            pop.sourceView = skView
            pop.sourceRect = CGRect(x: skView.bounds.maxX - 8, y: 72, width: 1, height: 1)
        }
        rootVC.present(activity, animated: true)
    }
    #endif
    
    // MARK: - Display Individual Student Detail
    func displayIndividualStudent(_ student: StudentSummary) {
        var currentY = size.height - 120
        
        // ✅ Back to overview button
        let backToOverviewButton = SKShapeNode(rectOf: CGSize(width: 120, height: 40), cornerRadius: 8)
        backToOverviewButton.fillColor = UIColor.white.withAlphaComponent(0.9)
        backToOverviewButton.strokeColor = UIColor.systemGray4
        backToOverviewButton.lineWidth = 1
        backToOverviewButton.position = CGPoint(x: 70, y: currentY)
        backToOverviewButton.name = "backToOverview"
        backToOverviewButton.zPosition = 10
        addChild(backToOverviewButton)
        
        let backLabel = SKLabelNode(text: "← 返回列表")
        backLabel.fontSize = 16
        backLabel.fontColor = .systemBlue
        backLabel.fontName = "AvenirNext-Medium"
        backLabel.position = backToOverviewButton.position
        backLabel.name = "backToOverview"
        backLabel.zPosition = 11
        addChild(backLabel)
        
        currentY -= 60
        
        // ✅ Student name header
        let nameHeader = SKLabelNode(text: student.studentName)
        nameHeader.fontSize = 32
        nameHeader.fontColor = .black
        nameHeader.fontName = "AvenirNext-Bold"
        nameHeader.position = CGPoint(x: size.width / 2, y: currentY)
        nameHeader.zPosition = 10
        nameHeader.name = "studentDetail"
        addChild(nameHeader)
        
        currentY -= 50
        
        // ✅ Level and basic info
        let levelInfo = SKLabelNode(text: "小學 \(student.currentLevel) 年級 | 學生ID: \(student.studentID)")
        levelInfo.fontSize = 18
        levelInfo.fontColor = .darkGray
        levelInfo.position = CGPoint(x: size.width / 2, y: currentY)
        levelInfo.zPosition = 10
        levelInfo.name = "studentDetail"
        addChild(levelInfo)
        
        currentY -= 60
        
        // ✅ Overall PIRLS Score
        let scoreTitle = SKLabelNode(text: "整體PIRLS分數")
        scoreTitle.fontSize = 22
        scoreTitle.fontColor = .black
        scoreTitle.fontName = "AvenirNext-Bold"
        scoreTitle.horizontalAlignmentMode = .left
        scoreTitle.position = CGPoint(x: 50, y: currentY)
        scoreTitle.zPosition = 10
        scoreTitle.name = "studentDetail"
        addChild(scoreTitle)
        
        currentY -= 35
        
        let scoreValue = SKLabelNode(text: "\(Int(student.overallScore * 100))%")
        scoreValue.fontSize = 36
        scoreValue.fontColor = student.overallScore >= 0.7 ? .systemGreen : (student.overallScore >= 0.5 ? .systemYellow : .systemRed)
        scoreValue.fontName = "AvenirNext-Bold"
        scoreValue.horizontalAlignmentMode = .left
        scoreValue.position = CGPoint(x: 50, y: currentY)
        scoreValue.zPosition = 10
        scoreValue.name = "studentDetail"
        addChild(scoreValue)
        
        // Progress bar for overall score
        let scoreBarWidth: CGFloat = size.width - 100
        let scoreBarHeight: CGFloat = 20
        let scoreBarBg = SKShapeNode(rectOf: CGSize(width: scoreBarWidth, height: scoreBarHeight))
        scoreBarBg.fillColor = .systemGray5
        scoreBarBg.strokeColor = .systemGray
        scoreBarBg.position = CGPoint(x: size.width / 2, y: currentY - 25)
        scoreBarBg.zPosition = 10
        scoreBarBg.name = "studentDetail"
        addChild(scoreBarBg)
        
        let scoreBarFill = SKShapeNode(rectOf: CGSize(width: scoreBarWidth * CGFloat(student.overallScore), height: scoreBarHeight))
        scoreBarFill.fillColor = student.overallScore >= 0.7 ? .systemGreen : (student.overallScore >= 0.5 ? .systemYellow : .systemRed)
        scoreBarFill.strokeColor = .clear
        scoreBarFill.position = CGPoint(x: 50 + (scoreBarWidth * CGFloat(student.overallScore)) / 2, y: currentY - 25)
        scoreBarFill.zPosition = 11
        scoreBarFill.name = "studentDetail"
        addChild(scoreBarFill)
        
        currentY -= 80
        
        // ✅ Vocabulary Statistics
        let vocabTitle = SKLabelNode(text: "詞彙掌握情況")
        vocabTitle.fontSize = 22
        vocabTitle.fontColor = .black
        vocabTitle.fontName = "AvenirNext-Bold"
        vocabTitle.horizontalAlignmentMode = .left
        vocabTitle.position = CGPoint(x: 50, y: currentY)
        vocabTitle.zPosition = 10
        vocabTitle.name = "studentDetail"
        addChild(vocabTitle)
        
        currentY -= 30
        
        let vocabStatsText: String
        if student.totalVocabularyWords < 0 {
            vocabStatsText = """
            掌握率: \(Int(student.vocabularyMastery * 100))%（上次登入快照）
            詳細詞彙筆數僅在目前登入學生的裝置「詞彙」頁可查。
            """
        } else {
            vocabStatsText = """
            掌握率: \(Int(student.vocabularyMastery * 100))%
            總詞彙數: \(student.totalVocabularyWords)
            已掌握: \(student.masteredVocabularyWords)
            """
        }
        let vocabStatsLabel = SKLabelNode(text: vocabStatsText)
        vocabStatsLabel.fontSize = 18
        vocabStatsLabel.fontColor = .black
        vocabStatsLabel.horizontalAlignmentMode = .left
        vocabStatsLabel.verticalAlignmentMode = .top
        vocabStatsLabel.numberOfLines = 0
        vocabStatsLabel.position = CGPoint(x: 50, y: currentY)
        vocabStatsLabel.zPosition = 10
        vocabStatsLabel.name = "studentDetail"
        addChild(vocabStatsLabel)
        
        currentY -= 100
        
        // ✅ PIRLS Process Breakdown
        let processTitle = SKLabelNode(text: "PIRLS 過程分數")
        processTitle.fontSize = 22
        processTitle.fontColor = .black
        processTitle.fontName = "AvenirNext-Bold"
        processTitle.horizontalAlignmentMode = .left
        processTitle.position = CGPoint(x: 50, y: currentY)
        processTitle.zPosition = 10
        processTitle.name = "studentDetail"
        addChild(processTitle)
        
        currentY -= 40
        
        // Get actual process scores from StudentProfile
        let profile = StudentProfile.shared
        var processYOffset: CGFloat = 0
        for process in PIRLSProcess.allCases {
            if let perf = profile.pirlsAssessment.processPerformance[process] {
                let processScore = perf.masteryLevel
                
                let processLabel = SKLabelNode(text: "\(process.displayName): \(Int(processScore * 100))%")
                processLabel.fontSize = 16
                processLabel.fontColor = .black
                processLabel.horizontalAlignmentMode = .left
                processLabel.position = CGPoint(x: 50, y: currentY - processYOffset)
                processLabel.zPosition = 10
                processLabel.name = "studentDetail"
                addChild(processLabel)
                
                // Progress bar
                let barWidth: CGFloat = size.width - 100
                let barHeight: CGFloat = 15
                let barBg = SKShapeNode(rectOf: CGSize(width: barWidth, height: barHeight))
                barBg.fillColor = .systemGray5
                barBg.strokeColor = .systemGray
                barBg.position = CGPoint(x: size.width / 2, y: currentY - processYOffset - 12)
                barBg.zPosition = 10
                barBg.name = "studentDetail"
                addChild(barBg)
                
                let barFill = SKShapeNode(rectOf: CGSize(width: barWidth * CGFloat(processScore), height: barHeight))
                barFill.fillColor = processScore >= 0.7 ? .systemGreen : (processScore >= 0.5 ? .systemYellow : .systemRed)
                barFill.strokeColor = .clear
                barFill.position = CGPoint(x: 50 + (barWidth * CGFloat(processScore)) / 2, y: currentY - processYOffset - 12)
                barFill.zPosition = 11
                barFill.name = "studentDetail"
                addChild(barFill)
                
                processYOffset += 35
            }
        }
    }
    
    // MARK: - Open Student Report
    func openStudentReport(_ student: StudentSummary) {
        // Generate and show report for this student
        ReportGenerator.shared.generatePDFReport { url in
            if let url = url {
                // In a real app, you might show a preview or share sheet
                print("✅ Generated report for \(student.studentName) at \(url)")
            }
        }
    }
}

// MARK: - Student Card Node
class StudentCardNode: SKNode {
    private var cardBackground: SKShapeNode!
    private var nameLabel: SKLabelNode!
    private var scoreLabel: SKLabelNode!
    private var levelLabel: SKLabelNode!
    private var cardSize: CGSize!
    
    init(size: CGSize) {
        super.init()
        self.cardSize = size
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func setupCard(student: StudentSummary) {
        // Background (make it more interactive and clickable)
        cardBackground = SKShapeNode(rectOf: cardSize, cornerRadius: 10)
        cardBackground.fillColor = UIColor.white.withAlphaComponent(0.95)
        cardBackground.strokeColor = .systemBlue
        cardBackground.lineWidth = 2
        addChild(cardBackground)
        
        // Student name
        nameLabel = SKLabelNode(text: student.studentName)
        nameLabel.fontSize = 20
        nameLabel.fontColor = .black  // Use explicit color
        nameLabel.horizontalAlignmentMode = .left
        nameLabel.position = CGPoint(x: -cardSize.width / 2 + 20, y: 20)
        nameLabel.zPosition = 1
        addChild(nameLabel)
        
        // ✅ Student ID (shown in overview)
        let idLabel = SKLabelNode(text: "ID: \(student.studentID)")
        idLabel.fontSize = 14
        idLabel.fontColor = .systemGray
        idLabel.horizontalAlignmentMode = .left
        idLabel.position = CGPoint(x: -cardSize.width / 2 + 20, y: 0)
        idLabel.zPosition = 1
        addChild(idLabel)
        
        // Level
        levelLabel = SKLabelNode(text: "小學 \(student.currentLevel) 年級")
        levelLabel.fontSize = 16
        levelLabel.fontColor = .darkGray  // Use explicit color
        levelLabel.horizontalAlignmentMode = .left
        levelLabel.position = CGPoint(x: -cardSize.width / 2 + 20, y: -20)
        levelLabel.zPosition = 1
        addChild(levelLabel)
        
        // Overall score (進度)
        scoreLabel = SKLabelNode(text: "進度: \(Int(student.overallScore * 100))%")
        scoreLabel.fontSize = 18
        scoreLabel.fontColor = student.overallScore >= 0.7 ? .systemGreen : (student.overallScore >= 0.5 ? .systemYellow : .systemRed)
        scoreLabel.horizontalAlignmentMode = .right
        scoreLabel.position = CGPoint(x: cardSize.width / 2 - 20, y: 10)
        addChild(scoreLabel)
        
        let vocabLine: String
        if student.totalVocabularyWords < 0 {
            vocabLine = "生字掌握: \(Int(student.vocabularyMastery * 100))%（快照）"
        } else {
            vocabLine = "生字掌握: \(Int(student.vocabularyMastery * 100))% (\(student.masteredVocabularyWords)/\(student.totalVocabularyWords))"
        }
        let vocabLabel = SKLabelNode(text: vocabLine)
        vocabLabel.fontSize = 16
        vocabLabel.fontColor = student.vocabularyMastery >= 0.7 ? .systemOrange : (student.vocabularyMastery >= 0.5 ? .systemYellow : .systemRed)
        vocabLabel.horizontalAlignmentMode = .right
        vocabLabel.position = CGPoint(x: cardSize.width / 2 - 20, y: -15)
        addChild(vocabLabel)
    }
}

// MARK: - Student Summary Data Structure
struct StudentSummary {
    let studentID: String
    let studentName: String
    let currentLevel: Int
    let overallScore: Double
    let vocabularyMastery: Double
    let totalVocabularyWords: Int
    let masteredVocabularyWords: Int
}

