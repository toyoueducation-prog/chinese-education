import Foundation

// MARK: - 🔄 DATA SYNC MANAGER - Synchronize Data with Alibaba ECS
class DataSyncManager {
    static let shared = DataSyncManager()  // Singleton pattern
    
    private let syncQueue = DispatchQueue(label: "com.chineseeducation.sync", qos: .utility)
    private var isSyncing = false
    private var pendingSyncs: [SyncTask] = []
    
    private init() {}
    
    // MARK: - Sync All Data
    func syncAllData(completion: @escaping (Bool) -> Void) {
        guard !isSyncing else {
            completion(false)
            return
        }
        
        isSyncing = true
        
        let group = DispatchGroup()
        var success = true
        
        // Sync student profile
        group.enter()
        StudentProfile.shared.syncToServer { profileSuccess in
            if !profileSuccess {
                success = false
            }
            group.leave()
        }
        
        // Sync vocabulary
        group.enter()
        VocabularyManager.shared.syncVocabularyToServer { vocabSuccess in
            if !vocabSuccess {
                success = false
            }
            group.leave()
        }
        
        // Sync PIRLS assessment
        group.enter()
        syncPIRLSAssessment { pirlsSuccess in
            if !pirlsSuccess {
                success = false
            }
            group.leave()
        }
        
        group.notify(queue: .main) {
            self.isSyncing = false
            completion(success)
        }
    }
    
    // MARK: - Sync PIRLS Assessment
    func syncPIRLSAssessment(completion: @escaping (Bool) -> Void) {
        guard let url = QuestionBankAPI.pirlsAssessmentURL() else {
            completion(false)
            return
        }
        
        let profile = StudentProfile.shared
        
        // ✅ Convert PIRLSProcess enum keys to strings for JSON
        var processPerformanceDict: [String: [String: Any]] = [:]
        for (process, performance) in profile.pirlsAssessment.processPerformance {
            processPerformanceDict[process.rawValue] = [
                "totalQuestions": performance.totalQuestions,
                "correctAnswers": performance.correctAnswers,
                "averageResponseTime": performance.averageResponseTime,
                "masteryLevel": performance.masteryLevel
            ]
        }
        
        let assessmentData: [String: Any] = [
            "studentID": profile.studentID,
            "assessment": [
                "studentLevel": profile.currentLevel,
                "overallScore": profile.pirlsAssessment.overallScore,
                "vocabularyMastery": profile.vocabularyMastery,
                "processPerformance": processPerformanceDict,  // ✅ Now uses String keys
                "readingPurposePerformance": [
                    "literary": profile.literaryPerformance,
                    "informational": profile.informationalPerformance
                ]
            ],
            "timestamp": Date().timeIntervalSince1970
        ]
        
        guard let jsonData = try? JSONSerialization.data(withJSONObject: assessmentData) else {
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
    
    // MARK: - Batch Sync
    func batchSync(completion: @escaping (Bool) -> Void) {
        syncQueue.async {
            var allSuccess = true
            
            // Sync in batches to avoid overwhelming server
            let profileSuccess = self.syncProfileSync()
            let vocabSuccess = self.syncVocabularySync()
            let assessmentSuccess = self.syncAssessmentSync()
            
            allSuccess = profileSuccess && vocabSuccess && assessmentSuccess
            
            DispatchQueue.main.async {
                completion(allSuccess)
            }
        }
    }
    
    private func syncProfileSync() -> Bool {
        let semaphore = DispatchSemaphore(value: 0)
        var success = false
        
        StudentProfile.shared.syncToServer { result in
            success = result
            semaphore.signal()
        }
        
        semaphore.wait()
        return success
    }
    
    private func syncVocabularySync() -> Bool {
        let semaphore = DispatchSemaphore(value: 0)
        var success = false
        
        VocabularyManager.shared.syncVocabularyToServer { result in
            success = result
            semaphore.signal()
        }
        
        semaphore.wait()
        return success
    }
    
    private func syncAssessmentSync() -> Bool {
        let semaphore = DispatchSemaphore(value: 0)
        var success = false
        
        syncPIRLSAssessment { result in
            success = result
            semaphore.signal()
        }
        
        semaphore.wait()
        return success
    }
    
    // MARK: - Offline Mode Support
    func queueSyncTask(_ task: SyncTask) {
        pendingSyncs.append(task)
    }
    
    func processPendingSyncs() {
        guard !pendingSyncs.isEmpty else { return }
        
        for task in pendingSyncs {
            switch task {
            case .profile:
                StudentProfile.shared.syncToServer { _ in }
            case .vocabulary:
                VocabularyManager.shared.syncVocabularyToServer { _ in }
            case .assessment:
                syncPIRLSAssessment { _ in }
            }
        }
        
        pendingSyncs.removeAll()
    }
}

enum SyncTask {
    case profile
    case vocabulary
    case assessment
}

