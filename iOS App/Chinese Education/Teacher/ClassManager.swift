import Foundation

/**
 * CLASS MANAGER - Student Roster and Group Management
 * 
 * Manages:
 * - Student roster
 * - Group creation for differentiated instruction
 * - Assignment scheduling
 * - Progress monitoring per group
 * - Parent communication templates
 */
// MARK: - 👥 CLASS MANAGER
class ClassManager {
    static let shared = ClassManager()
    
    // MARK: - Storage Keys
    private let studentsKey = "classStudents"
    private let groupsKey = "classGroups"
    private let assignmentsKey = "classAssignments"
    
    // MARK: - Data Storage
    private var students: [ClassStudent] = []
    private var groups: [StudentGroup] = []
    private var assignments: [Assignment] = []
    
    private init() {
        loadData()
    }
    
    // MARK: - Student Roster Management
    func addStudent(_ student: ClassStudent) {
        if !students.contains(where: { $0.studentID == student.studentID }) {
            students.append(student)
            saveData()
        }
    }
    
    func removeStudent(studentID: String) {
        students.removeAll { $0.studentID == studentID }
        // Remove from all groups
        for group in groups {
            group.studentIDs.removeAll { $0 == studentID }
        }
        saveData()
    }
    
    func getAllStudents() -> [ClassStudent] {
        return students
    }
    
    func getStudent(studentID: String) -> ClassStudent? {
        return students.first { $0.studentID == studentID }
    }
    
    // MARK: - Group Management
    func createGroup(name: String, studentIDs: [String], description: String? = nil) -> StudentGroup {
        let group = StudentGroup(
            id: UUID().uuidString,
            name: name,
            studentIDs: studentIDs,
            description: description,
            createdAt: Date()
        )
        groups.append(group)
        saveData()
        return group
    }
    
    func deleteGroup(groupID: String) {
        groups.removeAll { $0.id == groupID }
        saveData()
    }
    
    func getAllGroups() -> [StudentGroup] {
        return groups
    }
    
    func getGroup(groupID: String) -> StudentGroup? {
        return groups.first { $0.id == groupID }
    }
    
    func addStudentToGroup(studentID: String, groupID: String) {
        if let groupIndex = groups.firstIndex(where: { $0.id == groupID }) {
            if !groups[groupIndex].studentIDs.contains(studentID) {
                groups[groupIndex].studentIDs.append(studentID)
                saveData()
            }
        }
    }
    
    func removeStudentFromGroup(studentID: String, groupID: String) {
        if let groupIndex = groups.firstIndex(where: { $0.id == groupID }) {
            groups[groupIndex].studentIDs.removeAll { $0 == studentID }
            saveData()
        }
    }
    
    // MARK: - Assignment Management
    func createAssignment(_ assignment: Assignment) {
        assignments.append(assignment)
        saveData()
    }
    
    func updateAssignment(_ assignment: Assignment) {
        if let index = assignments.firstIndex(where: { $0.id == assignment.id }) {
            assignments[index] = assignment
            saveData()
        }
    }
    
    func deleteAssignment(assignmentID: String) {
        assignments.removeAll { $0.id == assignmentID }
        saveData()
    }
    
    func getAssignments(forStudentID studentID: String) -> [Assignment] {
        return assignments.filter { $0.assignedStudentIDs.contains(studentID) }
    }
    
    func getAssignments(forGroupID groupID: String) -> [Assignment] {
        guard let group = getGroup(groupID: groupID) else { return [] }
        return assignments.filter { assignment in
            group.studentIDs.contains { assignment.assignedStudentIDs.contains($0) }
        }
    }
    
    func getAllAssignments() -> [Assignment] {
        return assignments
    }
    
    // MARK: - Progress Monitoring
    func getGroupProgress(groupID: String) -> GroupProgress? {
        guard let group = getGroup(groupID: groupID) else { return nil }
        
        var totalScore: Double = 0
        var totalVocab: Double = 0
        var studentCount = 0
        
        for studentID in group.studentIDs {
            if let student = getStudent(studentID: studentID) {
                totalScore += student.overallScore
                totalVocab += student.vocabularyMastery
                studentCount += 1
            }
        }
        
        guard studentCount > 0 else { return nil }
        
        return GroupProgress(
            groupID: groupID,
            groupName: group.name,
            averageScore: totalScore / Double(studentCount),
            averageVocabulary: totalVocab / Double(studentCount),
            studentCount: studentCount
        )
    }
    
