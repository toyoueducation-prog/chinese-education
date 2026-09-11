import Foundation

/**
 * STUDENT PROFILE - Comprehensive Student Learning Profile
 * 
 * Tracks and manages all student learning data including:
 * - Basic information (ID, name, current level)
 * - PIRLS performance across all reading processes
 * - Vocabulary mastery and growth
 * - Reading purpose preferences
 * - Performance history over time
 * - Learning strengths and weaknesses
 * 
 * Data Persistence:
 * - Stores profile data in UserDefaults
 * - Automatically saves after updates
 * - Can sync with Alibaba ECS backend
 * 
 * Level System:
 * - Levels 1-6 correspond to Primary 1-6 (ages 6-12)
 * - Level progression based on PIRLS mastery
 * - Adaptive difficulty adjusts based on level
 * 
 * Performance Tracking:
 * - Tracks accuracy rates per PIRLS process
 * - Monitors vocabulary growth
 * - Records performance history
 * - Identifies strongest/weakest areas
 * 
 * Usage:
 * - Access via StudentProfile.shared singleton
 * - Updates automatically when questions are answered
 * - Used for personalized question generation
 * - Powers progress dashboards and reports
 */
// MARK: - 👤 STUDENT PROFILE - Comprehensive Student Learning Profile
class StudentProfile: ObservableObject {
    static let shared = StudentProfile()  // Singleton pattern
    
    // MARK: - 🔑 USER DEFAULTS KEYS
    private let profileKey = "studentProfile"
    
    // MARK: - 📊 BASIC INFORMATION
    @Published var studentID: String
    @Published var currentLevel: Int  // 1-6 (Primary 1-6)
    @Published var studentName: String?
    
    // MARK: - 📈 PIRLS PERFORMANCE
    @Published var pirlsAssessment: PIRLSAssessment
    
    // MARK: - 📖 VOCABULARY TRACKING
    @Published var vocabularyMastery: Double  // 0.0 to 1.0
    @Published var totalVocabularyWords: Int
    @Published var masteredVocabularyWords: Int
    
    // MARK: - 🎯 READING PURPOSE PREFERENCES
    @Published var literaryPerformance: Double  // Accuracy rate for literary texts
    @Published var informationalPerformance: Double  // Accuracy rate for informational texts
    
    // MARK: - 📅 PERFORMANCE HISTORY
    @Published var performanceHistory: [PerformanceRecord]
    
    // MARK: - 🎓 LEARNING PREFERENCES
    @Published var preferredReadingPurpose: ReadingPurpose?
    @Published var strongestProcess: PIRLSProcess?
    @Published var weakestProcess: PIRLSProcess?
    
    // MARK: - Initialization
    private init() {
        // Initialize all stored properties first
        let savedLevel = UserDefaults.standard.integer(forKey: "studentLevel")
        let initialLevel = savedLevel == 0 ? 1 : savedLevel  // Default to Primary 1 if 0
        
        self.studentID = UserDefaults.standard.string(forKey: "studentID") ?? UUID().uuidString
        self.currentLevel = initialLevel
        self.studentName = UserDefaults.standard.string(forKey: "studentName")
        self.pirlsAssessment = PIRLSAssessment(studentLevel: initialLevel)
        self.vocabularyMastery = 0.0
        self.totalVocabularyWords = 0
        self.masteredVocabularyWords = 0
        self.literaryPerformance = 0.0
        self.informationalPerformance = 0.0
        self.performanceHistory = []
        
        // Now we can use self to load profile
        loadProfile()
    }
    
    // MARK: - Load & Save Profile
    private func loadProfile() {
        guard let data = UserDefaults.standard.data(forKey: profileKey),
              let decoded = try? JSONDecoder().decode(StudentProfileData.self, from: data) else {
            return
        }
        
        self.studentID = decoded.studentID
        self.currentLevel = decoded.currentLevel
        self.studentName = decoded.studentName
        self.pirlsAssessment = decoded.pirlsAssessment
        self.vocabularyMastery = decoded.vocabularyMastery
        self.totalVocabularyWords = decoded.totalVocabularyWords
        self.masteredVocabularyWords = decoded.masteredVocabularyWords
        self.literaryPerformance = decoded.literaryPerformance
        self.informationalPerformance = decoded.informationalPerformance
        self.performanceHistory = decoded.performanceHistory
        updateDerivedFields()
    }
    
    func saveProfile() {
        let profileData = StudentProfileData(
            studentID: studentID,
            currentLevel: currentLevel,
            studentName: studentName,
            pirlsAssessment: pirlsAssessment,
            vocabularyMastery: vocabularyMastery,
            totalVocabularyWords: totalVocabularyWords,
            masteredVocabularyWords: masteredVocabularyWords,
            literaryPerformance: literaryPerformance,
            informationalPerformance: informationalPerformance,
            performanceHistory: performanceHistory
        )
        
        if let encoded = try? JSONEncoder().encode(profileData) {
            UserDefaults.standard.set(encoded, forKey: profileKey)
        }
    }
    
