import Foundation

// MARK: - 🎯 DIFFICULTY MANAGER - Adaptive Difficulty Adjustment System
class DifficultyManager {
    static let shared = DifficultyManager()  // Singleton pattern
    
    private init() {}
    
    // MARK: - Calculate Optimal Difficulty
    func calculateOptimalDifficulty(for studentProfile: StudentProfile) -> Int {
        let currentLevel = studentProfile.currentLevel
        let overallScore = studentProfile.pirlsAssessment.overallScore
        
        // Base difficulty on current level
        var optimalDifficulty = currentLevel
        
        // Adjust based on overall performance
        if overallScore >= 0.9 {
            // Excellent performance - increase difficulty
            optimalDifficulty = min(6, currentLevel + 1)
        } else if overallScore >= 0.7 {
            // Good performance - maintain or slightly increase
            optimalDifficulty = currentLevel
        } else if overallScore >= 0.5 {
            // Average performance - maintain
            optimalDifficulty = currentLevel
        } else {
            // Below average - decrease difficulty
            optimalDifficulty = max(1, currentLevel - 1)
        }
        
        // Fine-tune based on weakest process
        if let weakest = studentProfile.weakestProcess,
           let processPerf = studentProfile.pirlsAssessment.processPerformance[weakest],
           processPerf.masteryLevel < 0.4 {
            // If weakest process is very weak, reduce difficulty
            optimalDifficulty = max(1, optimalDifficulty - 1)
        }
        
        return optimalDifficulty
    }
    
    // MARK: - Adjust Difficulty Based on Performance
    func adjustDifficulty(currentDifficulty: Int, isCorrect: Bool, responseTime: TimeInterval, pirlsProcess: PIRLSProcess?) -> Int {
        var newDifficulty = currentDifficulty
        
        // Adjust based on correctness
        if isCorrect {
            // Correct answer - consider increasing difficulty
            if responseTime < 15.0 {
                // Fast and correct - increase difficulty
                newDifficulty = min(6, currentDifficulty + 1)
            } else if responseTime < 25.0 {
                // Moderate speed - maintain
                newDifficulty = currentDifficulty
            } else {
                // Slow but correct - maintain or slightly decrease
                newDifficulty = max(1, currentDifficulty - 1)
            }
        } else {
            // Incorrect answer - decrease difficulty
            if responseTime < 10.0 {
                // Fast but wrong - might be guessing, decrease more
                newDifficulty = max(1, currentDifficulty - 2)
            } else {
                // Wrong answer - decrease difficulty
                newDifficulty = max(1, currentDifficulty - 1)
            }
        }
        
        return newDifficulty
    }
    
    // MARK: - Select Questions by Difficulty
    func selectQuestionsByDifficulty(_ questions: [Question], targetDifficulty: Int, count: Int = 4) -> [Question] {
        // Filter questions by difficulty level
        let difficultyFiltered = questions.filter { question in
            if let difficulty = question.difficultyLevel {
                return abs(difficulty - targetDifficulty) <= 1  // Allow ±1 level
            }
            return false
        }
        
        // If not enough questions, expand range
        if difficultyFiltered.count < count {
            let expanded = questions.filter { question in
                if let difficulty = question.difficultyLevel {
                    return abs(difficulty - targetDifficulty) <= 2  // Allow ±2 levels
                }
                return false
            }
            return Array(expanded.prefix(count))
        }
        
        // Return requested count
        return Array(difficultyFiltered.prefix(count))
    }
    
    // MARK: - Balance Question Types
    func balanceQuestionTypes(_ questions: [Question], targetProcesses: [PIRLSProcess]? = nil) -> [Question] {
        var balanced: [Question] = []
        var processCounts: [PIRLSProcess: Int] = [:]
        
        // Initialize counts
        for process in PIRLSProcess.allCases {
            processCounts[process] = 0
        }
        
        // Target processes (default to all if not specified)
        let targetProcessesList = targetProcesses ?? PIRLSProcess.allCases
        
        // Shuffle questions for randomness
        let shuffled = questions.shuffled()
        
        for question in shuffled {
            if let process = question.pirlsProcess, targetProcessesList.contains(process) {
                // Check if we need more of this process type
                let currentCount = processCounts[process] ?? 0
                let targetCount = questions.count / targetProcessesList.count
                
                if currentCount < targetCount || balanced.count < questions.count {
                    balanced.append(question)
                    processCounts[process] = currentCount + 1
                }
            }
        }
        
        // Fill remaining slots
        if balanced.count < questions.count {
            for question in shuffled {
                if !balanced.contains(where: { $0.key == question.key }) {
                    balanced.append(question)
                    if balanced.count >= questions.count {
                        break
                    }
                }
            }
        }
        
        return balanced
    }
    
    // MARK: - Sync Difficulty with Alibaba ECS
    func syncDifficultyToServer(studentID: String, currentDifficulty: Int, performance: [String: Any], completion: @escaping (Int?) -> Void) {
        guard let url = QuestionBankAPI.updateDifficultyURL() else {
            completion(nil)
            return
        }
        
        let requestData: [String: Any] = [
            "studentID": studentID,
            "currentDifficulty": currentDifficulty,
            "performance": performance,
            "timestamp": Date().timeIntervalSince1970
        ]
        
        guard let jsonData = try? JSONSerialization.data(withJSONObject: requestData) else {
            completion(nil)
            return
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = jsonData
        
        URLSession.shared.dataTask(with: request) { data, response, error in
            guard let data = data,
                  let httpResponse = response as? HTTPURLResponse,
                  httpResponse.statusCode == 200,
                  error == nil,
                  let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
                  let recommendedDifficulty = json["recommendedDifficulty"] as? Int else {
                completion(nil)
                return
            }
            completion(recommendedDifficulty)
        }.resume()
    }
}