    // MARK: - Parent Communication
    func generateParentReport(studentID: String) -> ParentReport {
        guard let student = getStudent(studentID: studentID) else {
            return ParentReport(studentID: studentID, studentName: "未知", reportDate: Date(), content: "無法生成報告")
        }
        
        let analytics = PIRLSAnalytics.shared
        let profile = StudentProfile.shared  // In real app, load specific student profile
        
        let recommendations = analytics.generateRecommendations(profile)
        let benchmark = analytics.benchmarkAgainstGradeLevel(profile)
        
        var content = "親愛的家長：\n\n"
        content += "以下是 \(student.studentName) 的學習進度報告：\n\n"
        content += "整體表現：\(Int(profile.pirlsAssessment.overallScore * 100))%\n"
        content += "年級水平：\(benchmark.isAboveGradeLevel ? "高於" : (benchmark.isAtGradeLevel ? "達到" : "低於"))年級標準\n\n"
        content += "學習建議：\n"
        for (index, rec) in recommendations.prefix(3).enumerated() {
            content += "\(index + 1). \(rec.title)\n"
            content += "   \(rec.description)\n\n"
        }
        
        return ParentReport(
            studentID: studentID,
            studentName: student.studentName,
            reportDate: Date(),
            content: content
        )
    }
    
    // MARK: - Data Persistence
    private func loadData() {
        // Load students
        if let data = UserDefaults.standard.data(forKey: studentsKey),
           let decoded = try? JSONDecoder().decode([ClassStudent].self, from: data) {
            students = decoded
        }
        
        // Load groups
        if let data = UserDefaults.standard.data(forKey: groupsKey),
           let decoded = try? JSONDecoder().decode([StudentGroup].self, from: data) {
            groups = decoded
        }
        
        // Load assignments
        if let data = UserDefaults.standard.data(forKey: assignmentsKey),
           let decoded = try? JSONDecoder().decode([Assignment].self, from: data) {
            assignments = decoded
        }
    }
    
    /// Upserts the signed-in student's snapshot for the teacher roster (one shared `StudentProfile` / `VocabularyManager` on device).
    func addOrUpdateStudentFromCurrentProfile(displayName: String?) {
        let profile = StudentProfile.shared
        profile.updateVocabularyStats()
        let stats = VocabularyManager.shared.getStatistics()
        let name = displayName ?? profile.studentName ?? "學生"
        let vocabRate: Double
        if stats.totalWords > 0 {
            vocabRate = Double(stats.masteredWords) / Double(stats.totalWords)
        } else {
            vocabRate = profile.vocabularyMastery
        }
        let entry = ClassStudent(
            studentID: profile.studentID,
            studentName: name,
            currentLevel: profile.currentLevel,
            overallScore: profile.pirlsAssessment.overallScore,
            vocabularyMastery: vocabRate,
            parentEmail: nil,
            notes: nil
        )
        if let idx = students.firstIndex(where: { $0.studentID == entry.studentID }) {
            students[idx] = entry
        } else {
            students.append(entry)
        }
        saveData()
    }
    
    private func saveData() {
        // Save students
        if let encoded = try? JSONEncoder().encode(students) {
            UserDefaults.standard.set(encoded, forKey: studentsKey)
        }
        
        // Save groups
        if let encoded = try? JSONEncoder().encode(groups) {
            UserDefaults.standard.set(encoded, forKey: groupsKey)
        }
        
        // Save assignments
        if let encoded = try? JSONEncoder().encode(assignments) {
            UserDefaults.standard.set(encoded, forKey: assignmentsKey)
        }
    }
}

// MARK: - Data Structures
struct ClassStudent: Codable {
    let studentID: String
    let studentName: String
    let currentLevel: Int
    var overallScore: Double
    var vocabularyMastery: Double
    let parentEmail: String?
    let notes: String?
}

struct StudentGroup: Codable {
    let id: String
    let name: String
    var studentIDs: [String]
    let description: String?
    let createdAt: Date
}

struct Assignment: Codable {
    let id: String
    let title: String
    let description: String
    let passageKeys: [String]
    let questionKeys: [String]
    let assignedStudentIDs: [String]
    let dueDate: Date
    let difficultyLevel: Int
    let createdAt: Date
    var completedStudentIDs: [String]
    var averageScore: Double?
}

struct GroupProgress {
    let groupID: String
    let groupName: String
    let averageScore: Double
    let averageVocabulary: Double
    let studentCount: Int
}

struct ParentReport {
    let studentID: String
    let studentName: String
    let reportDate: Date
    let content: String
}

