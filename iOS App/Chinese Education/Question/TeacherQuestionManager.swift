import Foundation

class TeacherQuestionManager {
    static let shared = TeacherQuestionManager()

    private let teacherQuestionsKey = "teacherQuestions"

    // MARK: - Get Stored Teacher Questions
    func getTeacherQuestions() -> [Question] {
        guard let savedData = UserDefaults.standard.data(forKey: teacherQuestionsKey),
              let decodedQuestions = try? JSONDecoder().decode([Question].self, from: savedData) else {
            return []
        }
        return decodedQuestions
    }

    // MARK: - Add New Question Locally
    func addTeacherQuestion(_ question: Question) {
        var questions = getTeacherQuestions()
        questions.append(question)
        if let encodedData = try? JSONEncoder().encode(questions) {
            UserDefaults.standard.set(encodedData, forKey: teacherQuestionsKey)
        }
    }

    // MARK: - Get All Questions (Local + Teacher-Added)
    func getAllQuestions() -> [Question] {
        return QuestionBank.shared.getAllQuestions() + getTeacherQuestions()
    }
}
