import Foundation

/**
 * ASSIGNMENT MANAGER - Create and Track Assignments
 * 
 * Features:
 * - Create assignments with specific passages/questions
 * - Set due dates and difficulty levels
 * - Track completion and performance
 * - Provide feedback on assignments
 * - Generate assignment reports
 */
// MARK: - 📝 ASSIGNMENT MANAGER
class AssignmentManager {
    static let shared = AssignmentManager()
    
    private let assignmentsKey = "teacherAssignments"
    private var assignments: [Assignment] = []
    
    private init() {
        loadAssignments()
    }
    
    // MARK: - Create Assignment
    func createAssignment(
        title: String,
        description: String,
        passageKeys: [String],
        questionKeys: [String],
        assignedStudentIDs: [String],
        dueDate: Date,
        difficultyLevel: Int
    ) -> Assignment {
        let assignment = Assignment(
            id: UUID().uuidString,
            title: title,
            description: description,
            passageKeys: passageKeys,
            questionKeys: questionKeys,
            assignedStudentIDs: assignedStudentIDs,
            dueDate: dueDate,
            difficultyLevel: difficultyLevel,
            createdAt: Date(),
            completedStudentIDs: [],
            averageScore: nil
        )
        
        assignments.append(assignment)
        saveAssignments()
        return assignment
    }
    
    // MARK: - Update Assignment
    func updateAssignment(_ assignment: Assignment) {
        if let index = assignments.firstIndex(where: { $0.id == assignment.id }) {
            assignments[index] = assignment
            saveAssignments()
        }
    }
    
    // MARK: - Get Assignments
    func getAssignments(forStudentID studentID: String) -> [Assignment] {
        return assignments.filter { $0.assignedStudentIDs.contains(studentID) }
    }
    
    func getAssignments(forGroupID groupID: String) -> [Assignment] {
        guard let group = ClassManager.shared.getGroup(groupID: groupID) else { return [] }
        return assignments.filter { assignment in
            group.studentIDs.contains { assignment.assignedStudentIDs.contains($0) }
        }
    }
    
    func getAllAssignments() -> [Assignment] {
        return assignments
    }
    
    func getAssignment(assignmentID: String) -> Assignment? {
        return assignments.first { $0.id == assignmentID }
    }
    
    // MARK: - Complete Assignment
    func markAssignmentComplete(assignmentID: String, studentID: String, score: Double) {
        if let index = assignments.firstIndex(where: { $0.id == assignmentID }) {
            if !assignments[index].completedStudentIDs.contains(studentID) {
                assignments[index].completedStudentIDs.append(studentID)
            }
            
            // Update average score
            let completedScores = assignments[index].completedStudentIDs.count
            if assignments[index].averageScore == nil {
                assignments[index].averageScore = score
            } else {
                let currentAvg = assignments[index].averageScore!
                assignments[index].averageScore = (currentAvg * Double(completedScores - 1) + score) / Double(completedScores)
            }
            
            saveAssignments()
        }
    }
    
    // MARK: - Get Assignment Statistics
    func getAssignmentStatistics(assignmentID: String) -> AssignmentStatistics? {
        guard let assignment = getAssignment(assignmentID: assignmentID) else { return nil }
        
        let totalAssigned = assignment.assignedStudentIDs.count
        let completed = assignment.completedStudentIDs.count
        let completionRate = totalAssigned > 0 ? Double(completed) / Double(totalAssigned) : 0.0
        
        return AssignmentStatistics(
            assignmentID: assignmentID,
            totalAssigned: totalAssigned,
            completed: completed,
            completionRate: completionRate,
            averageScore: assignment.averageScore ?? 0.0,
            overdue: assignment.dueDate < Date() && completed < totalAssigned
        )
    }
    
    // MARK: - Generate Assignment Report
    func generateAssignmentReport(assignmentID: String) -> AssignmentReport? {
        guard let assignment = getAssignment(assignmentID: assignmentID),
              let stats = getAssignmentStatistics(assignmentID: assignmentID) else {
            return nil
        }
        
        var studentReports: [StudentAssignmentReport] = []
        
        for studentID in assignment.assignedStudentIDs {
            let isCompleted = assignment.completedStudentIDs.contains(studentID)
            let student = ClassManager.shared.getStudent(studentID: studentID)
            
            studentReports.append(StudentAssignmentReport(
                studentID: studentID,
                studentName: student?.studentName ?? "未知",
                isCompleted: isCompleted,
                score: isCompleted ? (assignment.averageScore ?? 0.0) : nil,
                isOverdue: !isCompleted && assignment.dueDate < Date()
            ))
        }
        
        return AssignmentReport(
            assignment: assignment,
            statistics: stats,
            studentReports: studentReports
        )
    }
    
    // MARK: - Data Persistence
    private func loadAssignments() {
        if let data = UserDefaults.standard.data(forKey: assignmentsKey),
           let decoded = try? JSONDecoder().decode([Assignment].self, from: data) {
            assignments = decoded
        }
    }
    
    private func saveAssignments() {
        if let encoded = try? JSONEncoder().encode(assignments) {
            UserDefaults.standard.set(encoded, forKey: assignmentsKey)
        }
    }
}

// MARK: - Data Structures
struct AssignmentStatistics {
    let assignmentID: String
    let totalAssigned: Int
    let completed: Int
    let completionRate: Double
    let averageScore: Double
    let overdue: Bool
}

struct AssignmentReport {
    let assignment: Assignment
    let statistics: AssignmentStatistics
    let studentReports: [StudentAssignmentReport]
}

struct StudentAssignmentReport {
    let studentID: String
    let studentName: String
    let isCompleted: Bool
    let score: Double?
    let isOverdue: Bool
}