    // MARK: - Update Performance
    func updatePerformance(question: Question, isCorrect: Bool, responseTime: TimeInterval, passageText: String) {
        // Update PIRLS process performance
        if let process = question.pirlsProcess {
            if var processPerf = pirlsAssessment.processPerformance[process] {
                processPerf.updatePerformance(isCorrect: isCorrect, responseTime: responseTime)
                pirlsAssessment.processPerformance[process] = processPerf
            }
        }
        
        // Update reading purpose performance
        if let purpose = question.readingPurpose {
            let currentRate = purpose == .literary ? literaryPerformance : informationalPerformance
            let newRate = (currentRate * 0.9) + (isCorrect ? 1.0 : 0.0) * 0.1  // Moving average
            if purpose == .literary {
                literaryPerformance = newRate
            } else {
                informationalPerformance = newRate
            }
        }
        
        // Track vocabulary
        if let vocabularyWords = question.vocabularyWords {
            for word in vocabularyWords {
                VocabularyManager.shared.trackWordEncounter(word, isCorrect: isCorrect, context: passageText)
            }
        }
        
        // Update overall assessment
        pirlsAssessment.updateOverallScore()
        updateDerivedFields()
        
        // Add to performance history
        let record = PerformanceRecord(
            date: Date(),
            questionKey: question.key,
            isCorrect: isCorrect,
            responseTime: responseTime,
            pirlsProcess: question.pirlsProcess,
            readingPurpose: question.readingPurpose
        )
        performanceHistory.append(record)
        
        // Keep only last 100 records
        if performanceHistory.count > 100 {
            performanceHistory.removeFirst()
        }
        
        saveProfile()
    }
    
    // MARK: - Update Vocabulary Stats
    func updateVocabularyStats() {
        let stats = VocabularyManager.shared.getStatistics()
        totalVocabularyWords = stats.totalWords
        masteredVocabularyWords = stats.masteredWords
        vocabularyMastery = stats.masteryRate
        pirlsAssessment.vocabularyMastery = vocabularyMastery
        saveProfile()
    }
    
    // MARK: - Update Derived Fields
    private func updateDerivedFields() {
        strongestProcess = pirlsAssessment.getStrongestProcess()
        weakestProcess = pirlsAssessment.getWeakestProcess()
        preferredReadingPurpose = literaryPerformance > informationalPerformance ? .literary : .informational
    }
    
    // MARK: - Level Progression
    func checkLevelProgression() -> Bool {
        let previousLevel = currentLevel
        
        // Level up based on PIRLS mastery
        if pirlsAssessment.overallScore >= 0.8 && currentLevel < 6 {
            currentLevel += 1
            pirlsAssessment.studentLevel = currentLevel
        } else if pirlsAssessment.overallScore < 0.5 && currentLevel > 1 {
            // Allow level down if struggling
            currentLevel = max(1, currentLevel - 1)
            pirlsAssessment.studentLevel = currentLevel
        }
        
        if currentLevel != previousLevel {
            saveProfile()
            return true
        }
        return false
    }
    
    // MARK: - Sync with Alibaba ECS
    func syncToServer(completion: @escaping (Bool) -> Void) {
        guard let url = QuestionBankAPI.studentProgressURL() else {
            completion(false)
            return
        }
        
        let profileData = StudentProfileData(
            studentID: studentID,
            currentLevel: currentLevel,
            studentName: studentName,
            pirlsAssessment: pirlsAssessment,
            vocabularyMastery: vocabularyMastery,
            totalVocabularyWords: totalVocabularyWords,
            masteredVocabularyWords: masteredVocabularyWords,
            literaryPerformance: literaryPerformance,
            informationalPerformance: informationalPerformance,
            performanceHistory: performanceHistory
        )
        
        guard let jsonData = try? JSONEncoder().encode(profileData) else {
            completion(false)
            return
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = jsonData
        
        URLSession.shared.dataTask(with: request) { data, response, error in
            guard let httpResponse = response as? HTTPURLResponse,
                  httpResponse.statusCode == 200,
                  error == nil else {
                completion(false)
                return
            }
            completion(true)
        }.resume()
    }
}

// MARK: - Performance Record
struct PerformanceRecord: Codable {
    let date: Date
    let questionKey: String
    let isCorrect: Bool
    let responseTime: TimeInterval
    let pirlsProcess: PIRLSProcess?
    let readingPurpose: ReadingPurpose?
}

// MARK: - Student Profile Data (for encoding/decoding)
private struct StudentProfileData: Codable {
    let studentID: String
    let currentLevel: Int
    let studentName: String?
    let pirlsAssessment: PIRLSAssessment
    let vocabularyMastery: Double
    let totalVocabularyWords: Int
    let masteredVocabularyWords: Int
    let literaryPerformance: Double
    let informationalPerformance: Double
    let performanceHistory: [PerformanceRecord]
}

